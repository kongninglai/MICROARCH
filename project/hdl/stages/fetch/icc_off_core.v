module icc_off_core #(
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

  /*** BUS SIGNALS ***/               
  inout     [BUS_BIT_WIDTH-1:0]                     DATA_BUS,
  inout     [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS,
  inout     [CHIPS_PER_RANK-1:0]                    WR_mask,  

  /*** BETWEEN ICACHE CONTROLLER & ICACHE ***/                
  input                                             ICACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    ICACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         ICACHE_VICT_WAY,
  input     [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] ICC_DATA_WR_MASK_DEFAULT,

  output                                            ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT,
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICC_ADDR_OUT,
  output    [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] ICC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [INDEX_WIDTH-1:0]                       ICC_TAG_VALID_SET_INDEX,
  output    [NUM_WAYS-1:0]                          ICC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         ICC_TAG_IN,

  /*** TO VALID STORE (ALONG WITH ICC_TAG_VALID_SET_INDEX) ***/
  output                                            ICC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             ICC_VALID_WR_EN,
  output                                            ICC_FSM_VALID_WR_EN_GLOBAL,

  /*** Need to write stuff into memory first ***/
  input                                             DC_MEM_WR_RQ,  
  output                                            DC_MEM_WR_ACK
);

wire    IC_MEM_RD_RQ, IC_MEM_RD_ACK, DATA_VALID_BAR;

icache_controller icache_controller_inst (
    .rst(rst), .clk(clk),
    .DATA_BUS(DATA_BUS),
    .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .IC_MEM_RD_RQ(IC_MEM_RD_RQ),
    .ICACHE_MISS(ICACHE_MISS),
    .ICACHE_RD_DATA(ICACHE_RD_DATA),
    .ICACHE_PHYS_ADDR(ICACHE_PHYS_ADDR),
    .ICACHE_VICT_WAY(ICACHE_VICT_WAY),
    .ICC_DATA_WR_MASK_DEFAULT(ICC_DATA_WR_MASK_DEFAULT),
    .ICC_STREAM_BUF_HIT(ICC_STREAM_BUF_HIT),
    .ICC_FSM_FILL_BUSY(ICC_FSM_FILL_BUSY),
    .ICC_WR_DATA_OUT(ICC_WR_DATA_OUT),
    .ICC_HIT_DATA_OUT(ICC_HIT_DATA_OUT),
    .ICC_ADDR_OUT(ICC_ADDR_OUT),
    .ICC_DATA_WR_MASK_OUT(ICC_DATA_WR_MASK_OUT),
    .ICC_TAG_VALID_SET_INDEX(ICC_TAG_VALID_SET_INDEX),
    .ICC_TAG_WR_MASK_OUT(ICC_TAG_WR_MASK_OUT),
    .ICC_TAG_IN(ICC_TAG_IN),
    .ICC_VALID_SET_OR_CLR(ICC_VALID_SET_OR_CLR),
    .ICC_VALID_WR_EN(ICC_VALID_WR_EN),
    .ICC_FSM_VALID_WR_EN_GLOBAL(ICC_FSM_VALID_WR_EN_GLOBAL)
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
  .IC_MEM_RD_RQ(IC_MEM_RD_RQ),
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
  .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .DMA_INT()
);

endmodule