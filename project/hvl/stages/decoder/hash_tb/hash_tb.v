`timescale 1ns / 1ps

module tb_hash();

    // 1. Inputs (Must be 'reg' so we can drive them)
    reg [3:0] eip;
    reg [7:0] ghr;

    // 2. Outputs (Must be 'wire' to read from the module)
    wire [3:0] hash_out;

    // Error Checking 
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate the UUT (Unit Under Test)
    hash uut (
        .eip(eip),
        .ghr(ghr),
        .hash_out(hash_out)
    );

    // 4. Checking Task
    task check_result;
        input [8*25:1] test_name; 
        input [3:0] expected_val;
        begin
            #5; // Wait 5ns for combinational logic gates to propagate
            if (hash_out === expected_val) begin
                $display("  ✅ PASS | %0s | eip:%b ghr:%b -> hash:%b", test_name, eip, ghr, hash_out);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: %b", expected_val);
                $display("     ACTUAL  : %b", hash_out);
                FAILURES = FAILURES + 1;
            end
            #5; // Wait a bit before the next test
        end
    endtask

    // 5. Stimulus Sequence
    initial begin
        // Setup waveform dumping
        $dumpfile("hash_tb.vpd");
        $dumpvars(0, tb_hash);

        $display("=======================================");
        $display("          GSHARE HASH FUNCTION TEST    ");
        $display("=======================================");

        // --------------------------------------------------------
        // TEST 1: All Zeros
        // Expected: (0000 ^ 0000) ^ 0000 = 0000
        // --------------------------------------------------------
        eip = 4'b0000;
        ghr = 8'b0000_0000;
        check_result("All Zeros          ", 4'b0000);

        // --------------------------------------------------------
        // TEST 2: All Ones
        // Expected: (1111 ^ 1111) ^ 1111 = 0000 ^ 1111 = 1111
        // --------------------------------------------------------
        eip = 4'b1111;
        ghr = 8'b1111_1111;
        check_result("All Ones           ", 4'b1111);

        // --------------------------------------------------------
        // TEST 3: GHR folding yields 1s, XOR with 0 EIP
        // Expected: (1010 ^ 0101) = 1111. 1111 ^ 0000 = 1111
        // --------------------------------------------------------
        eip = 4'b0000;
        ghr = 8'b1010_0101;
        check_result("GHR fold inverse   ", 4'b1111);

        // --------------------------------------------------------
        // TEST 4: EIP Isolation
        // Expected: (0000 ^ 0000) ^ 1011 = 1011
        // --------------------------------------------------------
        eip = 4'b1011;
        ghr = 8'b0000_0000;
        check_result("EIP Only           ", 4'b1011);

        // --------------------------------------------------------
        // TEST 5: Complex Mixed Hash
        // Expected: (1100 ^ 0011) = 1111. 1111 ^ 1010 = 0101
        // --------------------------------------------------------
        eip = 4'b1010;
        ghr = 8'b1100_0011;
        check_result("Complex Hash Mix   ", 4'b0101);

        // --------------------------------------------------------
        // TEST 6: Identical Halves (Self-canceling GHR)
        // Expected: (1101 ^ 1101) = 0000. 0000 ^ 0110 = 0110
        // --------------------------------------------------------
        eip = 4'b0110;
        ghr = 8'b1101_1101;
        check_result("Self-Canceling GHR ", 4'b0110);


        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule