/*
This module outputs the final modrm byte and the associated immediate information. 

Delay: 
0.24 + 2.69 + 0.47 (prefix num ready) + 0.8ns = 4.2ns total delay
Must wait until 3.38 to get output of prefix_num (3.38 - 2.91 = 0.47ns wait)

*/
module logic_true_modrm(
    input wire [7:0] candidate_opcode0,
    input wire [7:0] candidate_opcode1,
    input wire [7:0] candidate_opcode2,
    input wire [7:0] candidate_opcode3,
    input wire [7:0] candidate_opcode4,
    input wire [7:0] candidate_opcode5,
    input wire ext,
    input wire op_size,
    input wire [1:0] prefix_num,
    output wire [7:0] modrm_byte_true,
    output wire is_modrm_true,
    output wire [2:0] imm_size_inbytes_true,
    output wire [1:0] imm_size_true,
    output wire [2:0] sum_modrm_imm_true,
    output wire is_far_br_true
);

    //Layer 1: 0.24ns
    wire ext_buf, op_size_buf;
    bufferH16$ ext_buffer(ext_buf, ext);
    bufferH16$ op_size_buffer(op_size_buf, op_size);

    //Layer 2: 2.69ns + 0.47ns wait 
    //Lookup all potential opcodes bytes in parallel
    wire [1:0]imm_size0, imm_size1, imm_size2, imm_size3, imm_size4;
    wire is_modrm0, is_far_br0;
    wire [2:0] imm_size_inbytes0, sum_modrm_imm0;
    logic_modrm_imm MODRM_IMM_LOOKUP0(
        .opcode(candidate_opcode0), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm0), .imm_size(imm_size0), .imm_size_inbytes(imm_size_inbytes0), .sum_modrm_imm(sum_modrm_imm0), .is_far_br(is_far_br0)
    );

    wire is_modrm1, is_far_br1;
    wire [2:0] imm_size_inbytes1, sum_modrm_imm1;
    logic_modrm_imm MODRM_IMM_LOOKUP1(
        .opcode(candidate_opcode1), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm1), .imm_size(imm_size1), .imm_size_inbytes(imm_size_inbytes1), .sum_modrm_imm(sum_modrm_imm1), .is_far_br(is_far_br1)
    );

    wire is_modrm2, is_far_br2;
    wire [2:0] imm_size_inbytes2, sum_modrm_imm2;
    logic_modrm_imm MODRM_IMM_LOOKUP2(
        .opcode(candidate_opcode2), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm2), .imm_size(imm_size2), .imm_size_inbytes(imm_size_inbytes2), .sum_modrm_imm(sum_modrm_imm2), .is_far_br(is_far_br2)
    );

    wire is_modrm3, is_far_br3;
    wire [2:0] imm_size_inbytes3, sum_modrm_imm3;
    logic_modrm_imm MODRM_IMM_LOOKUP3(
        .opcode(candidate_opcode3), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm3), .imm_size(imm_size3), .imm_size_inbytes(imm_size_inbytes3), .sum_modrm_imm(sum_modrm_imm3), .is_far_br(is_far_br3)
    );

    wire is_modrm4, is_far_br4;
    wire [2:0] imm_size_inbytes4, sum_modrm_imm4;
    logic_modrm_imm MODRM_IMM_LOOKUP4(
        .opcode(candidate_opcode4), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm4), .imm_size(imm_size4), .imm_size_inbytes(imm_size_inbytes4), .sum_modrm_imm(sum_modrm_imm4), .is_far_br(is_far_br4)
    );

    //Layer 3: 0.8ns
    wire [7:0] imm_size_inbytes_temp, imm_size_temp;
    wire [7:0] sum_temp;
    wire [7:0] sib_idx_temp;
    mux4_8$ choose_modrm(.Y(modrm_byte_true), .IN0(candidate_opcode1), .IN1(candidate_opcode2), .IN2(candidate_opcode3), .IN3(candidate_opcode4), .S0(prefix_num[0]), .S1(prefix_num[1]));
    mux4$ choose_is_modrm(.outb(is_modrm_true), .in0(is_modrm0), .in1(is_modrm1), .in2(is_modrm2), .in3(is_modrm3), .s0(prefix_num[0]), .s1(prefix_num[1]));
    mux4_8$ choose_imm_size_inbytes(.Y(imm_size_inbytes_temp), .IN0({5'd0, imm_size_inbytes0}), .IN1({5'd0, imm_size_inbytes1}), .IN2({5'd0, imm_size_inbytes2}), .IN3({5'd0, imm_size_inbytes3}), .S0(prefix_num[0]), .S1(prefix_num[1]));
    mux4_8$ choose_imm_size(.Y(imm_size_temp), .IN0({6'd0, imm_size0}), .IN1({6'd0, imm_size1}), .IN2({6'd0, imm_size2}), .IN3({6'd0, imm_size3}), .S0(prefix_num[0]), .S1(prefix_num[1]));
    mux4_8$ choose_sum(.Y(sum_temp), .IN0({5'd0, sum_modrm_imm0}), .IN1({5'd0, sum_modrm_imm1}), .IN2({5'd0, sum_modrm_imm2}), .IN3({5'd0, sum_modrm_imm3}), .S0(prefix_num[0]), .S1(prefix_num[1]));
    mux4$ choose_is_far(.outb(is_far_br_true), .in0(is_far_br0), .in1(is_far_br1), .in2(is_far_br2), .in3(is_far_br3), .s0(prefix_num[0]), .s1(prefix_num[1]));
    assign imm_size_inbytes_true = imm_size_inbytes_temp[2:0];
    assign sum_modrm_imm_true = sum_temp[2:0];
    assign imm_size_true = imm_size_temp[1:0];

endmodule