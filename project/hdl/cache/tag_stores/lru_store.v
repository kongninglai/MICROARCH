module lru_store #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter RANK_BURST_SIZE=4,
  parameter MEM_ADDR_WIDTH=15,
  parameter TRUE_LRU=1
) (
  input                                             rst,
                                                    clk,
  input     [WAY_WIDTH-1:0]                         TAG_HIT_WAY,
  input                                             CACHE_HIT,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT,
  input                                             CC_STREAM_BUF_HIT,

  output    [WAY_WIDTH-1:0]                         VICT_WAY
);

wire  [15:2] VICT_WAY_DUMMY;

wire CACHE_MISS_buf64;
bufferHInv64$   bufferHInv64$_CACHE_MISS_buf64(CACHE_MISS_buf64, CACHE_HIT);

genvar i;
generate

  wire  [NUM_SETS-1:0]  VICT_WAYS_BIT1, VICT_WAYS_BIT0, touch_valid_gates, touch_valids;

  wire      [WAY_WIDTH-1:0] TAG_HIT_WAY_buf16;
  bufferH16$    bufferH16$_TAG_HIT_WAY_buf16[WAY_WIDTH-1:0](TAG_HIT_WAY_buf16, TAG_HIT_WAY);

  wire      [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CC_ADDR_OUT_buf16;
  bufferH16$    bufferH16$_CC_ADDR_OUT_buf16[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](CC_ADDR_OUT_buf16, CC_ADDR_OUT);

  wire      [INDEX_WIDTH-1:0] xor_outs [0:NUM_SETS-1];

  

  wire                      SB_HIT_CONDITION, HIT_CONDITION, HIT_CONDITION_buf16;
  wire    [WAY_WIDTH-1:0]   TOUCHED_WAY, TOUCHED_WAY_buf64;

  if (TRUE_LRU == 0) begin : PSEUDO_LRU_GEN
    assign HIT_CONDITION = CACHE_HIT;
    assign TOUCHED_WAY = TAG_HIT_WAY_buf16;
  end else begin : TRUE_LRU_GEN
    nand2$          nand2$_SB_HIT_CONDITION(SB_HIT_CONDITION, CC_STREAM_BUF_HIT, CACHE_MISS_buf64);
    nand2$          nand2$_HIT_CONDITION(HIT_CONDITION, CACHE_MISS_buf64, SB_HIT_CONDITION);
    mux2$           mux2$_TOUCHED_WAY[WAY_WIDTH-1:0](TOUCHED_WAY, TAG_HIT_WAY_buf16, VICT_WAY, CACHE_MISS_buf64);
  end

  bufferH64$    bufferH64$_TOUCHED_WAY_buf64[WAY_WIDTH-1:0](TOUCHED_WAY_buf64, TOUCHED_WAY);
  bufferH16$    bufferH16$_HIT_CONDITION_buf16(HIT_CONDITION_buf16, HIT_CONDITION);

  for (i = 0; i < NUM_SETS; i = i + 1) begin : LRU_STORE_TOUCH_VALIDS_GEN
    // This is just an optimized set index compare...
    xor2$   xor2$_xor_outs[INDEX_WIDTH-1:0](xor_outs[i], CC_ADDR_OUT_buf16[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], i[2:0]);
    nor3$   nor3$_nor_outs(touch_valid_gates[i], xor_outs[i][2], xor_outs[i][1], xor_outs[i][0]);

    and2$   and2$_touch_valids(touch_valids[i], touch_valid_gates[i], HIT_CONDITION_buf16);

    lru_store_per_set lru_store_per_set_VICT_WAYS
    (
      .rst(rst),
      .clk(clk),
      .T1(TOUCHED_WAY_buf64[WAY_WIDTH-1]), 
      .T0(TOUCHED_WAY_buf64[0]), 
      .valid(touch_valids[i]),
      .V1(VICT_WAYS_BIT1[i]), 
      .V0(VICT_WAYS_BIT0[i])
    );
  end
  
  mux8_16b mux8_16b_VICT_WAY 
  ( 
    {VICT_WAY_DUMMY, VICT_WAY},
    {14'd0, VICT_WAYS_BIT1[0], VICT_WAYS_BIT0[0]},
    {14'd0, VICT_WAYS_BIT1[1], VICT_WAYS_BIT0[1]},
    {14'd0, VICT_WAYS_BIT1[2], VICT_WAYS_BIT0[2]},
    {14'd0, VICT_WAYS_BIT1[3], VICT_WAYS_BIT0[3]},
    {14'd0, VICT_WAYS_BIT1[4], VICT_WAYS_BIT0[4]},
    {14'd0, VICT_WAYS_BIT1[5], VICT_WAYS_BIT0[5]},
    {14'd0, VICT_WAYS_BIT1[6], VICT_WAYS_BIT0[6]},
    {14'd0, VICT_WAYS_BIT1[7], VICT_WAYS_BIT0[7]},
    CC_ADDR_OUT_buf16[RANK_BURST_SIZE],
    CC_ADDR_OUT_buf16[RANK_BURST_SIZE+1],
    CC_ADDR_OUT_buf16[RANK_BURST_SIZE+2]
  );
endgenerate

endmodule