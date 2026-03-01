module xor4LL(
  output  out,
  input   in0, in1, in2, in3
);
	wire    xor2_0_out, xor2_1_out;
	xor2$   xor2$_0(xor2_0_out, in0, in1);
  xor2$   xor2$_1(xor2_1_out, in2, in3);
	xor2$   xor2$_2(out, xor2_0_out, xor2_1_out);
endmodule