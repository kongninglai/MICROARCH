// Designed to duplicate each bit of a 16b wire to produce 64b
module bit_duplicator #(
  parameter MULTIPLIER=4,
  parameter IN_WIDTH=16,
  parameter OUT_WIDTH=IN_WIDTH*MULTIPLIER
) (
  input   [IN_WIDTH-1:0]    in,
  output  [OUT_WIDTH-1:0]   out
);

wire  [IN_WIDTH-1:0]  in_buf16;

genvar i;
generate
  if (MULTIPLIER > 4) begin : INPUT_BUF_GEN
    bufferH16$  bufferH16$_in_buf16[IN_WIDTH-1:0](in_buf16, in);
  end else begin : INPUT_NO_BUF_GEN
    assign in_buf16 = in;
  end

  for (i = 0; i < IN_WIDTH; i = i + 1) begin : DUPLICATION_GEN
    assign out[i*MULTIPLIER +: MULTIPLIER] = {MULTIPLIER{in_buf16[i]}};
  end
endgenerate

endmodule