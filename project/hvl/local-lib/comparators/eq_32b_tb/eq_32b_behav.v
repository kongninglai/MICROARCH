module eq_32b_behav (
  input   [31:0]  in0, in1,
  output          eq
);

assign eq = (in0 == in1);

endmodule