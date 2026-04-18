`timescale 1ns / 1ps

module tb_logic_instr_valid();

    // 1. Inputs
    reg [31:0] i_eip;
    reg [4:0]  tail_ptr;
    reg [3:0]  incr_amt;
    
    reg mispredict_src_ex;
    reg from_wb_flush;
    reg v_ld_cs_src_ex; // Kept so test cases remain untouched
    
    reg stall_ex, stall_rr, stall_mem, stall_wb;

    reg clk, rst_bar;

    // 2. Outputs
    wire ld_pr_rr;
    wire instr_valid;

    // --- Signal Mapping Logic ---
    // Combine the granular testbench signals into the consolidated signals expected by the new module.
    wire combined_stall = stall_ex | stall_rr | stall_mem | stall_wb;
    wire combined_flush = mispredict_src_ex | from_wb_flush;

    // 3. Instantiate UUT (Updated to match new port list)
    logic_stall_flush uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .i_eip(i_eip),
        .tail_ptr(tail_ptr),
        .incr_amt(incr_amt),
        .flush_ex(combined_flush),    // Maps mispredicts/exceptions to flush_ex
        .flush_wb(1'b0),    // Maps mispredicts/exceptions to flush_wb
        .stall_rr(combined_stall),    // Maps any pipeline stall to stall_rr
        .ld_pr_rr(ld_pr_rr),
        .instr_valid(instr_valid)
    );

    // 4. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 5. Reusable Checking Task
    task check_result;
        input exp_ld_pr_rr;
        input exp_valid;
        input [8*30:1] test_name; 
        
        reg fail_ld, fail_val, fail_prot;
        begin
            // Determine which specific signals failed
            fail_ld   = (ld_pr_rr !== exp_ld_pr_rr);
            fail_val  = (instr_valid !== exp_valid);

            $display("-------------------------------------------------------------------------------------------------------");
            $display("TEST   : %0s", test_name);
            $display("INPUTS : EIP=%h | Incr=%0d | Tail=%0d | Stalls(ERMW)=%b%b%b%b | Flushes(MEL)=%b%b%b", 
                     i_eip, incr_amt, tail_ptr, stall_ex, stall_rr, stall_mem, stall_wb, mispredict_src_ex, from_wb_flush, v_ld_cs_src_ex);
            $display("EXPECT : LD_PR_RR=%b | INSTR_VALID=%b" , exp_ld_pr_rr, exp_valid);
            $display("ACTUAL : LD_PR_RR=%b | INSTR_VALID=%b ", ld_pr_rr, instr_valid);

            if (fail_ld || fail_val || fail_prot) begin
                $write("RESULT : ❌ FAIL -> Mismatch on: ");
                if (fail_ld)   $write("[LD_PR_RR] ");
                if (fail_val)  $write("[INSTR_VALID] ");
                $display("\n"); // Double newline for spacing
                FAILURES = FAILURES + 1;
            end else begin
                $display("RESULT : ✅ PASS\n");
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    // 6. Test Cases (Untouched)
    initial begin
        $display("=======================================================================================================");
        $display("                         INSTRUCTION VALIDITY & EXCEPTION LOGIC TEST SUITE                             ");
        $display("=======================================================================================================");
        rst_bar = 1'b0;
        clk = 1'b0;
        // DEFAULT STATE: All good. (Load = 1, Valid = 1)
        i_eip = 32'h0000_1000; 
        incr_amt = 4'd4; tail_ptr = 5'd10;
        {stall_ex, stall_rr, stall_mem, stall_wb} = 4'b0000;
        {mispredict_src_ex, from_wb_flush, v_ld_cs_src_ex} = 3'b000;
        #10;
        check_result(1'b1, 1'b1, "DEFAULT STATE");

        // TEST 1: Cache line boundary crossed!
        incr_amt = 4'd8; tail_ptr = 5'd5;
        #10;
        check_result(1'b1, 1'b0, "TEST 1: Cache Boundary Crossed");
        incr_amt = 4'd4; tail_ptr = 5'd10; // reset
        
        // TEST 2: Stall in Memory Stage.
        stall_mem = 1'b1;
        #10;
        check_result(1'b0, 1'b1, "TEST 2: Pipeline Stall (Memory)");
        stall_mem = 1'b0; // reset

        // TEST 3: Branch Mispredict Flush.
        mispredict_src_ex = 1'b1;
        #10;
        check_result(1'b1, 1'b0, "TEST 3: Pipeline Flush (Mispredict)");
        mispredict_src_ex = 1'b0; // reset

        //TEST 4: deleted (no longer doing limit checking in decode)

        // TEST 5: Everything goes wrong at once.
        i_eip = 32'h0010_0000;
        stall_wb = 1'b1;
        v_ld_cs_src_ex = 1'b1;
        incr_amt = 4'd15; tail_ptr = 5'd2;
        #10;
        check_result(1'b0, 1'b0, "TEST 5: Total Failure State");

        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule