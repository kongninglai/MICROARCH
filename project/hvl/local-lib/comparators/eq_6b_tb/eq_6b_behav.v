module eq_6b_behav (
  input   [5:0]  in0, in1,
  output          eq
);

assign eq = (in0 == in1);

endmodule