/*
This module outputs the final modrm byte and the associated immediate information. 

Delay: 
0.24 + 2.69 (2.93 total) + 0.21 + 
Must wait until 3.14 to get output of first stage (3.14 - 2.91 = 0.21 wait)

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
    input wire [2:0] prefix_num,
    ouptut wire [2:0] modrm_idx, 
    output wire [7:0] modrm_byte_true,
    output wire is_modrm_true,
    output wire [2:0] imm_size_inbytes_true,
    output wire [2:0] sum_modrm_imm_true,
    output wire is_far_br_true
);

    //Layer 1: 0.24ns
    wire ext_buf, op_size_buf;
    bufferH16$ ext_buffer(ext_buf, ext);
    bufferH16$ op_size_buffer(op_size_buf, op_size);

    //Layer 2: 2.69ns + 0.21 wait 
    //Lookup all potential opcodes bytes in parallel
    wire is_modrm0, is_far_br0;
    wire [2:0] imm_size_inbytes0, sum_modrm_imm0;
    logic_modrm_imm MODRM_IMM_LOOKUP0(
        .opcode(candidate_opcode0), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm0), .imm_size_inbytes(imm_size_inbytes0), .sum_modrm_imm(sum_modrm_imm0), .is_far_br(is_far_br0)
    );

    wire is_modrm1, is_far_br1;
    wire [2:0] imm_size_inbytes1, sum_modrm_imm1;
    logic_modrm_imm MODRM_IMM_LOOKUP1(
        .opcode(candidate_opcode1), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm1), .imm_size_inbytes(imm_size_inbytes1), .sum_modrm_imm(sum_modrm_imm1), .is_far_br(is_far_br1)
    );

    wire is_modrm2, is_far_br2;
    wire [2:0] imm_size_inbytes2, sum_modrm_imm2;
    logic_modrm_imm MODRM_IMM_LOOKUP2(
        .opcode(candidate_opcode2), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm2), .imm_size_inbytes(imm_size_inbytes2), .sum_modrm_imm(sum_modrm_imm2), .is_far_br(is_far_br2)
    );

    wire is_modrm3, is_far_br3;
    wire [2:0] imm_size_inbytes3, sum_modrm_imm3;
    logic_modrm_imm MODRM_IMM_LOOKUP3(
        .opcode(candidate_opcode3), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm3), .imm_size_inbytes(imm_size_inbytes3), .sum_modrm_imm(sum_modrm_imm3), .is_far_br(is_far_br3)
    );

    wire is_modrm4, is_far_br4;
    wire [2:0] imm_size_inbytes4, sum_modrm_imm4;
    logic_modrm_imm MODRM_IMM_LOOKUP4(
        .opcode(candidate_opcode4), .ext(ext_buf), .op_size(op_size_buf),
        .is_modrm(is_modrm4), .imm_size_inbytes(imm_size_inbytes4), .sum_modrm_imm(sum_modrm_imm4), .is_far_br(is_far_br4)
    );

    //Layer 3: 0.8ns
    wire [7:0] imm_size_temp;
    wire [7:0] sum_temp;
    wire [7:0] modrm_idx_temp;
    mux8_8 choose_modrm(.Y(modrm_byte_true), .IN0(candidate_opcode1), .IN1(candidate_opcode2), .IN2(candidate_opcode3), .IN3(candidate_opcode4), .IN4(candidate_opcode5), .IN5(8'd0), .IN6(8'd0), .IN7(8'd0), .S0(prefix_num[0]), .S1(prefix_num[1]), .S2(prefix_num[2]));
    mux8 choose_is_modrm(.outb(is_modrm_true), .in0(is_modrm0), .in1(is_modrm1), .in2(is_modrm2), .in3(is_modrm3), .in4(is_modrm4), .in5(1'd0), .in6(1'd0), .in7(1'd0), .s0(prefix_num[0]), .s1(prefix_num[1]), .s2(prefix_num[2]));
    mux8_8 choose_modrm_idx(.outb(modrm_idx_temp), .in0(3'd1), .in1(3'd2), .in2(3'd3), .in3(3'd4), .in4(3'd5), .in5(3'd0), .in6(3'd0), .in7(3'd0), .s0(prefix_num[0]), .s1(prefix_num[1]), .s2(prefix_num[2]));
    mux8_8 choose_imm_size(.Y(imm_size_temp), .IN0({5'd0, imm_size_inbytes0}), .IN1({5'd0, imm_size_inbytes1}), .IN2({5'd0, imm_size_inbytes2}), .IN3({5'd0, imm_size_inbytes3}), .IN4({5'd0, imm_size_inbytes4}), .IN5(8'd0), .IN6(8'd0), .IN7(8'd0), .S0(prefix_num[0]), .S1(prefix_num[1]), .S2(prefix_num[2]));
    mux8_8 choose_sum(.Y(sum_temp), .IN0({5'd0, sum_modrm_imm0}), .IN1({5'd0, sum_modrm_imm1}), .IN2({5'd0, sum_modrm_imm2}), .IN3({5'd0, sum_modrm_imm3}), .IN4({5'd0, sum_modrm_imm4}), .IN5(8'd0), .IN6(8'd0), .IN7(8'd0), .S0(prefix_num[0]), .S1(prefix_num[1]), .S2(prefix_num[2]));
    mux8 choose_is_far(.outb(is_far_br_true), .in0(is_far_br0), .in1(is_far_br1), .in2(is_far_br2), .in3(is_far_br3), .in4(is_far_br4), .in5(1'd0), .in6(1'd0), .in7(1'd0), .s0(prefix_num[0]), .s1(prefix_num[1]), .s2(prefix_num[2]));
    assign modrm_idx = modrm_idx_temp[2:0];
    assign imm_size_inbytes_true = imm_size_temp[2:0];
    assign sum_modrm_imm_true = sum_temp[2:0];

endmodule