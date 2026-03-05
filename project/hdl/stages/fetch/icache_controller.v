module icache_controller #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15,
  parameter   NUM_SETS=8,
  parameter   INDEX_WIDTH=$clog2(NUM_SETS),
  parameter   NUM_WAYS=4,
  parameter   WAY_WIDTH=$clog2(NUM_WAYS),
  parameter   TAG_WIDTH=8
) (
  input                                             rst, clk, 

  /*** BUS SIGNALS ***/               
  input     [BUS_BIT_WIDTH-1:0]                     DATA_BUS,
  input                                             IC_MEM_RD_ACK, DATA_VALID_BAR,
  output    [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS,
  output                                            IC_MEM_RD_RQ,

  /*** BETWEEN ICACHE CONTROLLER & ICACHE ***/                
  input                                             ICACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    ICACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         ICACHE_VICT_WAY,

  output                                            ICC_STREAM_BUF_HIT, ICC_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICC_ADDR_OUT,
  output    [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] ICC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [INDEX_WIDTH-1:0]                       ICC_TAG_VALID_SET_INDEX,
  output    [NUM_WAYS-1:0]                          ICC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         ICC_TAG_IN,

  /*** TO VALID STORE (ALONG WITH ICC_TAG_VALID_SET_INDEX) ***/
  output                                            ICC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             ICC_VALID_WR_EN,
  output                                            ICC_VALID_WR_EN_GLOBAL,
);


endmodule