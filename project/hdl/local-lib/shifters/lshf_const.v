module lshf_const #(
  parameter   WIDTH     = 32,
  parameter   SHF_AMT   = 16
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
  
  assign out[SHF_AMT-1:0]     = {SHF_AMT{1'b0}};
  assign out[WIDTH-1:SHF_AMT] = in[WIDTH-1-SHF_AMT:0];
	
endmodule