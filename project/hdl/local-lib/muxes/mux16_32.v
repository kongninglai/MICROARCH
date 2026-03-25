module mux16_32 (
  output  [31:0] out,
  input   [31:0] in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
  input               s0,s1,s2,s3
);

wire buffered_s0, buffered_s1, buffered_s2, buffered_s3;

bufferH16$ buffer_s0(buffered_s0, s0);
bufferH16$ buffer_s1(buffered_s1, s1);
bufferH16$ buffer_s2(buffered_s2, s2);
bufferH16$ buffer_s3(buffered_s3, s3);

wire    [15:0] mux4_00_out, mux4_10_out, mux4_20_out, mux4_30_out;
wire    [15:0] mux4_01_out, mux4_11_out, mux4_21_out, mux4_31_out;

mux4_16$   mux4$_00(mux4_00_out, in0[15:0], in1[15:0], in2[15:0], in3[15:0], buffered_s0, buffered_s1);
mux4_16$   mux4$_10(mux4_10_out, in4[15:0], in5[15:0], in6[15:0], in7[15:0], buffered_s0, buffered_s1);
mux4_16$   mux4$_20(mux4_20_out, in8[15:0], in9[15:0], in10[15:0], in11[15:0], buffered_s0, buffered_s1);
mux4_16$   mux4$_30(mux4_30_out, in12[15:0], in13[15:0], in14[15:0], in15[15:0], buffered_s0, buffered_s1);

mux4_16$   mux4$_out0(out[15:0], mux4_00_out, mux4_10_out, mux4_20_out, mux4_30_out, buffered_s2, buffered_s3);

mux4_16$   mux4$_01(mux4_01_out, in0[31:16], in1[31:16], in2[31:16], in3[15:0], buffered_s0, buffered_s1);
mux4_16$   mux4$_11(mux4_11_out, in4[31:16], in5[31:16], in6[31:16], in7[31:16], buffered_s0, buffered_s1);
mux4_16$   mux4$_21(mux4_21_out, in8[31:16], in9[31:16], in10[31:16], in11[31:16], buffered_s0, buffered_s1);
mux4_16$   mux4$_31(mux4_31_out, in12[31:16], in13[31:16], in14[31:16], in15[31:16], buffered_s0, buffered_s1);

mux4_16$   mux4$_out1(out[31:16], mux4_01_out, mux4_11_out, mux4_21_out, mux4_31_out, buffered_s2, buffered_s3);

endmodule