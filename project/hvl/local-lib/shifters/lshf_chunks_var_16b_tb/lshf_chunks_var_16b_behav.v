module lshf_chunks_var_16b_behav #(
  parameter WIDTH = 16,
  parameter CHUNK_WIDTH = 4
) (
  input  [WIDTH-1:0] in,
  input  [1:0]  shf_amt,
  output [WIDTH-1:0] out
);

wire [4:0] shift;
assign shift = shf_amt << 2;

assign out = (in << shift) | (~({16{1'b1}} << shift));

endmodule