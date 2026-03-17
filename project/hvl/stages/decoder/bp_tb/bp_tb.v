`timescale 1ns / 1ps

module tb_bp();

    // 1. Inputs
    reg clk;
    reg rst_bar;
    reg is_branch;      // NEW: From Decode
    reg [31:0] o_eip;
    reg br_t_nt_ex_d;
    reg br_valid_ex_d;
    reg [3:0] ext_pht_idx;

    // 2. Outputs
    wire cur_instr_prediction;
    wire [7:0] ghr_out;
    wire hit;                   // NEW: BTB Hit
    wire [31:0] bp_eip_target;  // NEW: BTB Target

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    bp uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .is_branch(is_branch), 
        .o_eip(o_eip),
        .br_t_nt_ex_d(br_t_nt_ex_d),
        .br_valid_ex_d(br_valid_ex_d),
        .ext_pht_idx(ext_pht_idx),
        .bp_eip_target(bp_eip_target), // NEW port mapped
        .hit(hit),                     // NEW port mapped
        .cur_instr_prediction(cur_instr_prediction),
        .ghr_out(ghr_out)
    );

    // 4. Clock Generation (10ns period)
    always #5 clk = ~clk;

    // 5. Checking Task 
    task check_result;
        input [8*25:1] test_name; 
        input [7:0] exp_ghr;
        input exp_pred;
        input exp_hit;
        input [31:0] exp_target;
        begin
            if (ghr_out === exp_ghr && cur_instr_prediction === exp_pred && hit === exp_hit && bp_eip_target === exp_target) begin
                $display("  ✅ PASS | %0s | GHR: %b | Pred: %b | Hit: %b", test_name, ghr_out, cur_instr_prediction, hit);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: GHR=%b | Pred=%b | Hit=%b | Target=%h", exp_ghr, exp_pred, exp_hit, exp_target);
                $display("     ACTUAL  : GHR=%b | Pred=%b | Hit=%b | Target=%h", ghr_out, cur_instr_prediction, hit, bp_eip_target);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 6. Stimulus
    initial begin
        $dumpfile("bp_tb.vpd");
        $dumpvars(0, tb_bp);

        $display("=======================================");
        $display("      TOP-LEVEL BRANCH PREDICTOR TEST  ");
        $display("=======================================");

        // Initialize (Time = 0)
        clk = 0;
        rst_bar = 0;
        is_branch = 0;
        o_eip = 32'h0000_0000;
        br_valid_ex_d = 0;
        br_t_nt_ex_d = 0;
        ext_pht_idx = 4'b0000;

        // Release Reset on the first falling edge
        @(negedge clk);
        rst_bar = 1;
        
        // Check Reset state after the rising edge
        // Note: o_eip is 0, so expected target is 0.
        @(posedge clk); #1; 
        check_result("Reset State        ", 8'b0000_0000, 1'bx, 1'b0, 32'h0000_0000);

        // --------------------------------------------------------
        // TEST 1: Non-branch Decode, No EX valid signal
        // --------------------------------------------------------
        @(negedge clk); 
        is_branch = 0;     // Decode: Not a branch
        o_eip = 32'h0000_0004;
        br_valid_ex_d = 0; // EX: No branch update
        br_t_nt_ex_d = 1;  // Even if high, GHR shouldn't shift!
        
        @(posedge clk); #1; 
        // Note: o_eip is now 0004, so expected target is 0004
        check_result("Hold State (No Val)", 8'b0000_0000, 1'bx, 1'b0, 32'h0000_0004);

        // --------------------------------------------------------
        // TEST 2: Decode Branch, EX Updates Taken
        // --------------------------------------------------------
        @(negedge clk);
        is_branch = 1;     // Decode: IS A BRANCH! (Pred should be 0)
        o_eip = 32'h0000_0008;
        br_valid_ex_d = 1; // EX: VALID UPDATE
        br_t_nt_ex_d = 1;  // EX: TAKEN
        
        @(posedge clk); #1;
        // Note: o_eip is now 0008, so expected target is 0008
        check_result("Decode Br, EX Taken", 8'b0000_0001, 1'b0, 1'b0, 32'h0000_0008);

        // --------------------------------------------------------
        // TEST 3: Decode Non-Branch, EX Updates Not Taken
        // --------------------------------------------------------
        @(negedge clk);
        is_branch = 0;     // Decode: Not a branch (Pred should be X)
        br_valid_ex_d = 1; // EX: VALID UPDATE
        br_t_nt_ex_d = 0;  // EX: NOT TAKEN
        // o_eip remains 0008
        
        @(posedge clk); #1;
        check_result("Decode NoBr, EX NT ", 8'b0000_0010, 1'bx, 1'b0, 32'h0000_0008);

        // --------------------------------------------------------
        // TEST 4: Decode Branch, EX Updates Taken
        // --------------------------------------------------------
        @(negedge clk);
        is_branch = 1;     // Decode: IS A BRANCH! (Pred should be 0)
        br_valid_ex_d = 1; // EX: VALID UPDATE
        br_t_nt_ex_d = 1;  // EX: TAKEN
        // o_eip remains 0008
        
        @(posedge clk); #1;
        check_result("Decode Br, EX Taken", 8'b0000_0101, 1'b0, 1'b0, 32'h0000_0008);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule