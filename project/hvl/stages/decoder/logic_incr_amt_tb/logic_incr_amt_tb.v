`timescale 1ns / 1ps

module tb_logic_incr_amt();

    // 1. Signals matching the logic_incr_amt ports
    reg  [2:0] rom_sum;
    reg  [2:0] disp_size_inbytes;
    reg  [2:0] prefix_amount;
    reg        sib_present;
    wire [4:0] incr_amt;

    // 2. Instantiate the Unit Under Test (UUT)
    logic_incr_amt uut (
        .rom_sum(rom_sum),
        .disp_size_inbytes(disp_size_inbytes),
        .prefix_amount(prefix_amount),
        .sib_present(sib_present),
        .incr_amt(incr_amt)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i, j, k, l;
    
    // Golden reference calculation
    reg [4:0] expected_val;

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING INSTRUCTION LENGTH DECODER VERIFICATION");
        $display("---------------------------------------------------------");

        // Loop through all possible combinations (8 * 8 * 8 * 2 = 1024 total tests)
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    for (l = 0; l < 2; l = l + 1) begin
                        
                        // Set Inputs
                        rom_sum           = i[2:0];
                        disp_size_inbytes = j[2:0];
                        prefix_amount     = k[2:0];
                        sib_present       = l[0];

                        // Wait for maximum arrival time + gate delays.
                        // Longest arrival is 5.05ns. CSA + FA_5b takes ~4ns.
                        // Waiting 15ns guarantees the structural signals are fully stable.
                        #15;

                        // Calculate Golden Value
                        expected_val = rom_sum + disp_size_inbytes + prefix_amount + sib_present;

                        // Check Result
                        if (incr_amt !== expected_val) begin
                            $display("❌ FAIL | Rom:%d Disp:%d Pref:%d SIB:%b | Got Length: %d | Exp: %d", 
                                      rom_sum, disp_size_inbytes, prefix_amount, sib_present, incr_amt, expected_val);
                            FAILURES = FAILURES + 1;
                        end else begin
                            SUCCESSES = SUCCESSES + 1;
                            
                            // Let's print the specific test case you wrote in your comments!
                            if (rom_sum == 7 && disp_size_inbytes == 4 && prefix_amount == 4 && sib_present == 1) begin
                                $display("✅ PASS | TARGET HIT: 7 + 4 + 4 + 1 = %d", incr_amt);
                            end
                        end
                    end
                end
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("DECODER ADDER SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: The top-level length decoder is perfect!");
        else
            $display("💥 VERIFICATION FAILED: Check the wire connections between the CSA and FA_5b.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule