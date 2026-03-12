module seg_limit_cmp_behav (
  input  [31:0] in,
  input  [19:0] seg_limit,
  output        exception
);

assign exception = (|in[31:20]) || (in[19:0] > seg_limit);

endmodule