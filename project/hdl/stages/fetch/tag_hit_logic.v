module tag_hit_logic #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8
) (
  input   [NUM_WAYS*TAG_WIDTH-1:0]  tag_store_out,
  input   [TAG_WIDTH-1:0]           tag_compare_val,

  output                            tag_hit,
  output  [WAY_WIDTH-1:0]           tag_hit_way
);

wire  [NUM_WAYS-1:0]  tag_hit_way_sel_one_hot;

genvar i;
generate
  for (i = 0; i < NUM_WAYS; i = i + 1) begin : TAG_CMP_GEN
    big_eq #(
      .WIDTH(TAG_WIDTH)
    ) big_eq_tag_hit_way_sel_one_hot (
      .in0(tag_compare_val), .in1(tag_store_out[i*TAG_WIDTH +: TAG_WIDTH]),
      .eq(tag_hit_way_sel_one_hot[i])
    );
  end
endgenerate

big_or #(
  .WIDTH(NUM_WAYS)
) big_or_tag_hit (
  .out(tag_hit),
  .in(tag_hit_way_sel_one_hot)
);

encoder4_2  encoder4_2_tag_hit_and_tag_hit_way(.in(tag_hit_way_sel_one_hot),.out(tag_hit_way),.valid(tag_hit));

endmodule