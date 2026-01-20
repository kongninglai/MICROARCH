module xor3LL(
  input   in0, in1, in2,
  output  out
);
	wire    xor2$_0_out;
	xor2$   xor2$_0(xor2$_0_out, in0, in1);
	xor2$   xor2$_1(out, xor2$_0_out, in2);
endmodule