module neq_4b_a_behav (
  input   [3:0]  in0, in1,
  input          valid,
  output         neq
);

assign neq = valid ? (in0 != in1) : 1'b1;

endmodule