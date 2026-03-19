module data_store_behav #(
  parameter RANK_BIT_WIDTH   = 128,
  parameter BUS_BIT_WIDTH    = 32,
  parameter CHIP_BIT_WIDTH   = 8,
  parameter RANK_BURST_SIZE  = 4,
  parameter BYTES_PER_BUS    = 4,
  parameter NUM_SETS         = 8,
  parameter INDEX_WIDTH      = $clog2(NUM_SETS),
  parameter NUM_WAYS         = 4
) (
  input   [INDEX_WIDTH-1:0]                             set_index,
  input   [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  wr_en_bar_one_hot,
  input   [RANK_BIT_WIDTH-1:0]                          data_in,
  output  [NUM_WAYS*RANK_BIT_WIDTH-1:0]                 data_out
);

localparam NUM_BYTES_PER_RANK = RANK_BURST_SIZE * BYTES_PER_BUS;

reg [CHIP_BIT_WIDTH-1:0] mem [0:NUM_WAYS-1][0:NUM_SETS-1][0:NUM_BYTES_PER_RANK-1];

integer i, j;

always @(*) begin
  for (i = 0; i < NUM_WAYS; i = i + 1) begin
    for (j = 0; j < NUM_BYTES_PER_RANK; j = j + 1) begin
      if (!wr_en_bar_one_hot[i*NUM_BYTES_PER_RANK + j])
        mem[i][set_index][j] = data_in[j*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH];
    end
  end
end

genvar w, b;
generate
  for (w = 0; w < NUM_WAYS; w = w + 1) begin : data_out_assign
    wire [RANK_BIT_WIDTH-1:0] concat_bytes;
    assign concat_bytes = { mem[w][set_index][NUM_BYTES_PER_RANK-1],
                            mem[w][set_index][NUM_BYTES_PER_RANK-2],
                            mem[w][set_index][NUM_BYTES_PER_RANK-3],
                            mem[w][set_index][NUM_BYTES_PER_RANK-4],
                            mem[w][set_index][NUM_BYTES_PER_RANK-5],
                            mem[w][set_index][NUM_BYTES_PER_RANK-6],
                            mem[w][set_index][NUM_BYTES_PER_RANK-7],
                            mem[w][set_index][NUM_BYTES_PER_RANK-8],
                            mem[w][set_index][NUM_BYTES_PER_RANK-9],
                            mem[w][set_index][NUM_BYTES_PER_RANK-10],
                            mem[w][set_index][NUM_BYTES_PER_RANK-11],
                            mem[w][set_index][NUM_BYTES_PER_RANK-12],
                            mem[w][set_index][NUM_BYTES_PER_RANK-13],
                            mem[w][set_index][NUM_BYTES_PER_RANK-14],
                            mem[w][set_index][NUM_BYTES_PER_RANK-15],
                            mem[w][set_index][0]};
    assign data_out[w*RANK_BIT_WIDTH +: RANK_BIT_WIDTH] = concat_bytes;
  end
endgenerate

endmodule