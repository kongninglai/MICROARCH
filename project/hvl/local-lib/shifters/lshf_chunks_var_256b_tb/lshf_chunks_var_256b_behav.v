module lshf_chunks_var_256b_behav #(
  parameter WIDTH = 256,
  parameter CHUNK_WIDTH = 16
) (
  input  [255:0] in,
  input  [3:0]  shf_amt,
  output [255:0] out
);

wire [7:0] shift;
assign shift = shf_amt << 4;

assign out = (in << shift) | (~({256{1'b1}} << shift));

endmodule