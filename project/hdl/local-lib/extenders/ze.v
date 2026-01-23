module ze #(
  parameter   INP_WIDTH = 8,
  parameter   OUT_WIDTH = 32
) (
  input       [INP_WIDTH-1:0]   in,
  output      [OUT_WIDTH-1:0]   out   
);
  assign out  = {
                  {(OUT_WIDTH-INP_WIDTH){1'b0}},
                  in[INP_WIDTH-1:0]
                };
endmodule