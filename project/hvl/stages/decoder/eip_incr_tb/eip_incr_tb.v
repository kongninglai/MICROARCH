`timescale 1ns / 1ps

module tb_eip_incr();

    // 1. Signals
    reg  [3:0]  incr_amt;
    reg  [31:0] eip;
    wire [31:0] incr_eip;

    // 2. Instantiate UUT
    eip_incr uut (
        .incr_amt(incr_amt),
        .eip(eip),
        .incr_eip(incr_eip)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i, j;
    
    // Golden reference
    reg [31:0] expected_val;

    // Array of corner cases
    reg [31:0] corner_cases [0:4];
    
    initial begin
        // Initialize Corner Cases
        corner_cases[0] = 32'h00000000; // Zero
        corner_cases[1] = 32'hFFFFFFFF; // Max value (should wrap around)
        corner_cases[2] = 32'h0000FFFF; // Half-word boundary
        corner_cases[3] = 32'h7FFFFFFF; // Max positive signed
        corner_cases[4] = 32'hFFFFFFFE; // Almost max

        $display("---------------------------------------------------------");
        $display("STARTING EIP INCREMENTER VERIFICATION");
        $display("---------------------------------------------------------");

        // --- PART 1: TEST CORNER CASES ---
        $display("Running Corner Cases...");
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                eip      = corner_cases[i];
                incr_amt = j[3:0];

                #10; // Wait for the adders and mux to settle

                expected_val = eip + incr_amt;

                if (incr_eip !== expected_val) begin
                    $display("❌ FAIL | EIP: %h + Incr: %d | Got: %h | Exp: %h", 
                              eip, incr_amt, incr_eip, expected_val);
                    FAILURES = FAILURES + 1;
                end else begin
                    SUCCESSES = SUCCESSES + 1;
                end
            end
        end

        // --- PART 2: TEST RANDOM ADDRESSES ---
        $display("Running Random EIP Values...");
        for (i = 0; i < 100; i = i + 1) begin
            // Generate a random 32-bit EIP
            eip = {$random, $random}; 
            
            for (j = 0; j < 16; j = j + 1) begin
                incr_amt = j[3:0];

                #10;

                expected_val = eip + incr_amt;

                if (incr_eip !== expected_val) begin
                    $display("❌ FAIL | EIP: %h + Incr: %d | Got: %h | Exp: %h", 
                              eip, incr_amt, incr_eip, expected_val);
                    FAILURES = FAILURES + 1;
                end else begin
                    SUCCESSES = SUCCESSES + 1;
                end
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("EIP INCR TEST SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: Pre-compute MUX logic works perfectly!");
        else
            $display("💥 VERIFICATION FAILED: Check your mux port mappings or PA_32b instantiation.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule