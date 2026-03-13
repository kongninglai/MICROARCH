`timescale 1ns / 1ps

module tb_mux2_32();

    // Inputs
    reg [31:0] IN0;
    reg [31:0] IN1;
    reg S0;

    // Outputs
    wire [31:0] Y;

    // Error tracking
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    mux2_32 uut (
        .Y(Y),
        .IN0(IN0),
        .IN1(IN1),
        .S0(S0)
    );

    initial begin
        // Initialize Inputs
        IN0 = 32'hAAAAAAAA; // Alternating 1s and 0s
        IN1 = 32'h55555555; // Alternating 0s and 1s
        S0  = 1'b0;

        $display("===============================================================");
        $display("Starting Self-Checking TB for Structural mux2_32$...");
        $display("===============================================================");

        // Wait a bit for initial gate delays to settle
        #10;

        // Test 1: Select IN0
        S0 = 1'b0;
        #5; // Wait past the 0.33ns max select delay
        if (Y !== IN0) begin
            $display("❌ FAIL [Test 1]: S0=0 | Expected Y=%h, Got Y=%h", IN0, Y);
            error_count = error_count + 1;
            FAILURES = FAILURES + 1;
        end else begin
            $display("✅ PASS [Test 1]: S0=0 | Y correctly matched IN0 (%h)", Y);
            SUCCESSES = SUCCESSES + 1;
        end

        // Test 2: Select IN1
        S0 = 1'b1;
        #5;
        if (Y !== IN1) begin
            $display("❌ FAIL [Test 2]: S0=1 | Expected Y=%h, Got Y=%h", IN1, Y);
            error_count = error_count + 1;
            FAILURES = FAILURES + 1;
        end else begin
            $display("✅ PASS [Test 2]: S0=1 | Y correctly matched IN1 (%h)", Y);
            SUCCESSES = SUCCESSES + 1;
        end

        // Test 3: Change IN1 data while it is selected
        IN1 = 32'hDEADBEEF;
        #5; // Wait past the 0.22ns max data delay
        if (Y !== IN1) begin
            $display("❌ FAIL [Test 3]: S0=1 (Data update) | Expected Y=%h, Got Y=%h", IN1, Y);
            error_count = error_count + 1;
            FAILURES = FAILURES + 1;
        end else begin
            $display("✅ PASS [Test 3]: S0=1 (Data update) | Y successfully tracked IN1 change (%h)", Y);
            SUCCESSES = SUCCESSES + 1;
        end

        // Test 4: Select IN0 and change its data
        IN0 = 32'hCAFEBABE;
        S0 = 1'b0;
        #5;
        if (Y !== IN0) begin
            $display("❌ FAIL [Test 4]: S0=0 (Select & Data update) | Expected Y=%h, Got Y=%h", IN0, Y);
            error_count = error_count + 1;
            FAILURES = FAILURES + 1;
        end else begin
            $display("✅ PASS [Test 4]: S0=0 (Select & Data update) | Y successfully tracked IN0 change (%h)", Y);
            SUCCESSES = SUCCESSES + 1;
        end

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule