module lshf_bytes_var_256b_behav #(
  parameter WIDTH = 256,
  parameter CHUNK_WIDTH = 8
) (
  input  [255:0] in,
  input  [4:0]  shf_amt,
  output [255:0] out
);

wire [7:0] shift;
assign shift = shf_amt << 3;

assign out = (in << shift);

endmodule