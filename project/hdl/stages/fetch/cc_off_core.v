module cc_off_core #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),
  parameter CYCLE_TIME_X10=100,

  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8
) (
  input                                             rst, clk, 
  input     [2:0]                                   KB_PFN, DMA_PFN,

  /*** BUS SIGNALS ***/               
  inout     [BUS_BIT_WIDTH-1:0]                     DATA_BUS,
  inout     [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS,
  inout     [CHIPS_PER_RANK-1:0]                    WR_mask,  

  /*** BETWEEN CACHE CONTROLLER & CACHE ***/                
  input                                             CACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    CACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         CACHE_VICT_WAY,
  input     [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] CC_DATA_WR_MASK_DEFAULT,

  output                                            CC_STREAM_BUF_HIT, CC_FSM_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    CC_WR_DATA_OUT, CC_HIT_DATA_OUT,
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT,
  output    [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] CC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [INDEX_WIDTH-1:0]                       CC_TAG_VALID_SET_INDEX,
  output    [NUM_WAYS-1:0]                          CC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         CC_TAG_IN,

  /*** TO VALID STORE (ALONG WITH CC_TAG_VALID_SET_INDEX) ***/
  output                                            CC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             CC_VALID_WR_EN,
  output                                            CC_FSM_VALID_WR_EN_GLOBAL,

  /*** Need to write stuff into memory first ***/
  input                                             DC_MEM_WR_RQ,  
  output                                            DC_MEM_WR_ACK
);

wire    [2:0]   REQS, ACKS;

wire    DATA_VALID_BAR;

cache_controller cache_controller_inst (
    .rst(rst), .clk(clk),
    .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN),
    .DATA_BUS(DATA_BUS),
    .ACKS({ACKS[2], 2'b00}),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .REQS(REQS),
    .CACHE_MISS(CACHE_MISS),
    .CACHE_RD_DATA(CACHE_RD_DATA),
    .CACHE_PHYS_ADDR(CACHE_PHYS_ADDR),
    .CACHE_VICT_WAY(CACHE_VICT_WAY),
    .CC_DATA_WR_MASK_DEFAULT(CC_DATA_WR_MASK_DEFAULT),
    .CC_STREAM_BUF_HIT(CC_STREAM_BUF_HIT),
    .CC_FSM_FILL_BUSY(CC_FSM_FILL_BUSY),
    .CC_WR_DATA_OUT(CC_WR_DATA_OUT),
    .CC_HIT_DATA_OUT(CC_HIT_DATA_OUT),
    .CC_ADDR_OUT(CC_ADDR_OUT),
    .CC_DATA_WR_MASK_OUT(CC_DATA_WR_MASK_OUT),
    .CC_TAG_VALID_SET_INDEX(CC_TAG_VALID_SET_INDEX),
    .CC_TAG_WR_MASK_OUT(CC_TAG_WR_MASK_OUT),
    .CC_TAG_IN(CC_TAG_IN),
    .CC_VALID_SET_OR_CLR(CC_VALID_SET_OR_CLR),
    .CC_VALID_WR_EN(CC_VALID_WR_EN),
    .CC_FSM_VALID_WR_EN_GLOBAL(CC_FSM_VALID_WR_EN_GLOBAL)
);

off_core_top #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst(rst),
  .clk(clk),
  .DC_MEM_WR_RQ(DC_MEM_WR_RQ),
  .DC_DMA_WR_RQ(1'b0),
  .DC_KB_WR_RQ(1'b0),
  .DC_MEM_RD_RQ(1'b0),
  .DC_DMA_RD_RQ(1'b0),
  .DC_KB_RD_RQ(1'b0),
  .IC_MEM_RD_RQ(REQS[2]),
  .TEST_CASE_NEW_CHAR(8'd0),
  .TEST_CASE_NEW_CHAR_WR(8'd0),
  .TEST_CASE_NEW_READY(1'b0),
  .TEST_CASE_NEW_READY_WR(1'b0),
  .WR_mask(WR_mask),
  .ADDR_BUS(ADDR_BUS),
  .DATA_BUS(DATA_BUS),
  .DATA_VALID_BAR(DATA_VALID_BAR),
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK),
  .DC_DMA_WR_ACK(),
  .DC_KB_WR_ACK(),
  .DC_MEM_RD_ACK(),
  .DC_DMA_RD_ACK(),
  .DC_KB_RD_ACK(),
  .IC_MEM_RD_ACK(ACKS[2]),
  .DMA_INT()
);

endmodule