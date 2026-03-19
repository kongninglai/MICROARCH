module tag_store_behav #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter TAG_WIDTH=8
) (
  input   [INDEX_WIDTH-1:0]         set_index,
  input   [NUM_WAYS-1:0]            wr_en_bar_one_hot,
  input   [TAG_WIDTH-1:0]           tag_in,

  output  [NUM_WAYS*TAG_WIDTH-1:0]  tag_out
);

reg [TAG_WIDTH-1:0] mem [0:NUM_WAYS-1][0:NUM_SETS-1];

integer i;
always @(*) begin
  for (i = 0; i < NUM_WAYS; i = i + 1) begin
    if (!wr_en_bar_one_hot[i])
      mem[i][set_index] = tag_in;
  end
end

genvar j;
generate
  for (j = 0; j < NUM_WAYS; j = j + 1) begin : tag_out_assign
    assign tag_out[j*TAG_WIDTH +: TAG_WIDTH] = mem[j][set_index];
  end
endgenerate

endmodule