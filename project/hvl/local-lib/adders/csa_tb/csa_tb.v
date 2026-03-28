`timescale 1ns / 1ps

module tb_csa();

    // 1. Signals matching your csa ports
    reg  [4:0] in0, in1, in2;
    wire [4:0] sum_vec, carry_vec;

    // 2. Instantiate the Unit Under Test (UUT)
    csa uut (
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .sum_vec(sum_vec),
        .carry_vec(carry_vec)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i, j, k;
    
    // 5-bit registers to hold the truncated comparisons
    reg [4:0] expected_val;
    reg [4:0] actual_val;

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING 5-BIT CSA VERIFICATION");
        $display("---------------------------------------------------------");

        // Loop through all 32,768 possible combinations
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                for (k = 0; k < 32; k = k + 1) begin
                    
                    // Set Inputs
                    in0 = i[4:0];
                    in1 = j[4:0];
                    in2 = k[4:0];

                    // Wait 5ns to let your 1.2ns structural gates settle
                    #5;

                    // Calculate Golden Value (Masked to bottom 5 bits)
                    expected_val = (in0 + in1 + in2) & 5'h1F;
                    
                    // Calculate Actual Output (Masked to bottom 5 bits)
                    actual_val = (sum_vec + carry_vec) & 5'h1F;

                    // Check Result
                    if (expected_val !== actual_val) begin
                        $display("❌ FAIL | %d + %d + %d | Got vectors sum=%b carry=%b (Mod32 Total: %d) | Exp: %d", 
                                  in0, in1, in2, sum_vec, carry_vec, actual_val, expected_val);
                        FAILURES = FAILURES + 1;
                    end else begin
                        SUCCESSES = SUCCESSES + 1;
                    end
                end
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("CSA TEST SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: The 5-bit CSA is mathematically sound!");
        else
            $display("💥 VERIFICATION FAILED: Check the bit-slice wiring.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule