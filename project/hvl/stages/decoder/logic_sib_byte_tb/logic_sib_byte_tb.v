`timescale 1ns / 1ps

module tb_logic_sib_byte();

    // 1. UUT Signals
    reg [7:0] c [1:6];    // Matches your 6 candidate inputs
    reg is_modrm_true;
    reg [2:0] prefix_num;
    
    wire [7:0] sib_byte_true;
    wire is_sib_true;

    // 2. Instantiate the Unit Under Test
    // FIXED: Removed candidate_modrm7 to match your module's 6-input header
    logic_sib_byte uut (
        .candidate_modrm1(c[1]), 
        .candidate_modrm2(c[2]), 
        .candidate_modrm3(c[3]),
        .candidate_modrm4(c[4]), 
        .candidate_modrm5(c[5]), 
        .candidate_modrm6(c[6]),
        .is_modrm_true(is_modrm_true),
        .prefix_num(prefix_num),
        .sib_byte_true(sib_byte_true),
        .is_sib_true(is_sib_true)
    );

    // Error Checking
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 3. Verification Task
    task verify_scenario(
        input [128:0] desc,
        input [2:0]   p_num,        
        input         modrm_valid,  
        input [7:0]   expected_sib, 
        input         expected_flag 
    );
    begin
        prefix_num = p_num;
        is_modrm_true = modrm_valid;
        
        #5; 

        $display("SCENARIO: %s", desc);
        $display("  Prefix Count: %0d | SIB_Valid: %b | SIB_Byte: %h", p_num, is_sib_true, sib_byte_true);
        
        if (is_sib_true !== expected_flag) begin
            $display("  [FAIL] SIB Flag mismatch! Got: %b, Exp: %b", is_sib_true, expected_flag);
            FAILURES = FAILURES + 1;
        end
        else if (expected_flag && (sib_byte_true !== expected_sib)) begin
            $display("  [FAIL] SIB Byte mismatch! Got: %h, Exp: %h", sib_byte_true, expected_sib);
            FAILURES = FAILURES + 1;
        end
        else begin
            $display("  [PASS]");
            SUCCESSES = SUCCESSES + 1;
        end
        $display("---------------------------------------------------------");
    end
    endtask

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING SPECULATIVE SIB SELECTION TESTS");
        $display("---------------------------------------------------------");

        // --- CASE 1: Standard MOV with SIB (No Prefixes) ---
        // 89 04 24 -> Opcode@0, ModRM@1, SIB@2.
        c[1] = 8'h04; c[2] = 8'h24; 
        verify_scenario("Standard SIB (No Prefix)", 3'd0, 1'b1, 8'h24, 1'b1);

        // --- CASE 2: The "Immediate Trap" ---
        c[1] = 8'h24; 
        verify_scenario("Immediate Trap (is_modrm=0)", 3'd0, 1'b0, 8'h00, 1'b0);

        // --- CASE 3: Register Direct Trap ---
        c[1] = 8'hE0; 
        verify_scenario("Register Direct Trap (Mod=11)", 3'd0, 1'b1, 8'h00, 1'b0);

        // --- CASE 4: Offset SIB (2 Prefixes) ---
        // 66 F2 89 04 24 -> Prefixes@0,1. Opcode@2, ModRM@3, SIB@4.
        c[3] = 8'h04; c[4] = 8'h24; 
        verify_scenario("Offset SIB (2 Prefixes)", 3'd2, 1'b1, 8'h24, 1'b1);

        // --- CASE 5: Max Prefix Lookahead (4 Prefixes) ---
        // Opcode@4, ModRM@5, SIB@6. 
        // This still fits in 6 candidates (candidate6 = index 6).
        c[5] = 8'h04; c[6] = 8'h24; 
        verify_scenario("Max Prefix Lookahead", 3'd4, 1'b1, 8'h24, 1'b1);

        $display("ALL TESTS COMPLETED.");
        $display("---------------------------------------------------------");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule