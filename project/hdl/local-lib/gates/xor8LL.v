module xor8LL(
  output  out,
  input   in0, in1, in2, in3, in4, in5, in6, in7
);
	wire    xor4_0_out, xor4_1_out;
	xor4LL   xor4_0(xor4_0_out, in0, in1, in2, in3);
    xor4LL   xor4_1(xor4_1_out, in4, in5, in6, in7);
	xor2$   xor2$_2(out, xor4_0_out, xor4_1_out);
endmodule