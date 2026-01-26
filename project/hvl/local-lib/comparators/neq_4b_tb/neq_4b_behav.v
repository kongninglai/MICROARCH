module neq_4b_behav (
  input   [3:0]  in0, in1,
  output         neq
);

assign neq = (in0 != in1);

endmodule