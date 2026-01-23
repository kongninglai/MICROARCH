module eq_3b_behav (
  input   [2:0]  in0, in1,
  output          eq
);

assign eq = (in0 == in1);

endmodule