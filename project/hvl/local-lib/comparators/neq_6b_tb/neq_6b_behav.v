module neq_6b_behav (
  input   [5:0]  in0, in1,
  output         neq
);

assign neq = (in0 != in1);

endmodule