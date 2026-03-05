module lshf_chunks_var_128b_behav #(
  parameter WIDTH = 128,
  parameter CHUNK_WIDTH = 4
) (
  input  [127:0] in,
  input  [4:0]  shf_amt,
  output [127:0] out
);

wire [7:0] shift;
assign shift = shf_amt << 2;

assign out = (in << shift) | (~({128{1'b1}} << shift));

endmodule