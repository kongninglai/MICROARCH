module lshf_chunks_behav #(
  parameter   CHUNK_WIDTH = 16,
  parameter   WIDTH       = 256,
  parameter   SHF_AMT     = 8
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);

  localparam SHIFT = CHUNK_WIDTH * SHF_AMT;

  assign out = (in << SHIFT) | {{WIDTH-SHIFT{1'b0}}, {SHIFT{1'b1}}};

endmodule