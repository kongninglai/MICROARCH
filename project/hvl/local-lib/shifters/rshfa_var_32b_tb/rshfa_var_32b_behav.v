module rshfa_var_32b_behav (
  input  [31:0] in,
  input  [4:0]  shf_amt,
  output [31:0] out
);

  assign out = $signed(in) >>> shf_amt;
  
endmodule
