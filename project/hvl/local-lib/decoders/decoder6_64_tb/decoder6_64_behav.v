module decoder6_64_behav  (
  input    [5:0]  SEL,
  output  [63:0]  Y,YBAR
);

assign YBAR = ~Y;
assign Y = 16'd1 << SEL;

endmodule