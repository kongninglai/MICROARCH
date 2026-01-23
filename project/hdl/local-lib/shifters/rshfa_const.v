module rshfa_const #(
  parameter   WIDTH     = 32,
  parameter   SHF_AMT   = 16
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
	
	assign out[WIDTH-1:WIDTH-SHF_AMT] = {SHF_AMT{in[WIDTH-1]}};
	assign out[WIDTH-SHF_AMT-1:0]     = in[WIDTH-1:SHF_AMT];
	
endmodule