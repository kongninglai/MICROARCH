module lshf_const_behav #(
  parameter   WIDTH     = 32,
  parameter   SHF_AMT   = 16
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
  
  assign out = in << SHF_AMT;
	
endmodule