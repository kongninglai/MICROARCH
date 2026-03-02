module lshf_chunks #(
  parameter   CHUNK_WIDTH = 16,
  parameter   WIDTH       = 256,
  parameter   SHF_AMT     = 8
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
  
  assign out[CHUNK_WIDTH*SHF_AMT-1:0]     = {CHUNK_WIDTH*SHF_AMT{1'b1}};
  assign out[WIDTH-1:CHUNK_WIDTH*SHF_AMT] = in[WIDTH-1-(CHUNK_WIDTH*SHF_AMT):0];
	
endmodule