module cmp_gen_32b_behav (
  input		[31:0]	in0, in1,
	output	 [0:0]	lt, gt, eq
);	
	
assign lt = (in0 < in1);
assign gt = (in0 > in1);
assign eq = (in0 == in1);
	
endmodule