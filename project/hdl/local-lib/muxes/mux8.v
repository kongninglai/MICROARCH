module mux8 (
  input           in0,in1,in2,in3,in4,in5,in6,in7,s0,s1,s2,
  output          outb
);

wire    mux2$_0_out, mux2$_1_out, mux2$_2_out, mux2$_3_out;

mux4$   mux4$_0(mux4$_0_out, in0, in1, in2, in3, s0, s1);
mux4$   mux4$_1(mux4$_1_out, in4, in5, in6, in7, s0, s1);
mux2$   mux2$_0(outb, mux4$_0_out, mux4$_1_out, s2);

endmodule