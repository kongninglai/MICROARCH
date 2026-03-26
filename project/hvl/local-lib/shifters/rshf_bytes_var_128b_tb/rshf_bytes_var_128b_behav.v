module rshf_bytes_var_128b_behav #(
  parameter WIDTH = 128,
  parameter CHUNK_WIDTH = 8
) (
  input  [127:0] in,
  input  [3:0]  shf_amt,
  output [127:0] out
);

wire [6:0] shift;
assign shift = shf_amt << 3;

assign out = (in >> shift);

endmodule