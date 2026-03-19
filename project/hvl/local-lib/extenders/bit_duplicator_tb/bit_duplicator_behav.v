module bit_duplicator_behav #(
  parameter MULTIPLIER=4,
  parameter IN_WIDTH=16,
  parameter OUT_WIDTH=IN_WIDTH*MULTIPLIER
) (
  input   [IN_WIDTH-1:0]    in,
  output reg [OUT_WIDTH-1:0] out
);

integer i;

always @(*) begin
  for (i = 0; i < IN_WIDTH; i = i + 1) begin
    out[i*MULTIPLIER +: MULTIPLIER] = {MULTIPLIER{in[i]}};
  end
end

endmodule