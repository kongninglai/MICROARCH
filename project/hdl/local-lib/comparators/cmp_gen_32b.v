module cmp_gen_32b(
  input		[31:0]	in0, in1,
	output	 [0:0]	lt, gt, eq
);	
	
	wire 		[31:0]	neg_in1, difference, xnor_out, cout;
	
	wire					  gt_long, lt_long, gt_short, lt_short;
	
	negate_32b negate_32b_0(.in({1'b0, in1[30:0]}), .out(neg_in1));
	
	HA_32b HA_32b_0(.in0({1'b0, in0[30:0]}), .in1(neg_in1), .s(difference), .cout(cout));
	
  assign lt_long = difference[31];
	
	eq_32b		eq_32b_0(.in0(in0), .in1(in1), .eq(eq));
	
	// nor2$(out, in0, in1);
	nor2$	nor2$_0(gt_long, lt_long, eq);
	
	wire	diff_msb;
	
	xor2$ xor2$_0(diff_msb, in0[31], in1[31]);
	
	and2$ and2$_0(lt_short, diff_msb, in1[31]);
	nor2$	nor2$_1(gt_short, lt_short, eq);
	
	mux2$	mux2$_0(lt, lt_long, lt_short, diff_msb);
	mux2$	mux2$_1(gt, gt_long, gt_short, diff_msb);
	
endmodule