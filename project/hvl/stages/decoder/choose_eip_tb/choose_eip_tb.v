`timescale 1ns / 1ps

module tb_choose_eip();

    // 1. Inputs
    reg clk;             
    reg rst_bar;         
    
    reg [3:0] instr_length;
    reg [31:0] o_eip;    // TB Shadow Tracker
    reg ld_pr_rr;
    reg instr_valid;
    reg mispredict_src_ex;
    reg v_ld_cs_src_ex; 
    reg cur_instr_prediction;
    reg [31:0] bp_eip_target;
    reg [31:0] ex_eip_target;
    reg [1:0] branch_type;
    reg hit; // BTB Hit

    // 2. Outputs
    wire [31:0] i_eip; 
    wire ld_eip;
    wire [31:0] eip_true;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    choose_eip uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .instr_length(instr_length),
        .i_eip(i_eip),                 
        .ld_pr_rr(ld_pr_rr),
        .instr_valid(instr_valid),
        .cur_instr_prediction(cur_instr_prediction),
        .flush_ex(mispredict_src_ex),  
        .bp_eip_target(bp_eip_target),
        .ex_eip_target(ex_eip_target),
        .branch_type(branch_type),
        .hit(hit), 
        .ld_eip(ld_eip),
        .eip_true(eip_true),
        .take_branch() // Ignored in this testbench
    );

    // --- CLOCK GENERATION ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // 4. Checking Task (PURE SEQUENTIAL VERIFICATION)
    task check_result;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_next_eip; 
        
        reg [31:0] expected_reg_val;
        begin
            
            // 1. Wait right before the clock edge to check combinational logic
            #4; 
            
            if (ld_eip !== exp_ld_eip) begin
                $display("  ❌ FAIL | %0s | ENABLE MISMATCH", test_name);
                $display("     EXPECTED ld_eip=%b | ACTUAL ld_eip=%b", exp_ld_eip, ld_eip);
                FAILURES = FAILURES + 1;
            end else begin
                // The enable signal is correct! 
                if (exp_ld_eip == 1'b1) begin
                    expected_reg_val = exp_next_eip; 
                end else begin
                    // If stalled, the register should hold whatever is CURRENTLY in it
                    expected_reg_val = uut.o_eip;        
                end
                
                // 2. CLOCK IT! Let the register naturally capture data.
                @(posedge clk); 
                #1; // Wait 1ns for the flip-flop Q output to stabilize
                
                // 3. Check the internal register state
                if (uut.o_eip === expected_reg_val) begin
                    $display("  ✅ PASS | %0s | REG_OUT: %h", test_name, uut.o_eip);
                    SUCCESSES = SUCCESSES + 1;
                end else begin
                    $display("  ❌ FAIL | %0s | REGISTER CAPTURE ERROR", test_name);
                    $display("     EXPECTED REG STATE: %h", expected_reg_val);
                    $display("     ACTUAL REG STATE  : %h", uut.o_eip);
                    FAILURES = FAILURES + 1;
                end
            end

            // 4. THE MAGIC SYNC: 
            // Update the testbench's tracker to match the physical hardware!
            // This ensures the NEXT test case calculates its math correctly.
            o_eip = uut.o_eip;
        end
    endtask

    // 5. Stimulus
    // 5. Stimulus
    initial begin
        $dumpfile("choose_eip_tb.vpd");
        $dumpvars(0, tb_choose_eip);

        $display("=======================================");
        $display("       EIP MUX & SELECTION TEST        ");
        $display("=======================================");

        // --- 1. SET DEFAULT INPUTS (MUST HAPPEN AT TIME 0) ---
        // Setup base addresses
        o_eip = 32'h0000_0000;         
        instr_length = 4'd4;           
        bp_eip_target = 32'h0000_2000; 
        ex_eip_target = 32'h0000_3000; 
        
        // Safe default control inputs
        ld_pr_rr = 1;
        instr_valid = 0;
        mispredict_src_ex = 0;
        v_ld_cs_src_ex = 0;
        cur_instr_prediction = 0;
        branch_type = 2'b00;
        hit = 0;

        // --- 2. HARDWARE RESET SEQUENCE ---
        rst_bar = 0;
        #15;
        rst_bar = 1;
        @(negedge clk); // Align stimulus to the negative edge

        // --------------------------------------------------------
        // TEST 1: Normal Sequential Instruction (Not a branch)
        // Expected: Jumps to 4
        // --------------------------------------------------------
        instr_valid = 1;
        check_result("Normal Sequential Add  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 2: Pipeline Stalled
        // Expected: Holds at 4
        // --------------------------------------------------------
        ld_pr_rr = 0;
        check_result("Stall (Hold EIP)       ", 1'b0, o_eip);
        ld_pr_rr = 1; 

        // --------------------------------------------------------
        // TEST 3: JMP rel8 (01) - DIRECT (Resolvable)
        // Expected: Jumps to 2000
        // --------------------------------------------------------
        branch_type = 2'b01;
        hit = 1; 
        check_result("JMP rel8 (Direct 01)   ", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 4: CALL r/m32 (01) - INDIRECT (Unresolvable)
        // Expected: Jumps to 2004 (Base is 2000 + 4)
        // --------------------------------------------------------
        branch_type = 2'b01;
        hit = 0; 
        check_result("CALL r/m32 (Indir 01)  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 5: JNE rel8 (10) - DIRECT, Predicted NOT TAKEN
        // Expected: Jumps to 2008 (Base is 2004 + 4)
        // --------------------------------------------------------
        branch_type = 2'b10;
        hit = 1; 
        cur_instr_prediction = 1'b0; 
        check_result("JNE rel8 (Direct, NT)  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 6: JNE rel8 (10) - DIRECT, Predicted TAKEN
        // Expected: Jumps to 2000 (Because target is static 2000)
        // --------------------------------------------------------
        branch_type = 2'b10;
        hit = 1; 
        cur_instr_prediction = 1'b1; 
        check_result("JNE rel8 (Direct, T)   ", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 7: JMP ptr16:16 (11) - DIRECT (Far Resolvable)
        // Expected: Jumps to 2000
        // --------------------------------------------------------
        branch_type = 2'b11;
        hit = 1; 
        cur_instr_prediction = 1'b0; 
        check_result("JMP ptr (Direct Far 11)", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 8: RETF (11) - INDIRECT (Far Unresolvable)
        // Expected: Jumps to 2004 (Base is 2000 + 4)
        // --------------------------------------------------------
        branch_type = 2'b11;
        hit = 0; 
        check_result("RETF (Indirect Far 11) ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 9: Priority Check (Mispredict from EX stage)
        // Expected: Jumps to 3000
        // --------------------------------------------------------
        branch_type = 2'b01;         
        hit = 1;                     
        mispredict_src_ex = 1'b1;    
        check_result("Priority: EX Flush     ", 1'b1, ex_eip_target);
        mispredict_src_ex = 1'b0;    

        // --------------------------------------------------------
        // TEST 10: Invalid Instruction Bubble
        // Expected: Stall at 3000
        // --------------------------------------------------------
        instr_valid = 0;
        branch_type = 2'b00;
        hit = 0;
        check_result("Invalid Inst Bubble    ", 1'b0, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 11: BTB False Hit on Non-Branch (00)
        // Expected: Jumps to 3004
        // --------------------------------------------------------
        instr_valid = 1;
        branch_type = 2'b00;         
        hit = 1;                     
        cur_instr_prediction = 1'b1; 
        check_result("BTB False Hit on ADD   ", 1'b1, o_eip + instr_length); 

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule