module decoder5_32_behav  (
  input    [4:0]  SEL,
  output  [31:0]  Y,YBAR
);

assign YBAR = ~Y;
assign Y = 32'd1 << SEL;

endmodule