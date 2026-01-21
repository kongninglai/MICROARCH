module mux16 (
  output          outb,
  input           in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,s0,s1,s2,s3
);

wire    mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out;

mux4$   mux4$_0(mux4$_0_out, in0, in1, in2, in3, s0, s1);
mux4$   mux4$_1(mux4$_1_out, in4, in5, in6, in7, s0, s1);
mux4$   mux4$_2(mux4$_2_out, in8, in9, in10, in11, s0, s1);
mux4$   mux4$_3(mux4$_3_out, in12, in13, in14, in15, s0, s1);
mux4$   mux4$_4(outb, mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out, s2, s3);

endmodule