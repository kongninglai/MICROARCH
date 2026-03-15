`timescale 1ns / 1ps

module choose_eip_tb();

    // 1. Inputs
    reg [3:0]  instr_length;
    reg [31:0] o_eip;
    reg ld_pr_rr;
    reg instr_valid;
    reg mispredict_src_ex;
    reg v_ld_cs_src_ex;
    reg [31:0] bp_eip_target;
    reg [31:0] ex_eip_target;
    reg [1:0]  branch_type;

    // 2. Outputs
    wire [31:0] i_eip;
    wire ld_eip;
    wire [31:0] eip_true;

    // 3. Instantiate UUT 
    choose_eip uut (
        .instr_length(instr_length),
        .o_eip(o_eip),
        .i_eip(i_eip),
        .ld_pr_rr(ld_pr_rr),
        .instr_valid(instr_valid),
        .mispredict_src_ex(mispredict_src_ex),
        .v_ld_cs_src_ex(v_ld_cs_src_ex),
        .bp_eip_target(bp_eip_target),
        .ex_eip_target(ex_eip_target),
        .branch_type(branch_type),
        .ld_eip(ld_eip),
        .eip_true(eip_true)
    );

    // 4. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Expected Values
    reg exp_ld_eip;
    reg [31:0] exp_eip_true;

    // 5. Reusable Checking Task
// 5. Reusable Checking Task
    task check_result;
        input [8*25:1] test_name; 
        begin
            #10; // Wait for combinational logic delay
            
            // Print the internal signals using hierarchical referencing (uut.signal_name)
            $display("-----------------------------------------------------------------------");
            $display("TEST: %0s", test_name);
            $display("  INTERNAL SIGNALS -> Flush: %b | Stall: %b | Is_Branch: %b | EIP_SEL: %b", 
                     uut.flush, uut.stall, uut.is_branch, uut.eip_sel);

            if (ld_eip !== exp_ld_eip || eip_true !== exp_eip_true) begin
                $display("  ❌ FAIL");
                $display("     EXPECT : ld_eip=%b | eip_true=%h", exp_ld_eip, exp_eip_true);
                $display("     ACTUAL : ld_eip=%b | eip_true=%h", ld_eip, eip_true);
                FAILURES = FAILURES + 1;
            end else begin
                $display("  ✅ PASS");
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin
        $display("=======================================================================");
        $display("                     EIP SELECTION TEST SUITE                          ");
        $display("=======================================================================");

        // Initialize distinct addresses so we know exactly which one the MUX chose
        o_eip         = 32'h0000_1000;
        instr_length  = 4'd4;          // i_eip will be 0x0000_1004
        bp_eip_target = 32'h0000_2000; // Branch Predictor Target
        ex_eip_target = 32'h0000_3000; // Execute Recovery Target
        
        // --------------------------------------------------------------------
        // TEST 1: Normal Valid Instruction (Not a branch)
        // Expect: ld_eip = 1, eip_true = i_eip (0x1004)
        // --------------------------------------------------------------------
        ld_pr_rr = 1; instr_valid = 1; mispredict_src_ex = 0; v_ld_cs_src_ex = 0;
        branch_type = 2'b00;
        
        exp_ld_eip = 1'b1;
        exp_eip_true = 32'h0000_1004; 
        check_result("TEST 1: Normal Sequential");

        // --------------------------------------------------------------------
        // TEST 2: Valid Branch Instruction
        // Expect: ld_eip = 1, eip_true = bp_eip_target (0x2000)
        // --------------------------------------------------------------------
        branch_type = 2'b10; // Conditional branch
        
        exp_ld_eip = 1'b1;
        exp_eip_true = 32'h0000_2000;
        check_result("TEST 2: Branch Taken");

        // --------------------------------------------------------------------
        // TEST 3: Pipeline Stall (Overrides Normal/Branch fetching)
        // Expect: ld_eip = 0, eip_true = o_eip (0x1000)
        // --------------------------------------------------------------------
        ld_pr_rr = 0; 
        
        exp_ld_eip = 1'b0;
        exp_eip_true = 32'h0000_1000;
        check_result("TEST 3: Pipeline Stall");

        // --------------------------------------------------------------------
        // TEST 4: Branch Mispredict Flush (Overrides Stall)
        // Expect: ld_eip = 1, eip_true = ex_eip_target (0x3000)
        // --------------------------------------------------------------------
        mispredict_src_ex = 1; 
        
        exp_ld_eip = 1'b1;
        exp_eip_true = 32'h0000_3000;
        check_result("TEST 4: Mispredict Flush");

        // --------------------------------------------------------------------
        // TEST 5: Load CS Flush
        // Expect: ld_eip = 1, eip_true = ex_eip_target (0x3000)
        // --------------------------------------------------------------------
        mispredict_src_ex = 0; 
        v_ld_cs_src_ex = 1; 
        
        exp_ld_eip = 1'b1;
        exp_eip_true = 32'h0000_3000;
        check_result("TEST 5: Load CS Flush");

        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule