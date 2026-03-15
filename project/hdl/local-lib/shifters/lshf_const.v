module lshf_const #(
  parameter   WIDTH     = 32,
  parameter   SHF_AMT   = 16,
  parameter   SHF_ONES  = 0
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);

generate
  if (SHF_ONES) begin : SHIFT_ONES_GEN
    assign out[SHF_AMT-1:0]     = {SHF_AMT{1'b1}};
  end else begin : SHIFT_ZEROS_GEN
    assign out[SHF_AMT-1:0]     = {SHF_AMT{1'b0}};
  end
endgenerate
  assign out[WIDTH-1:SHF_AMT] = in[WIDTH-1-SHF_AMT:0];
	
endmodule