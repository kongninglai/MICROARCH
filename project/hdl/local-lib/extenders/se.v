module se #(
  parameter   INP_WIDTH = 8,
  parameter   OUT_WIDTH = 32
) (
  input       [INP_WIDTH-1:0]   in,
  output      [OUT_WIDTH-1:0]   out
);

generate
  if (OUT_WIDTH - INP_WIDTH >= 3 && OUT_WIDTH - INP_WIDTH <= 15) begin : se_buf16_gen
    wire [INP_WIDTH-1:0] in_buf16;
    bufferH16$  bufferH16$_in_buf16[INP_WIDTH-1:0](in_buf16, in);
    assign out  = {
                    {(OUT_WIDTH-INP_WIDTH){in_buf16[INP_WIDTH-1]}},
                    in_buf16[INP_WIDTH-1:0]
                  }; 
  end else if (OUT_WIDTH - INP_WIDTH >= 16) begin : se_buf64_gen
    wire [INP_WIDTH-1:0] in_buf64;
    bufferH64$  bufferH64$_in_buf64[INP_WIDTH-1:0](in_buf64, in);
    assign out  = {
                    {(OUT_WIDTH-INP_WIDTH){in_buf64[INP_WIDTH-1]}},
                    in_buf64[INP_WIDTH-1:0]
                  }; 
  end else begin : se_no_buf_gen
    assign out  = {
                    {(OUT_WIDTH-INP_WIDTH){in[INP_WIDTH-1]}},
                    in[INP_WIDTH-1:0]
                  };
  end
endgenerate

endmodule