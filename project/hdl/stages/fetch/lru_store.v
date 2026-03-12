module lru_store #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter RANK_BURST_SIZE=4,
  parameter MEM_ADDR_WIDTH=15,
  parameter TRUE_LRU=0
) (
  input                                             rst,
                                                    clk,
  input     [WAY_WIDTH-1:0]                         TAG_HIT_WAY,
  input                                             CACHE_HIT,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT,
  input                                             CC_STREAM_BUF_HIT,

  output    [WAY_WIDTH-1:0]                         VICT_WAY
);

genvar i;
generate

  wire  [NUM_SETS-1:0]  VICT_WAYS_BIT1, VICT_WAYS_BIT0, touch_valid_gates, touch_valids;


  wire      CACHE_HIT_buf16;
  bufferH16$    bufferH16$_CACHE_HIT_buf16(CACHE_HIT_buf16, CACHE_HIT);

  wire      [WAY_WIDTH-1:0] TAG_HIT_WAY_buf16;
  bufferH16$    bufferH16$_TAG_HIT_WAY_buf16[WAY_WIDTH-1:0](TAG_HIT_WAY_buf16, TAG_HIT_WAY);

  wire      [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CC_ADDR_OUT_buf16;
  bufferH16$    bufferH16$_CC_ADDR_OUT_buf16[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](CC_ADDR_OUT_buf16, CC_ADDR_OUT);

  for (i = 0; i < NUM_SETS; i = i + 1) begin : LRU_STORE_TOUCH_VALIDS_GEN

    big_eq #(
      .WIDTH(INDEX_WIDTH)
    ) big_eq_touch_valid_gates (
      .in0(CC_ADDR_OUT_buf16[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]), .in1(i[2:0]),
      .eq(touch_valid_gates[i])
    );

    wire                      HIT_CONDITION, HIT_CONDITION_buf16;
    wire    [WAY_WIDTH-1:0]   TOUCHED_WAY, TOUCHED_WAY_buf16;

    if (TRUE_LRU == 0) begin
      assign HIT_CONDITION = CACHE_HIT_buf16;
      assign TOUCHED_WAY = TAG_HIT_WAY_buf16;
    end else begin
      or2$    or2$_HIT_CONDITION(HIT_CONDITION, CACHE_HIT_buf16, CC_STREAM_BUF_HIT);
      mux2$   mux2$_TOUCHED_WAY[WAY_WIDTH-1:0](TOUCHED_WAY, VICT_WAY, TAG_HIT_WAY_buf16, CACHE_HIT_buf16);
    end

    bufferH16$    bufferH16$_HIT_CONDITION_buf16(HIT_CONDITION_buf16, HIT_CONDITION);
    bufferH16$    bufferH16$_TOUCHED_WAY_buf16[WAY_WIDTH-1:0](TOUCHED_WAY_buf16, TOUCHED_WAY);

    and2$   and2$_touch_valids(touch_valids[i], touch_valid_gates[i], HIT_CONDITION);

    lru_store_per_set lru_store_per_set_VICT_WAYS
    (
      .rst(rst),
      .clk(clk),
      .T1(TOUCHED_WAY[WAY_WIDTH-1]), 
      .T0(TOUCHED_WAY[0]), 
      .valid(touch_valids[i]),
      .V1(VICT_WAYS_BIT1[i]), 
      .V0(VICT_WAYS_BIT0[i])
    );
  end

  mux8    mux8[WAY_WIDTH-1:0]( VICT_WAY,
                              {VICT_WAYS_BIT1[0], VICT_WAYS_BIT0[0]},
                              {VICT_WAYS_BIT1[1], VICT_WAYS_BIT0[1]},
                              {VICT_WAYS_BIT1[2], VICT_WAYS_BIT0[2]},
                              {VICT_WAYS_BIT1[3], VICT_WAYS_BIT0[3]},
                              {VICT_WAYS_BIT1[4], VICT_WAYS_BIT0[4]},
                              {VICT_WAYS_BIT1[5], VICT_WAYS_BIT0[5]},
                              {VICT_WAYS_BIT1[6], VICT_WAYS_BIT0[6]},
                              {VICT_WAYS_BIT1[7], VICT_WAYS_BIT0[7]},
                              CC_ADDR_OUT_buf16[RANK_BURST_SIZE],
                              CC_ADDR_OUT_buf16[RANK_BURST_SIZE+1],
                              CC_ADDR_OUT_buf16[RANK_BURST_SIZE+2]);
endgenerate

endmodule