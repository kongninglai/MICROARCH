module se_behav #(
  parameter   INP_WIDTH = 8,
  parameter   OUT_WIDTH = 32
) (
  input       [INP_WIDTH-1:0]   in,
  output  reg [OUT_WIDTH-1:0]   out
);

  always @(*) begin
    out[INP_WIDTH-1:0] = in[INP_WIDTH-1:0];
    if (in[INP_WIDTH-1] == 1'b0) begin
      out[OUT_WIDTH-1:INP_WIDTH] = {(OUT_WIDTH-INP_WIDTH){1'b0}};
    end else begin
      out[OUT_WIDTH-1:INP_WIDTH] = {(OUT_WIDTH-INP_WIDTH){1'b1}};    
    end
  end
	
endmodule