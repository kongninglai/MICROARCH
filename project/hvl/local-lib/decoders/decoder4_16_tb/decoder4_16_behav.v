module decoder4_16_behav  (
  input    [3:0]  SEL,
  output  [15:0]  Y,YBAR
);

assign YBAR = ~Y;
assign Y = 16'd1 << SEL;

endmodule