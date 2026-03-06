`timescale 1ns / 1ps

module tb_logic_true_modrm_golden();

    // 1. UUT Signals
    reg [7:0] c [0:5]; // Candidate array
    reg ext, op_size;
    reg [2:0] prefix_num;
    
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
    
    // Kept original 8-bit check against ROM data
    wire [7:0] hw_res = {is_modrm_true, imm_size_inbytes_true, sum_true, is_far_br_true};

    // 5. Helper Task: Fetches "Truth" from ROM arrays based on current UUT inputs
    task verify_against_rom;
        input [127:0] msg;
        reg [7:0] target_op;
        reg [7:0] expected_modrm; 
        reg [1:0] exp_imm_size_bits; 
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

            // Convert ROM's 3-bit byte count (bits 6:4) into the 2-bit expected output
            case(exp_byte[6:4])
                3'd0: exp_imm_size_bits = 2'b00; // 0 bytes
                3'd1: exp_imm_size_bits = 2'b01; // 1 byte
                3'd2: exp_imm_size_bits = 2'b10; // 2 bytes
                3'd4: exp_imm_size_bits = 2'b11; // 4 bytes 
                default: exp_imm_size_bits = 2'b00;
            endcase

            #10; // Wait for UUT delay 

            $display("SCENARIO: %s", msg);
            if (modrm_byte_true !== expected_modrm) 
                $display("  [FAIL] MUX chose wrong ModRM byte: Got %h, Exp %h", modrm_byte_true, expected_modrm);
            else if (hw_res !== exp_byte)
                $display("  [FAIL] ROM Props wrong: HW %b, ROM File %b", hw_res, exp_byte);
            else if (imm_size_true !== exp_imm_size_bits)
                $display("  [FAIL] imm_size (2-bit) mismatch: Got %b, Exp %b (from ROM %0d bytes)", 
                          imm_size_true, exp_imm_size_bits, exp_byte[6:4]);
            else
                $display("  [PASS] Opcode %h matches ROM data perfectly.", target_op);
            $display("---------------------------------------------------------");
        end
    endtask

    initial begin
        // Load all 8 ROM files
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_lo.data", g_std_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_hi.data", g_std_hi);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_lo.data", g_oso_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_hi.data", g_oso_hi);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_lo.data", g_ext_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_hi.data", g_ext_hi);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_lo.data", g_exo_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_hi.data", g_exo_hi);

        #10;
        $display("STARTING ROM-INDEXED SCENARIO TESTS");

        // CASE 1: 0 Prefixes. Opcode 0x90 at index 0. ModRM at index 1.
        c[0]=8'h90; c[1]=8'hAA; c[2]=8'h00; c[3]=8'h00; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=0; prefix_num=0;
        verify_against_rom("NOP at Index 0");

        // CASE 2: 2 Prefixes. Opcode 0x89 at index 2. ModRM at index 3.
        c[0]=8'hF3; c[1]=8'h66; c[2]=8'h89; c[3]=8'hBB; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=0; prefix_num=2;
        verify_against_rom("MOV at Index 2");

        // CASE 3: 1 Prefix. Opcode 0x05 at index 1. ModRM at index 2.
        c[0]=8'h66; c[1]=8'h05; c[2]=8'hCC; c[3]=8'h00; c[4]=8'h00; c[5]=8'h00;
        ext=0; op_size=1; prefix_num=1;
        verify_against_rom("ADD (OSO) at Index 1");

        // CASE 4: 4 Prefixes. Opcode 0xC3 at index 4. ModRM at index 5.
        c[0]=8'hF3; c[1]=8'h66; c[2]=8'h2E; c[3]=8'h3E; c[4]=8'hC3; c[5]=8'hDD;
        ext=0; op_size=0; prefix_num=4;
        verify_against_rom("RET at Index 4");

        $finish;
    end
endmodule