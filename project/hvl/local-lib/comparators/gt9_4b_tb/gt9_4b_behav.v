module gt9_4b_behav (
  input   [3:0] in,
  output        gt
);

assign gt = (in > 9);

endmodule