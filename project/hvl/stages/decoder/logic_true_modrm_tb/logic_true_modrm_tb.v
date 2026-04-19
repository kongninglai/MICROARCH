/*
imm_size = 00 (1 byte), 01(2 bytes), 10(4 bytes), 11(6 bytes)
*/


`timescale 1ns / 1ps

module tb_logic_true_modrm_golden();

    // 1. UUT Signals
    reg [7:0] c [0:5]; // Candidate array
    reg ext, op_size;
    reg [1:0] prefix_num;
    
    wire [7:0] modrm_byte_true;
    wire is_modrm_true, is_far_br_true;
    wire [2:0] imm_size_inbytes_true, sum_true;
    wire [1:0] imm_size_true; 

    // 2. Golden Model Arrays (32-bit rows, 8 files total)
    reg [31:0] g_std_lo [0:31], g_std_hi [0:31];
    reg [31:0] g_oso_lo [0:31], g_oso_hi [0:31];
    reg [31:0] g_ext_lo [0:31], g_ext_hi [0:31];
    reg [31:0] g_exo_lo [0:31], g_exo_hi [0:31];

    // 3. Instantiate UUT
    logic_true_modrm uut (
        .candidate_opcode0(c[0]), .candidate_opcode1(c[1]), .candidate_opcode2(c[2]), 
        .candidate_opcode3(c[3]), .candidate_opcode4(c[4]), .candidate_opcode5(c[5]),
        .ext(ext), .op_size(op_size), .prefix_num(prefix_num),
        .modrm_byte_true(modrm_byte_true), 
        .is_modrm_true(is_modrm_true),
        .imm_size_inbytes_true(imm_size_inbytes_true),
        .imm_size_true(imm_size_true), 
        .sum_modrm_imm_true(sum_true),
        .is_far_br_true(is_far_br_true)
    );

    // 4. Verification Variables
    integer i_op;
    reg [31:0] row;
    reg [7:0]  exp_byte;
    reg [2:0]  expected_imm_size_bytes;

    // Error Checking
    integer FAILURES = 0;
    integer SUCCESSES = 0;
    
    // Kept original 8-bit check against ROM data
    wire [7:0] hw_res = {is_modrm_true, imm_size_inbytes_true, sum_true, is_far_br_true};

    // 5. Helper Task: Fetches "Truth" from ROM arrays based on current UUT inputs
    task verify_against_rom;
        input [127:0] msg;
        reg [7:0] target_op;
        reg [7:0] expected_modrm; 
        begin
            target_op = c[prefix_num]; 
            expected_modrm = c[prefix_num + 1]; // ModRM is always Opcode + 1
            
            // Logic to pick the correct Golden Array Row
            case({target_op[7], ext, op_size})
                3'b000: row = g_std_lo[target_op[6:2]];
                3'b001: row = g_oso_lo[target_op[6:2]];
                3'b010: row = g_ext_lo[target_op[6:2]];
                3'b011: row = g_exo_lo[target_op[6:2]];
                3'b100: row = g_std_hi[target_op[6:2]];
                3'b101: row = g_oso_hi[target_op[6:2]];
                3'b110: row = g_ext_hi[target_op[6:2]];
                3'b111: row = g_exo_hi[target_op[6:2]];
            endcase

            // Logic to pick the correct Byte in that Row
            case(target_op[1:0])
                2'b00: exp_byte = row[7:0];
                2'b01: exp_byte = row[15:8];
                2'b10: exp_byte = row[23:16];
                2'b11: exp_byte = row[31:24];
            endcase

            #10; // Wait for UUT delay 

            $display("SCENARIO: %s", msg);
            if (modrm_byte_true !== expected_modrm) begin
                $display("  [FAIL] MUX chose wrong ModRM byte: Got %h, Exp %h", modrm_byte_true, expected_modrm);
                FAILURES = FAILURES + 1;
            end
            else if (hw_res !== exp_byte) begin 
                $display("  [FAIL] ROM Props wrong: HW %b, ROM File %b", hw_res, exp_byte);
                FAILURES = FAILURES + 1;
            end
            else if (imm_size_inbytes_true !== expected_imm_size_bytes) begin
                $display("  [FAIL] imm_size_inbytes mismatch: Got %0d, Exp %0d", 
                          imm_size_inbytes_true, expected_imm_size_bytes);
                FAILURES = FAILURES + 1;
            end
            // Check the 2-bit mux signal logic (begin/end added here)
            else if ((expected_imm_size_bytes == 3'b001 && imm_size_true !== 2'b00) ||
                     (expected_imm_size_bytes == 3'b010 && imm_size_true !== 2'b01) ||
                     (expected_imm_size_bytes == 3'b100 && imm_size_true !== 2'b10)) begin
                $display("  [FAIL] imm_size_true (2-bit mux) mismatch for byte count %0d", expected_imm_size_bytes);
                FAILURES = FAILURES + 1;
            end
            else begin
                $display("  [PASS] Opcode %h matches ROM data perfectly.", target_op);
                SUCCESSES = SUCCESSES + 1;
            end
            $display("---------------------------------------------------------");
        end
    endtask

    initial begin
        // Load all 8 ROM files
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_std_lo.data", g_std_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_std_hi.data", g_std_hi);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_oso_lo.data", g_oso_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_oso_hi.data", g_oso_hi);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_lo.data", g_ext_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_hi.data", g_ext_hi);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_oso_lo.data", g_exo_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_oso_hi.data", g_exo_hi);

        #10;
        $display("STARTING ROM-INDEXED SCENARIO TESTS");

        // CASE 1: 0 Prefixes. Opcode 0x90 at index 0. ModRM at index 1.
        c[0]=8'h90; c[1]=8'hAA; c[2]=8'h00; c[3]=8'h00; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=0; prefix_num=0; expected_imm_size_bytes = 3'b000; 
        verify_against_rom("NOP at Index 0");

        // CASE 2: 2 Prefixes. Opcode 0x89 at index 2. ModRM at index 3.
        c[0]=8'hF3; c[1]=8'h66; c[2]=8'h89; c[3]=8'hBB; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=0; prefix_num=2; expected_imm_size_bytes = 3'b000;
        verify_against_rom("MOV at Index 2");

        // CASE 3: 1 Prefix. Opcode 0x05 at index 1. ModRM at index 2.
        c[0]=8'h66; c[1]=8'h05; c[2]=8'hCC; c[3]=8'h00; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=1; prefix_num=1; expected_imm_size_bytes = 3'b010; 
        verify_against_rom("ADD (OSO) at Index 1");

        // CASE 4: 4 Prefixes. Opcode 0xC3 at index 3. ModRM at index 4.
        // RET doesnt have an immediate encoded into the instruction
        c[0]=8'hF3; c[1]=8'h66; c[2]=8'h2E; c[3]=8'hC3; c[4]=8'hDD; c[5]=8'hFF;
        ext=0; op_size=0; prefix_num=3; expected_imm_size_bytes = 3'b000;
        verify_against_rom("RET at Index 3");

        // CASE 5: OR AL, imm8 (0C) with OSO Prefix (66); Instruction: 66 0C 12
        c[0]=8'h66; c[1]=8'h0C; c[2]=8'h12; c[3]=8'h00; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=1; prefix_num=1; 
        expected_imm_size_bytes = 3'b001; // Should be 1 byte
        verify_against_rom("OR AL (0C) with OSO Trap");
        // Expected values: imm_size_inbytes_true should be 1 (3'b001), imm_size_true (the 2-bit mux) should be 0 (2'b00)
                
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

        $finish;
    end
endmodule