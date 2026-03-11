module tag_hit_logic_behav #(
  parameter NUM_SETS     = 8,
  parameter INDEX_WIDTH  = $clog2(NUM_SETS),
  parameter NUM_WAYS     = 4,
  parameter WAY_WIDTH    = $clog2(NUM_WAYS),
  parameter TAG_WIDTH    = 8
) (
  input  [NUM_WAYS*TAG_WIDTH-1:0] tag_store_out,
  input  [TAG_WIDTH-1:0]          tag_compare_val,
  input  [NUM_WAYS-1:0]           cache_valid_out,

  output reg [NUM_WAYS-1:0]       tag_hit,
  output reg [WAY_WIDTH-1:0]      tag_hit_way
);

integer i;

always @(*) begin
  tag_hit_way = 0;
  tag_hit = 0;

  for (i = 0; i < NUM_WAYS; i = i + 1) begin
    if (tag_compare_val == tag_store_out[i*TAG_WIDTH +: TAG_WIDTH])
      tag_hit[i] = 1'b1;
    else
      tag_hit[i] = 1'b0;
  end

  for (i = 0; i < NUM_WAYS; i = i + 1) begin
    if (tag_hit[i] & cache_valid_out[i]) begin
      tag_hit_way = i[WAY_WIDTH-1:0];
    end
  end
end

endmodule