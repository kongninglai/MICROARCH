module neq_2b_a (
  input   [1:0] in0, in1,
  input         valid,
  output        neq
);

  wire    [1:0] in1_INV, in1_valid;

  inv1$         inv1$_in1_not[1:0](in1_INV, in0);
  mux2$         mux2$_in1_valid[1:0](in1_valid, in1_INV, in1, valid);
	
	wire		[1:0]	xor_out;
	
	// xor2$(out, in0, in1);
	xor2$	xor2$_0[1:0](xor_out, in0, in1_valid);
	
	/* Product Expressions */
	wire or_0_0_out;
	
	or2$ or_0_0(or_0_0_out,xor_out[1],xor_out[0]);

	/* Sum Expressions */
  assign neq = or_0_0_out;

endmodule