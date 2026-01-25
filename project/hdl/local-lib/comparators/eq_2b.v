module eq_2b (
  input   [1:0] in0, in1,
  output        eq
);
	
	wire		[1:0]	xnor_out;
	
	// xnor2$(out, in0, in1);
	xnor2$	xnor2$_0[1:0](xnor_out, in0, in1);
	
	and2$ and_0_0(eq,xnor_out[0],xnor_out[1]);

endmodule