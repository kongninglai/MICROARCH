`timescale 1ns / 1ps

module tb_logic_is_sib();

    reg [7:0] candidate_modrm;
    wire is_sib;

    // Instantiate UUT
    logic_is_sib uut (
        .candidate_modrm(candidate_modrm),
        .is_sib(is_sib)
    );

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING SIB DETECTION TESTS");
        $display("---------------------------------------------------------");

        // Case 1: Mod=00, R/M=100 ([ESP]) -> SHOULD BE SIB
        candidate_modrm = 8'b00_000_100; 
        #5;
        $display("MOD: 00, R/M: 100 | Result: %b | Expected: 1", is_sib);

        // Case 2: Mod=01, R/M=100 ([ESP+disp8]) -> SHOULD BE SIB
        candidate_modrm = 8'b01_000_100; 
        #5;
        $display("MOD: 01, R/M: 100 | Result: %b | Expected: 1", is_sib);

        // Case 3: Mod=11, R/M=100 (Register direct AH/ESP) -> SHOULD NOT BE SIB
        // In x86, Mod=11 means register-to-register, so no SIB follows.
        candidate_modrm = 8'b11_000_100; 
        #5;
        $display("MOD: 11, R/M: 100 | Result: %b | Expected: 0", is_sib);

        // Case 4: Mod=00, R/M=000 ([EAX]) -> SHOULD NOT BE SIB
        candidate_modrm = 8'b00_000_000; 
        #5;
        $display("MOD: 00, R/M: 000 | Result: %b | Expected: 0", is_sib);

        $display("---------------------------------------------------------");
        $finish;
    end

endmodule