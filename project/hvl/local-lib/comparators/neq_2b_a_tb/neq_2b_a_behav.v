module neq_2b_a_behav (
  input   [1:0]  in0, in1,
  input          valid,
  output         neq
);

assign neq = valid ? (in0 != in1) : 1'b1;

endmodule