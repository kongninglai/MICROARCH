`timescale 1ns / 1ps

module tb_block_decoder();

    // 1. UUT Signals
    reg [127:0] cache_line;
    reg [31:0]  o_eip_in;
    
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0]  prefix_seg_ov_id;
    wire [7:0]  opcode, modrm, sib;
    wire [1:0]  disp_size_mux, imm_size_mux, addressing_mode;
    wire [31:0] disp, imm, o_eip_out, i_eip_out;
    wire        double_imm;

    // 2. Instantiate the Unit Under Test (UUT)
    block_decoder uut (
        .cache_line(cache_line),
        .o_eip_in(o_eip_in),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm(modrm),
        .sib(sib),
        .disp_size_mux(disp_size_mux),
        .disp(disp),
        .imm_size_mux(imm_size_mux),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .double_imm(double_imm),
        .o_eip_out(o_eip_out),
        .i_eip_out(i_eip_out)
    );

    // 3. Helper Task to simplify scenario testing
    task run_scenario(
        input [128:0] desc,
        input [127:0] line_data,
        input [7:0]   expected_opcode,
        input         expected_mrm_flag // We can use internal wires if exposed, 
                                        // or verify via secondary outputs
    );
    begin
        cache_line = line_data;
        o_eip_in = 32'h0000_0000;
        
        #15; // Wait for logic to settle (Predecoder delay ~10ns)

        $display("--- SCENARIO: %s ---", desc);
        $display("  Instruction: %h %h %h %h %h", line_data[7:0], line_data[15:8], 
                                                   line_data[23:16], line_data[31:24], line_data[39:32]);
        
        if (opcode !== expected_opcode)
            $display("  [FAIL] Opcode mismatch! Got %h, Expected %h", opcode, expected_opcode);
        else
            $display("  [PASS] Opcode identified correctly.");

        // Check prefixes based on the description
        if (desc == "NOP (No Prefix)" && (prefix_rep || prefix_op_size))
            $display("  [FAIL] Prefixes wrongly detected!");
            
        $display("---------------------------------------------------------");
    end
    endtask

    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING BLOCK DECODER INTEGRATION TESTS");
        $display("---------------------------------------------------------");

        // Scenario 1: Simple Instruction (No Prefixes, No ModRM)
        // 90 (NOP)
        run_scenario("NOP (No Prefix)", 128'h0000_0000_0000_0000_0000_0000_0000_0090, 8'h90, 0);

        // Scenario 2: Instruction with ModRM (No Prefixes)
        // 89 D8 (MOV EAX, EBX)
        // Byte 0: 89 (Opcode), Byte 1: D8 (ModRM)
        run_scenario("MOV (No Prefix, Has ModRM)", 128'h0000_0000_0000_0000_0000_0000_0000_D889, 8'h89, 1);

        // Scenario 3: Instruction with 1 Prefix and ModRM
        // 66 89 D8 (MOV AX, BX - Operand Size Override)
        // Byte 0: 66 (Prefix), Byte 1: 89 (Opcode), Byte 2: D8 (ModRM)
        run_scenario("MOV (66h Prefix, Has ModRM)", 128'h0000_0000_0000_0000_0000_0000_D88966, 8'h89, 1);

        // Scenario 4: Instruction with 2 Prefixes (Rep and Seg Override)
        // F3 2E 90 (REP CS NOP)
        // Byte 0: F3, Byte 1: 2E, Byte 2: 90 (Opcode)
        run_scenario("NOP (F3h 2Eh Prefixes)", 128'h0000_0000_0000_0000_0000_0000_00902EF3, 8'h90, 0);

        // Scenario 5: Extended Opcode with Prefixes
        // 66 0F 11 (MOVAPS with OSO)
        // Byte 0: 66, Byte 1: 0F (Sets EXT), Byte 2: 11 (Opcode)
        run_scenario("MOVAPS (66h 0Fh Prefixes)", 128'h0000_0000_0000_0000_0000_0000_00110F66, 8'h11, 1);

        $display("ALL TESTS COMPLETED.");
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule