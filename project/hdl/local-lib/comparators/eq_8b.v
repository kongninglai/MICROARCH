module eq_8b (
  input   [7:0] in0, in1,
  output        eq
);
	
	wire		[7:0]	xnor_out;
	
	// xnor2$(out, in0, in1);
	xnor2$	xnor2$_0[7:0](xnor_out, in0, in1);
	
	/* Product Expressions */
	wire and_0_0_out;
	wire and_0_1_out;
	wire and_0_2_out;
	
	and2$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out);
	and4$ and_0_1(and_0_1_out,xnor_out[7],xnor_out[6],xnor_out[5],xnor_out[4]);
	and4$ and_0_2(and_0_2_out,xnor_out[3],xnor_out[2],xnor_out[1],xnor_out[0]);

	/* Sum Expressions */
  assign eq = and_0_0_out;

endmodule