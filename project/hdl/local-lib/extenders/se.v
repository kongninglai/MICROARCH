module se #(
  parameter   INP_WIDTH = 8,
  parameter   OUT_WIDTH = 32
) (
  input       [INP_WIDTH-1:0]   in,
  output      [OUT_WIDTH-1:0]   out
);
  assign out  = {
                  {(OUT_WIDTH-INP_WIDTH){in[INP_WIDTH-1]}},
                  in[INP_WIDTH-1:0]
                };
endmodule