module eq_1b (
  input         in0, in1,
  output        eq
);
	// xnor2$(out, in0, in1);
	xnor2$	xnor2$_0(eq, in0, in1);

endmodule