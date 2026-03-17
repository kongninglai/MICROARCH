`timescale 1ns / 1ps

module tb_choose_eip();

    // 1. Inputs
    reg [3:0] instr_length;
    reg [31:0] o_eip;
    reg ld_pr_rr;
    reg instr_valid;
    reg mispredict_src_ex;
    reg v_ld_cs_src_ex;
    reg cur_instr_prediction;
    reg [31:0] bp_eip_target;
    reg [31:0] ex_eip_target;
    reg [1:0] branch_type;
    reg hit; // NEW: BTB Hit (Resolvable in Decode)

    // 2. Outputs
    wire [31:0] i_eip;
    wire ld_eip;
    wire [31:0] eip_true;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    choose_eip uut (
        .instr_length(instr_length),
        .o_eip(o_eip),
        .i_eip(i_eip),
        .ld_pr_rr(ld_pr_rr),
        .instr_valid(instr_valid),
        .mispredict_src_ex(mispredict_src_ex),
        .v_ld_cs_src_ex(v_ld_cs_src_ex),
        .cur_instr_prediction(cur_instr_prediction),
        .bp_eip_target(bp_eip_target),
        .ex_eip_target(ex_eip_target),
        .branch_type(branch_type),
        .hit(hit), // Hooked up new input
        .ld_eip(ld_eip),
        .eip_true(eip_true)
    );

    // 4. Checking Task
    task check_result;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_eip_true;
        begin
            #5; // Wait 5ns for combinational logic to propagate
            if (ld_eip === exp_ld_eip && eip_true === exp_eip_true) begin
                $display("  ✅ PASS | %0s | ld: %b | eip_true: %h", test_name, ld_eip, eip_true);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: ld_eip=%b | eip_true=%h", exp_ld_eip, exp_eip_true);
                $display("     ACTUAL  : ld_eip=%b | eip_true=%h", ld_eip, eip_true);
                FAILURES = FAILURES + 1;
            end
            #5; // Padding before next test
        end
    endtask

    // 5. Stimulus
    initial begin
        $dumpfile("choose_eip_tb.vpd");
        $dumpvars(0, tb_choose_eip);

        $display("=======================================");
        $display("       EIP MUX & SELECTION TEST        ");
        $display("=======================================");

        // Setup base addresses to easily track what the MUX selects
        o_eip = 32'h0000_1000;         // Current PC
        instr_length = 4'd4;           // So i_eip will be 1004
        bp_eip_target = 32'h0000_2000; // Branch Predictor Target
        ex_eip_target = 32'h0000_3000; // Execute Flush Target
        
        // Safe default inputs
        ld_pr_rr = 1;
        instr_valid = 1;
        mispredict_src_ex = 0;
        v_ld_cs_src_ex = 0;
        cur_instr_prediction = 0;
        branch_type = 2'b00;
        hit = 0;

        // --------------------------------------------------------
        // TEST 1: Normal Sequential Instruction (Not a branch)
        // Expected: ld_eip = 1, eip_true = i_eip (1004)
        // --------------------------------------------------------
        check_result("Normal Sequential Add  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 2: Pipeline Stalled
        // Expected: ld_eip = 0, eip_true = o_eip (1000)
        // --------------------------------------------------------
        ld_pr_rr = 0;
        check_result("Stall (Hold EIP)       ", 1'b0, o_eip);
        ld_pr_rr = 1; // Restore

        // --------------------------------------------------------
        // TEST 3: JMP rel8 (01) - DIRECT (Resolvable)
        // Expected: ld_eip = 1, eip_true = bp_eip_target (2000)
        // --------------------------------------------------------
        branch_type = 2'b01;
        hit = 1; // Direct branch!
        check_result("JMP rel8 (Direct 01)   ", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 4: CALL r/m32 (01) - INDIRECT (Unresolvable)
        // Expected: eip_true = i_eip (1004) because we can't jump yet
        // --------------------------------------------------------
        branch_type = 2'b01;
        hit = 0; // Indirect branch!
        check_result("CALL r/m32 (Indir 01)  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 5: JNE rel8 (10) - DIRECT, Predicted NOT TAKEN
        // Expected: ld_eip = 1, eip_true = i_eip (1004)
        // --------------------------------------------------------
        branch_type = 2'b10;
        hit = 1; // Direct!
        cur_instr_prediction = 1'b0; // Not Taken
        check_result("JNE rel8 (Direct, NT)  ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 6: JNE rel8 (10) - DIRECT, Predicted TAKEN
        // Expected: ld_eip = 1, eip_true = bp_eip_target (2000)
        // --------------------------------------------------------
        branch_type = 2'b10;
        hit = 1; // Direct!
        cur_instr_prediction = 1'b1; // Taken
        check_result("JNE rel8 (Direct, T)   ", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 7: JMP ptr16:16 (11) - DIRECT (Far Resolvable)
        // Expected: ld_eip = 1, eip_true = bp_eip_target (2000)
        // --------------------------------------------------------
        branch_type = 2'b11;
        hit = 1; // Direct!
        cur_instr_prediction = 1'b0; // Pred ignored for uncond
        check_result("JMP ptr (Direct Far 11)", 1'b1, bp_eip_target);

        // --------------------------------------------------------
        // TEST 8: RETF (11) - INDIRECT (Far Unresolvable)
        // Expected: ld_eip = 1, eip_true = i_eip (1004)
        // --------------------------------------------------------
        branch_type = 2'b11;
        hit = 0; // Indirect!
        check_result("RETF (Indirect Far 11) ", 1'b1, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 9: Priority Check (Mispredict from EX stage)
        // Even if Decode wants to branch, EX flush must override it!
        // --------------------------------------------------------
        branch_type = 2'b01;         
        hit = 1;                     // Decode wants to jump
        mispredict_src_ex = 1'b1;    // EX says NO, flush and jump to 3000!
        check_result("Priority: EX Flush     ", 1'b1, ex_eip_target);
        mispredict_src_ex = 1'b0;    // Restore

        // --------------------------------------------------------
        // TEST 10: Invalid Instruction Bubble
        // Pipeline is moving, but the instruction isn't valid yet.
        // --------------------------------------------------------
        instr_valid = 0;
        branch_type = 2'b00;
        hit = 0;
        check_result("Invalid Inst Bubble    ", 1'b0, o_eip + instr_length);

        // --------------------------------------------------------
        // TEST 11: BTB False Hit on Non-Branch (00)
        // If cond_take doesn't explicitly verify branch_type == 10,
        // a false BTB hit + Taken prediction on a regular instruction 
        // will cause the CPU to wildly jump!
        // Expected: ld_eip = 1, eip_true = i_eip (1004)
        // --------------------------------------------------------
        instr_valid = 1;
        branch_type = 2'b00;         // Decode says: NOT A BRANCH
        hit = 1;                     // BTB says: "I have a target!" (False Hit / Alias)
        cur_instr_prediction = 1'b1; // Predictor says: "Taken!"
        check_result("BTB False Hit on ADD   ", 1'b1, o_eip + instr_length); // Because branch_type is 00, Decode MUST ignore the hit and pred!

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule