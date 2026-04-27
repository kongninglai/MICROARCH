`timescale 1ns / 1ps

module tb_predictor();

    // 1. Inputs
    reg clk;
    reg rst_bar;
    reg br_t_nt_in;
    reg [3:0] ext_pht_idx; 
    reg [3:0] b_pht_idx;   
    reg from_ex_br_valid; 
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
        .from_ex_br_valid(from_ex_br_valid), 
        .b_pht_idx(b_pht_idx),
        .from_de_br_valid(b_valid),
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
        from_ex_br_valid = 0; // Don't forget to declare this as a reg at the top of your TB!

        // Release Reset
        @(negedge clk);
        rst_bar = 1;
        
        // --------------------------------------------------------
        // TEST 1: Original PHT value without inc/dec
        // Default state is 01 (Weakly Not Taken).
        // --------------------------------------------------------
        @(negedge clk);
        b_valid = 1;
        b_pht_idx = 4'd0;
        
        @(posedge clk); #1;
        check_result("1. Default PHT (01) -> Out 0", 1'b0);

        // --------------------------------------------------------
        // TEST 2: Increment PHT[1] 1 time (01 -> 10)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd1;
        from_ex_br_valid = 1; // Enable write
        br_t_nt_in = 1;       // Increment (Taken)
        
        @(posedge clk);       // State updates on clock edge
        @(negedge clk);       // Prep for read
        from_ex_br_valid = 0; // Disable write
        b_valid = 1;
        b_pht_idx = 4'd1;     // Read the index we just updated
        
        @(posedge clk); #1;
        check_result("2. Incr 1x (10 Weak Taken)", 1'b1);

        // --------------------------------------------------------
        // TEST 3: Increment PHT[1] 2 times (10 -> 11)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd1;
        from_ex_br_valid = 1;
        br_t_nt_in = 1; 
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd1;
        
        @(posedge clk); #1;
        check_result("3. Incr 2x (11 Str Taken)", 1'b1);

        // --------------------------------------------------------
        // TEST 4: Increment PHT[1] 3 times (11 -> 11 Saturation)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd1;
        from_ex_br_valid = 1;
        br_t_nt_in = 1; 
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd1;
        
        @(posedge clk); #1;
        check_result("4. Incr 3x (Saturate at 11)", 1'b1);

        // --------------------------------------------------------
        // TEST 5: Increment PHT[1] 4 times (11 -> 11 Saturation)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd1;
        from_ex_br_valid = 1;
        br_t_nt_in = 1; 
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd1;
        
        @(posedge clk); #1;
        check_result("5. Incr 4x (Saturate at 11)", 1'b1);

        // --------------------------------------------------------
        // TEST 6: Decrement PHT[2] 1 time (01 -> 00)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd2;   // Using a fresh index (defaults to 01)
        from_ex_br_valid = 1;
        br_t_nt_in = 0;       // Decrement (Not Taken)
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd2;
        
        @(posedge clk); #1;
        check_result("6. Decr 1x (00 Str Not Taken)", 1'b0);

        // --------------------------------------------------------
        // TEST 7: Decrement PHT[2] 2 times (00 -> 00 Saturation)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd2;
        from_ex_br_valid = 1;
        br_t_nt_in = 0; 
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd2;
        
        @(posedge clk); #1;
        check_result("7. Decr 2x (Saturate at 00)", 1'b0);

        // --------------------------------------------------------
        // TEST 8: Decrement PHT[2] 3 times (00 -> 00 Saturation)
        // --------------------------------------------------------
        @(negedge clk);
        ext_pht_idx = 4'd2;
        from_ex_br_valid = 1;
        br_t_nt_in = 0; 
        
        @(posedge clk); 
        @(negedge clk); 
        from_ex_br_valid = 0; 
        b_valid = 1;
        b_pht_idx = 4'd2;
        
        @(posedge clk); #1;
        check_result("8. Decr 3x (Saturate at 00)", 1'b0);

        // --------------------------------------------------------
        // TEST 9: Inc/Dec multiple times, valid/invalid read testing
        // Using PHT[3]. Default is 01.
        // --------------------------------------------------------
        // 9a. Increment it -> becomes 10 (Weakly Taken)
        @(negedge clk);
        ext_pht_idx = 4'd3;
        from_ex_br_valid = 1;
        br_t_nt_in = 1; 
        @(posedge clk); 
        
        // Read with b_valid = 0 (Should force output to 0 despite state 10)
        @(negedge clk);
        from_ex_br_valid = 0;
        b_pht_idx = 4'd3;
        b_valid = 0; // INVALID decode branch
        @(posedge clk); #1;
        check_result("9a. State 10 but b_valid=0 -> Out 0", 1'b0);
        
        // 9b. Decrement -> becomes 01 (Weakly Not Taken)
        @(negedge clk);
        ext_pht_idx = 4'd3;
        from_ex_br_valid = 1;
        br_t_nt_in = 0; 
        @(posedge clk);
        
        // 9c. Decrement again -> becomes 00 (Strongly Not Taken)
        @(negedge clk);
        br_t_nt_in = 0; 
        @(posedge clk);
        
        // Read with b_valid = 1
        @(negedge clk);
        from_ex_br_valid = 0;
        b_pht_idx = 4'd3;
        b_valid = 1; // VALID decode branch
        @(posedge clk); #1;
        check_result("9d. Decremented to 00, b_valid=1 -> Out 0", 1'b0);

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule