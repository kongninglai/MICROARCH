`timescale 1ns / 1ps

module tb_logic_branch();

    // 1. Inputs
    reg [7:0] opcode;
    reg [7:0] modrm;
    reg       v_modrm;
    reg       ext_opcode;

    // 2. Outputs
    wire       is_branch;
    wire [1:0] branch_type;

    // 3. Instantiate UUT
    logic_branch uut (
        .opcode(opcode),
        .modrm(modrm),
        .v_modrm(v_modrm),
        .ext_opcode(ext_opcode),
        .is_branch(is_branch),
        .branch_type(branch_type)
    );

    // 4. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Expected Values
    reg exp_is_branch;
    reg [1:0] exp_branch_type;

    // 5. Checking Task
    task check_result;
        input [8*25:1] test_name; 
        begin
            #10; // Wait for logic to settle
            $display("-----------------------------------------------------------------------");
            $display("TEST: %0s", test_name);
            $display("  INPUTS -> Opcode: %h | ModR/M: %h | Ext: %b | V_Mod: %b", opcode, modrm, ext_opcode, v_modrm);

            if (is_branch !== exp_is_branch || branch_type !== exp_branch_type) begin
                $display("  ❌ FAIL");
                $display("     EXPECT : is_branch=%b | branch_type=%b", exp_is_branch, exp_branch_type);
                $display("     ACTUAL : is_branch=%b | branch_type=%b", is_branch, branch_type);
                FAILURES = FAILURES + 1;
            end else begin
                $display("  ✅ PASS (Type: %b)", branch_type);
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin
        $display("=======================================================================");
        $display("                     BRANCH DECODE TEST SUITE                          ");
        $display("=======================================================================");

        // Initialize safe defaults
        opcode = 8'h00; modrm = 8'h00; v_modrm = 0; ext_opcode = 0;

        // TEST 1: Normal Math Instruction (ADD)
        opcode = 8'h01; ext_opcode = 0;
        exp_is_branch = 0; exp_branch_type = 2'b00;
        check_result("ADD r/m32, r32");

        // TEST 2: JMP rel8 (Unconditional Near)
        opcode = 8'hEB; ext_opcode = 0;
        exp_is_branch = 1; exp_branch_type = 2'b01;
        check_result("JMP rel8");

        // TEST 3: JNE rel8 (Conditional Near - No Prefix)
        opcode = 8'h75; ext_opcode = 0;
        exp_is_branch = 1; exp_branch_type = 2'b10;
        check_result("JNE rel8");

        // TEST 4: JNE rel32 (Conditional Near - WITH Prefix)
        opcode = 8'h85; ext_opcode = 1;
        exp_is_branch = 1; exp_branch_type = 2'b10;
        check_result("JNE rel32 (0F Prefix)");

        // TEST 5: TEST r/m32 (Tricky! Same opcode as JNE rel32, but NO prefix)
        opcode = 8'h85; ext_opcode = 0;
        exp_is_branch = 0; exp_branch_type = 2'b00;
        check_result("TEST r/m32 (NO Prefix)");

        // TEST 6: IRETd (Far Branch)
        opcode = 8'hCF; ext_opcode = 0;
        exp_is_branch = 1; exp_branch_type = 2'b11;
        check_result("IRETd");

        // TEST 7: CALL r/m32 (FF edge case - /2 ModR/M)
        opcode = 8'hFF; ext_opcode = 0; v_modrm = 1; modrm = 8'b00_010_000; // /2
        exp_is_branch = 1; exp_branch_type = 2'b01;
        check_result("CALL r/m32 (FF /2)");

        // TEST 8: PUSH r/m32 (FF edge case - /6 ModR/M - NOT A BRANCH)
        opcode = 8'hFF; ext_opcode = 0; v_modrm = 1; modrm = 8'b00_110_000; // /6
        exp_is_branch = 0; exp_branch_type = 2'b00;
        check_result("PUSH r/m32 (FF /6)");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule