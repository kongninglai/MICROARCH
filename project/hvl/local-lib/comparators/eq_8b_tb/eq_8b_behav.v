module eq_8b_behav (
  input   [7:0]  in0, in1,
  output          eq
);

assign eq = (in0 == in1);

endmodule