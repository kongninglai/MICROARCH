module lshf_chunks #(
  parameter   CHUNK_WIDTH = 16,
  parameter   WIDTH       = 256,
  parameter   SHF_AMT     = 8,
  parameter   SHF_ZEROS   = 0
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
generate
  if (SHF_ZEROS) begin : zero_shift_gen
    assign out[CHUNK_WIDTH*SHF_AMT-1:0]     = {CHUNK_WIDTH*SHF_AMT{1'b0}};
  end else begin : ones_shift_gen
    assign out[CHUNK_WIDTH*SHF_AMT-1:0]     = {CHUNK_WIDTH*SHF_AMT{1'b1}};
  end
endgenerate
  assign out[WIDTH-1:CHUNK_WIDTH*SHF_AMT] = in[WIDTH-1-(CHUNK_WIDTH*SHF_AMT):0];
	
endmodule