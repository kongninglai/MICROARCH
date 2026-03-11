module tag_hit_logic #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8
) (
  input   [NUM_WAYS*TAG_WIDTH-1:0]  tag_store_out,
  input   [TAG_WIDTH-1:0]           tag_compare_val,
  input   [NUM_WAYS-1:0]            cache_valid_out,

  output  [NUM_WAYS-1:0]            tag_hit,
  output  [WAY_WIDTH-1:0]           tag_hit_way
);

genvar i;
generate
  for (i = 0; i < NUM_WAYS; i = i + 1) begin : TAG_CMP_GEN
    big_eq #(
      .WIDTH(TAG_WIDTH)
    ) big_eq_tag_hit (
      .in0(tag_compare_val), .in1(tag_store_out[i*TAG_WIDTH +: TAG_WIDTH]),
      .eq(tag_hit[i])
    );
  end
endgenerate

wire  [NUM_WAYS-1:0]  tag_hit_gated;

and2$   and2$_tag_hit_gated[NUM_WAYS-1:0](tag_hit_gated, tag_hit, cache_valid_out);

encoder4_2  encoder4_2_tag_hit_and_tag_hit_way(.in(tag_hit_gated),.out(tag_hit_way),.valid());

endmodule