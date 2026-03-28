`timescale 1ns / 1ps

module tb_logic_is_sib();

    reg [7:0] candidate_modrm;
    wire is_sib;

    // Instantiate UUT
    logic_is_sib uut (
        .candidate_modrm(candidate_modrm),
        .is_sib(is_sib)
    );

    // Error Checking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer total_tests = 0;

    // Task to automate checking and counter incrementing
    task check_sib;
        input [1:0] mod;
        input [2:0] rm;
        input expected;
        begin
            total_tests = total_tests + 1;
            candidate_modrm = {mod, 3'b000, rm}; // Keep Reg/Opcode bits as 000
            #5;
            
            if (is_sib === expected) begin
                $display("✅ PASS | MOD: %b, R/M: %b | Result: %b | Expected: %b", mod, rm, is_sib, expected);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("❌ FAIL | MOD: %b, R/M: %b | Result: %b | Expected: %b", mod, rm, is_sib, expected);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING SIB DETECTION TESTS");
        $display("---------------------------------------------------------");

        // Case 1: Mod=00, R/M=100 ([ESP]) -> SHOULD BE SIB
        check_sib(2'b00, 3'b100, 1'b1);

        // Case 2: Mod=01, R/M=100 ([ESP+disp8]) -> SHOULD BE SIB
        check_sib(2'b01, 3'b100, 1'b1);

        // Case 3: Mod=11, R/M=100 (Register direct) -> SHOULD NOT BE SIB
        check_sib(2'b11, 3'b100, 1'b0);

        // Case 4: Mod=00, R/M=000 ([EAX]) -> SHOULD NOT BE SIB
        check_sib(2'b00, 3'b000, 1'b0);

        // Case 5: Mod=10, R/M=100 ([ESP+disp32]) -> SHOULD BE SIB
        check_sib(2'b10, 3'b100, 1'b1);

        $display("---------------------------------------------------------");
        
        if (FAILURES == 0) begin
            $display("🎉 ALL SIB TESTS PASSED!");
        end else begin
            $display("💥 SIB DETECTION FAILED WITH %0d ERRORS!", FAILURES);
        end
        $display("---------------------------------------------------------");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule