module eq_2b_behav (
  input    [1:0]  in0, in1,
  output          eq
);

assign eq = (in0 == in1);

endmodule