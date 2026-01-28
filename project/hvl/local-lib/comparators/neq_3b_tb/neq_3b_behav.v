module neq_3b_behav (
  input   [2:0]  in0, in1,
  output         neq
);

assign neq = (in0 != in1);

endmodule