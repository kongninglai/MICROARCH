module seg_limit_cmp (
  input		[31:0]	in,
  input   [31:0]  seg_limit,
	output	 [0:0]	exception
);	

wire gt;

cmp_gen_32b cmp_gen_32b_gt (
  .in0(in), .in1(seg_limit),
	.lt(), .gt(exception), .eq()
);


endmodule