`timescale 1ns / 1ps

module tb_predictor();

    // 1. Inputs
    reg clk;
    reg rst_bar;
    reg br_t_nt_in;
    reg [3:0] ext_pht_idx; 
    reg [3:0] b_pht_idx;   
    reg b_valid;     // NEW INPUT: From decode stage

    // 2. Outputs
    wire br_t_nt_out;

    // Error Checking 
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    predictor uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .br_t_nt_in(br_t_nt_in),
        .ext_pht_idx(ext_pht_idx),
        .b_pht_idx(b_pht_idx),
        .b_valid(b_valid),
        .br_t_nt_out(br_t_nt_out)
    );

    // 4. Clock Generation (10ns period)
    always #5 clk = ~clk;

    // 5. Checking Task
    task check_result;
        input [8*25:1] test_name; 
        input expected_val;
        begin
            if (br_t_nt_out === expected_val) begin
                $display("  ✅ PASS | %0s | Out: %b", test_name, br_t_nt_out);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: %b", expected_val);
                $display("     ACTUAL  : %b", br_t_nt_out);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 6. Stimulus Sequence
    initial begin
        $dumpfile("predictor_tb.vpd");
        $dumpvars(0, tb_predictor);

        $display("=======================================");
        $display("    UPDATED STATIC PREDICTOR TEST      ");
        $display("=======================================");

        // Initialize (Time = 0)
        clk = 0;
        rst_bar = 0;
        br_t_nt_in = 0;
        ext_pht_idx = 4'd0;
        b_pht_idx = 4'd0;
        b_valid = 0;

        // Release Reset
        @(negedge clk);
        rst_bar = 1;
        
        // --------------------------------------------------------
        // TEST 1: Valid = 0 (Not a branch instruction)
        // --------------------------------------------------------
        @(negedge clk);
        b_valid = 0;
        
        @(posedge clk); #1;
        check_result("Valid=0 -> Output X", 1'bx);

        // --------------------------------------------------------
        // TEST 2: Valid = 1 (It is a branch!)
        // --------------------------------------------------------
        @(negedge clk);
        b_valid = 1;
        
        @(posedge clk); #1;
        check_result("Valid=1 -> Output 0", 1'b0);

        // --------------------------------------------------------
        // TEST 3: Execute sends a 'Taken' update, but valid=0
        // --------------------------------------------------------
        @(negedge clk);
        br_t_nt_in = 1; // Try to train it
        b_valid = 0;    // Not currently decoding a branch
        
        @(posedge clk); #1;
        check_result("Train Taken, Val=0 ", 1'bx);

        // --------------------------------------------------------
        // TEST 4: Execute sends a 'Taken' update, valid=1
        // --------------------------------------------------------
        @(negedge clk);
        b_valid = 1;    // Now decoding a branch
        
        @(posedge clk); #1;
        check_result("Train Taken, Val=1 ", 1'b0);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule