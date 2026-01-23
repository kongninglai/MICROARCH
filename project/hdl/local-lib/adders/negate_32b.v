module negate_32b #(
  parameter   WIDTH = 32
) (
  input   [WIDTH-1:0]  in,
  output  [WIDTH-1:0]  out
);

	wire 		[WIDTH-1:0]	in_bar;
	inv1$ inv1_0[WIDTH-1:0](in_bar, in);
	
	PA_32b  PA_32b_out(.in0(in_bar), .in1({{WIDTH-1{1'b0}},1'b1}), .s(out));
	
endmodule