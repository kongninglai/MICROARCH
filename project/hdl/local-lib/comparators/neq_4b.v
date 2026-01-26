module neq_4b (
  input   [3:0] in0, in1,
  output        neq
);
	
	wire		[3:0]	xor_out;
	
	// xor2$(out, in0, in1);
	xor2$	xor2$_0[3:0](xor_out, in0, in1);
	
	/* Product Expressions */
	wire or_0_0_out;
	
	or4$ or_0_0(or_0_0_out,xor_out[3],xor_out[2],xor_out[1],xor_out[0]);
  //
	/* Sum Expressions */
  assign neq = or_0_0_out;

endmodule