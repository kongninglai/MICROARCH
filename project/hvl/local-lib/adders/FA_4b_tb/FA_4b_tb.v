`timescale 1ns / 1ps

module tb_FA_4b();

    // 1. Signals matching the FA_4b ports
    reg  [3:0] in0, in1;
    reg        cin;
    wire [3:0] s;

    // 2. Instantiate the Unit Under Test (UUT)
    FA_4b uut (
        .in0(in0),
        .in1(in1),
        .cin(cin),
        .s(s)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i, j, k;
    
    // Golden reference calculation (5 bits wide to safely handle math before truncation)
    reg [4:0] expected_val;

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING 4-BIT PREFIX ADDER VERIFICATION");
        $display("---------------------------------------------------------");

        // Loop through all possible combinations 
        // (16 * 16 * 2 = 512 total tests)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    
                    // Set Inputs
                    in0 = i[3:0];
                    in1 = j[3:0];
                    cin = k[0];

                    // Wait for structural delay to settle
                    #5;

                    // Calculate Golden Value
                    expected_val = in0 + in1 + cin;

                    // Check Result (s is 4 bits, so we compare against the bottom 4 bits of expected_val)
                    if (s !== expected_val[3:0]) begin
                        $display("❌ FAIL | %d + %d + %b | Got Sum: %d | Exp Sum: %d", 
                                  in0, in1, cin, s, expected_val[3:0]);
                        FAILURES = FAILURES + 1;
                    end else begin
                        SUCCESSES = SUCCESSES + 1;
                    end
                end
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("ADDER TEST SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: Hardware matches Golden Model!");
        else
            $display("💥 VERIFICATION FAILED: Check prefix tree carry propagation.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule