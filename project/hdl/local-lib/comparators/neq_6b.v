module neq_6b (
  input   [5:0] in0, in1,
  output        neq
);
	
	wire		[5:0]	xor_out;
	
	// xor2$(out, in0, in1);
	xor2$	xor2$_0[5:0](xor_out, in0, in1);
	
	/* Product Expressions */
	wire or_0_0_out;
	wire or_0_1_out;
	
	or3$ or_0_0(or_0_0_out,or_0_1_out,xor_out[5],xor_out[4]);
	or4$ or_0_1(or_0_1_out,xor_out[3],xor_out[2],xor_out[1],xor_out[0]);

	/* Sum Expressions */
  assign neq = or_0_0_out;

endmodule