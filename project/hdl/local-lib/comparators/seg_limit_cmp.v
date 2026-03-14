module seg_limit_cmp (
  input		[31:0]	in,
  input   [19:0]  seg_limit,
	output	 [0:0]	exception
);	

wire gt;

cmp_gen_20b cmp_gen_20b_gt (
  .in0(in[19:0]), .in1(seg_limit),
	.lt(), .gt(gt), .eq()
);

wire top_bits_exception;

big_or #(
  .WIDTH(12)
) big_or_top_bits_exception (
  .out(top_bits_exception),
  .in(in[31:20])
);

or2$    or2$_exception(exception, top_bits_exception, gt);

endmodule