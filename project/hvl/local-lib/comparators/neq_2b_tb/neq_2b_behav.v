module neq_2b_behav (
  input   [1:0]  in0, in1,
  output         neq
);

assign neq = (in0 != in1);

endmodule