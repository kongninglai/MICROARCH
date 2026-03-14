/*
Delay: 0.6ns
*/

module xor3LL(
  output  out,
  input   in0, in1, in2
);
	wire    xor2$_0_out;
	xor2$   xor2$_0(xor2$_0_out, in1, in2);
	xor2$   xor2$_1(out, xor2$_0_out, in0);
endmodule