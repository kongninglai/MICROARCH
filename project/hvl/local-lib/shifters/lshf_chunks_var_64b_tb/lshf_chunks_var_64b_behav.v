module lshf_chunks_var_64b_behav #(
  parameter WIDTH = 64,
  parameter CHUNK_WIDTH = 4
) (
  input  [WIDTH-1:0] in,
  input  [1:0]  shf_amt,
  output [WIDTH-1:0] out
);

wire [5:0] shift;
assign shift = shf_amt << 4;

assign out = (in << shift) | (~({64{1'b1}} << shift));

endmodule