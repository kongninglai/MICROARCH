`timescale 1ns / 1ps

module tb_csa_bit_nand();

    // 1. Signals
    reg  a, b, c;
    wire sum, carry;

    // 2. Instantiate the Unit Under Test (UUT)
    csa_bitslice uut (
        .a(a),
        .b(b),
        .c(c),
        .sum(sum),
        .carry(carry)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;
    
    // Golden reference calculation (2 bits wide to hold values 0, 1, 2, or 3)
    reg [1:0] expected_val;

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING 1-BIT NAND CSA VERIFICATION");
        $display("---------------------------------------------------------");

        // Loop through all 8 possible input combinations (000 to 111)
        for (i = 0; i < 8; i = i + 1) begin
            
            // Map the loop variable bits to inputs A, B, C
            {a, b, c} = i[2:0];

            // Wait for the structural NAND gates to settle
            #5;

            // Calculate Golden Value (A + B + C)
            expected_val = a + b + c;

            // Check Result: expected_val[0] is sum, expected_val[1] is carry
            if (sum !== expected_val[0] || carry !== expected_val[1]) begin
                $display("❌ FAIL | %b + %b + %b | Got Sum: %b Carry: %b | Exp Sum: %b Carry: %b", 
                          a, b, c, sum, carry, expected_val[0], expected_val[1]);
                FAILURES = FAILURES + 1;
            end else begin
                $display("✅ PASS | %b + %b + %b = %d (Sum: %b, Carry: %b)", 
                          a, b, c, expected_val, sum, carry);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("NAND CSA SLICE SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: The 9-NAND logic is perfect!");
        else
            $display("💥 VERIFICATION FAILED: Check your NAND gate wiring.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule