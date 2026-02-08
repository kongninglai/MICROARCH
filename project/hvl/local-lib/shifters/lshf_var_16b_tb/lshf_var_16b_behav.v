module lshf_var_16b_behav (
  input  [15:0] in,
  input  [3:0]  shf_amt,
  output [15:0] out
);

  assign out = in << shf_amt;
  
endmodule
