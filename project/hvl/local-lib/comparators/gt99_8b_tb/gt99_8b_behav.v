module gt99_8b_behav (
  input   [7:0] in,
  output        gt
);

assign gt = (in > 8'h99);

endmodule