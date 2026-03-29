module cmp_gt_32b_behav (
  input		[31:0]	in0, in1,
	output	 [0:0]	gt
);	
	
assign gt = (in0 > in1);
	
endmodule