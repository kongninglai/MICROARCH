module seg_limit_cmp_bh (
  input		[31:0]	in,
  input   [31:0]  seg_limit,
	output	 [0:0]	exception
);	
	
assign exception = in > seg_limit;
	
endmodule