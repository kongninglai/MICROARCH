/* 
This module extracts the immediate value 
*/
module logic_imm(
    input wire [127:8] cache_bits, //bytes 1-14 of the instruction cache
    input wire [3:0] total_offset, //ready at 6.45ns from p_m_s_d_adder
    input wire [1:0] imm_size, //ready at 4.2ns (comes from logic_true_modrm)
    input wire [1:0] sum_1_lower,
    output wire [47:0] imm_bytes,
    output wire [31:0] bp_imm
);  

    wire [7:0] cache_bytes [1:14];
    genvar i;
    
    // Layer 0: 0.24ns hidden by logic_disp_size latency
    generate
        for (i = 1; i <= 14; i = i + 1) begin : unpack_and_buffer_cache
            assign cache_bytes[i] = cache_bits[(i*8)+7 : (i*8)];
        end
    endgenerate

    wire [7:0] rel8;
    wire [15:0] rel16;
    wire [31:0] rel32;

    // Only real possibilites are inst. lengths 2, 3, 4 (supported 5 just for fun)
    // 2 = 10, 3 = 11, 4 = 00, 5 = 01
    mux4_8$  mux4_8$_rel8
    (
      rel8,
      cache_bytes[3],
      cache_bytes[4],
      cache_bytes[1],
      cache_bytes[2],
      sum_1_lower[0],
      sum_1_lower[1]
    );

    // Only real possibilities are override, opcode, rel16 (4) |OR| override, dummy_override, ext_opcode, opcode, rel16 (6) (supported 7 just for fun)
    // 4 = 00, 5 = 01, 6 = 10, 7 = 11
    mux4_16$  mux4_16$_rel16
    (
      rel16,
      {cache_bytes[3], cache_bytes[2]},
      {cache_bytes[4], cache_bytes[3]},
      {cache_bytes[5], cache_bytes[4]},
      {cache_bytes[6], cache_bytes[5]},
      sum_1_lower[0],
      sum_1_lower[1]
    );

    // Only real possibilities are opcode, rel32 (5) |OR| ext_opcode, opcode, rel32 (6) |OR| dummy_override, ext_opcode, opcode, rel32 (7) (supported 8 just for fun)
    // 5 = 01, 6 = 10, 7 = 11, 8 = 00
    mux4_16$  mux4_16$_rel32_low
    (
      rel32[15:0],
      {cache_bytes[5], cache_bytes[4]},
      {cache_bytes[2], cache_bytes[1]},
      {cache_bytes[3], cache_bytes[2]},
      {cache_bytes[4], cache_bytes[3]},
      sum_1_lower[0],
      sum_1_lower[1]
    );

    mux4_16$  mux4_16$_rel32_high
    (
      rel32[31:16],
      {cache_bytes[7], cache_bytes[6]},
      {cache_bytes[4], cache_bytes[3]},
      {cache_bytes[5], cache_bytes[4]},
      {cache_bytes[6], cache_bytes[5]},
      sum_1_lower[0],
      sum_1_lower[1]
    );

    mux4_16$  mux4_16$_bp_imm_low
    (
      bp_imm[15:0],
      {{8{rel8[7]}}, rel8},
      rel16,
      rel32[15:0],
      ,
      imm_size[0],
      imm_size[1]
    );

    mux4_16$  mux4_16$_bp_imm_high
    (
      bp_imm[31:16],
      {16{rel8[7]}},
      {16{rel16[15]}},
      rel32[31:16],
      ,
      imm_size[0],
      imm_size[1]
    );

    //Layer 1: takes 1.1ns
    wire [47:0] imm_bytes48, imm_bytes32, imm_bytes16, imm_bytes8;
    mux16_48 imm_byte_mux48(
        .Y(imm_bytes48), 
        .IN0({cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2], cache_bytes[1]}), 
        .IN1({cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), 
        .IN2({cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), 
        .IN3({cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), 
        .IN4({cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), 
        .IN5({cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}),
        .IN6({cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}),
        .IN7({cache_bytes[13], cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), 
        .IN8({cache_bytes[14], cache_bytes[13], cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9]}), 
        .IN9(48'd0), 
        .IN10(48'd0), 
        .IN11(48'd0),
        .IN12(48'd0),
        .IN13(48'd0),
        .IN14(48'd0),
        .IN15(48'd0),
        .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]), .S3(total_offset[3])
    );

    mux16_48 imm_byte_mux32(
        .Y(imm_bytes32), 
        .IN0({16'd0, cache_bytes[4], cache_bytes[3], cache_bytes[2], cache_bytes[1]}), 
        .IN1({16'd0, cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), 
        .IN2({16'd0, cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), 
        .IN3({16'd0, cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), 
        .IN4({16'd0, cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), 
        .IN5({16'd0, cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}),
        .IN6({16'd0, cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}),
        .IN7({16'd0, cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), 
        .IN8({16'd0, cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9]}), 
        .IN9({16'd0, cache_bytes[13], cache_bytes[12], cache_bytes[11], cache_bytes[10]}), 
        .IN10({16'd0, cache_bytes[14], cache_bytes[13], cache_bytes[12], cache_bytes[11]}), 
        .IN11(48'd0),
        .IN12(48'd0),
        .IN13(48'd0),
        .IN14(48'd0),
        .IN15(48'd0),
        .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]), .S3(total_offset[3])
    );
 
    mux16_48 imm_byte_mux16(
        .Y(imm_bytes16), 
        .IN0({32'd0, cache_bytes[2], cache_bytes[1]}), 
        .IN1({32'd0, cache_bytes[3], cache_bytes[2]}), 
        .IN2({32'd0, cache_bytes[4], cache_bytes[3]}), 
        .IN3({32'd0, cache_bytes[5], cache_bytes[4]}), 
        .IN4({32'd0, cache_bytes[6], cache_bytes[5]}), 
        .IN5({32'd0, cache_bytes[7], cache_bytes[6]}),
        .IN6({32'd0, cache_bytes[8], cache_bytes[7]}),
        .IN7({32'd0, cache_bytes[9], cache_bytes[8]}), 
        .IN8({32'd0, cache_bytes[10], cache_bytes[9]}), 
        .IN9({32'd0, cache_bytes[11], cache_bytes[10]}), 
        .IN10({32'd0, cache_bytes[12], cache_bytes[11]}), 
        .IN11(48'd0),
        .IN12(48'd0),
        .IN13(48'd0),
        .IN14(48'd0),
        .IN15(48'd0),
        .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]), .S3(total_offset[3])
    );

    mux16_48 imm_byte_mux8(
        .Y(imm_bytes8), 
        .IN0({40'd0, cache_bytes[1]}), 
        .IN1({40'd0, cache_bytes[2]}), 
        .IN2({40'd0, cache_bytes[3]}), 
        .IN3({40'd0, cache_bytes[4]}), 
        .IN4({40'd0, cache_bytes[5]}), 
        .IN5({40'd0, cache_bytes[6]}),
        .IN6({40'd0, cache_bytes[7]}),
        .IN7({40'd0, cache_bytes[8]}), 
        .IN8({40'd0, cache_bytes[9]}), 
        .IN9({40'd0, cache_bytes[10]}), 
        .IN10({40'd0, cache_bytes[11]}), 
        .IN11(48'd0),
        .IN12(48'd0),
        .IN13(48'd0),
        .IN14(48'd0),
        .IN15(48'd0),
        .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]), .S3(total_offset[3])
    );

    //Layer 2: 0.22ns through data delay
    mux4_48 imm_size_mux(
        .IN0(imm_bytes8),
        .IN1(imm_bytes16),
        .IN2(imm_bytes32),
        .IN3(imm_bytes48),
        .S0(imm_size[0]),
        .S1(imm_size[1]),
        .Y(imm_bytes)
    );

endmodule