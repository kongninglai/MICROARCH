module full_cc_off_core #(
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

  /********** ICACHE **********/

  /*** BETWEEN CACHE CONTROLLER & CACHE ***/                
  input                                             ICACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    ICACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         ICACHE_VICT_WAY,

  output                                            ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT,
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICC_ADDR_OUT,
  output    [NUM_WAYS*RANK_BURST_SIZE-1:0]          ICC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [NUM_WAYS-1:0]                          ICC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         ICC_TAG_IN,

  /*** TO VALID STORE ***/
  output                                            ICC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             ICC_VALID_WR_EN,
  output                                            ICC_FSM_VALID_WR_EN_GLOBAL,

  /********** DCACHE **********/          

  /*** BETWEEN CACHE CONTROLLER & CACHE ***/        
  input                                             DCACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    DCACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      DCACHE_RD_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         DCACHE_VICT_WAY,

  output                                            DCC_STREAM_BUF_HIT, DCC_FSM_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    DCC_WR_DATA_OUT, DCC_HIT_DATA_OUT,
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      DCC_ADDR_OUT,
  output    [NUM_WAYS*RANK_BURST_SIZE-1:0]          DCC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [NUM_WAYS-1:0]                          DCC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         DCC_TAG_IN,

  /*** TO VALID STORE ***/
  output                                            DCC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             DCC_VALID_WR_EN,
  output                                            DCC_FSM_VALID_WR_EN_GLOBAL,

  /*** WRITEBACK ENGINE ***/
  input                                             DCACHE_NEED_WR_BUS,
  input     [RANK_BIT_WIDTH-1:0]                    DCACHE_WBE_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      DCACHE_WR_PHYS_ADDR,
  input     [CHIPS_PER_RANK-1:0]                    DCACHE_WR_MASK,

  output                                            WBE_BUSY,

  /*** DMA INTERRUPT ***/
  output                                            DMA_INT,

  /*** KB TEST CASE ***/
  input     [7:0]                                   TEST_CASE_NEW_CHAR      ,
                                                    TEST_CASE_NEW_CHAR_WR   ,
  input                                             TEST_CASE_NEW_READY     ,
                                                    TEST_CASE_NEW_READY_WR  
);

wire    [2:0]   ICC_REQS, ICC_ACKS;
wire    [5:0]   DCC_REQS, DCC_ACKS;

wire    DATA_VALID_BAR;

dcache_controller_wbe dcache_controller_wbe_inst (
    .clk                            (clk),
    .rst                            (rst),
    .DC_MEM_WR_ACK                  (DCC_ACKS[5]),
    .DC_DMA_WR_ACK                  (DCC_ACKS[4]),
    .DC_KB_WR_ACK                   (DCC_ACKS[3]),
    .DCACHE_NEED_WR_BUS             (DCACHE_NEED_WR_BUS),
    .DCACHE_WBE_DATA                (DCACHE_WBE_DATA),
    .DCACHE_PHYS_ADDR               (DCACHE_WR_PHYS_ADDR),
    .DCACHE_WR_MASK                 (DCACHE_WR_MASK),
    .KB_PFN                         (KB_PFN),
    .DMA_PFN                        (DMA_PFN),
    .WR_mask                        (WR_mask),
    .ADDR_BUS                       (ADDR_BUS),
    .DATA_BUS                       (DATA_BUS),
    .DC_MEM_WR_RQ                   (DCC_REQS[5]),
    .DC_DMA_WR_RQ                   (DCC_REQS[4]),
    .DC_KB_WR_RQ                    (DCC_REQS[3]),
    .WBE_BUSY                       (WBE_BUSY)
);

cache_controller icache_controller_inst (
    .rst(rst), .clk(clk),
    .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN),
    .DATA_BUS(DATA_BUS),
    .ACKS({ICC_ACKS[2], 2'b00}),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .REQS(ICC_REQS),
    .CACHE_MISS(ICACHE_MISS),
    .CACHE_RD_DATA(ICACHE_RD_DATA),
    .CACHE_PHYS_ADDR(ICACHE_PHYS_ADDR),
    .CACHE_VICT_WAY(ICACHE_VICT_WAY),
    .CC_STREAM_BUF_HIT(ICC_STREAM_BUF_HIT),
    .CC_FSM_FILL_BUSY(ICC_FSM_FILL_BUSY),
    .CC_WR_DATA_OUT(ICC_WR_DATA_OUT),
    .CC_HIT_DATA_OUT(ICC_HIT_DATA_OUT),
    .CC_ADDR_OUT(ICC_ADDR_OUT),
    .CC_DATA_WR_MASK_OUT(ICC_DATA_WR_MASK_OUT),
    .CC_TAG_WR_MASK_OUT(ICC_TAG_WR_MASK_OUT),
    .CC_TAG_IN(ICC_TAG_IN),
    .CC_VALID_SET_OR_CLR(ICC_VALID_SET_OR_CLR),
    .CC_VALID_WR_EN(ICC_VALID_WR_EN),
    .CC_FSM_VALID_WR_EN_GLOBAL(ICC_FSM_VALID_WR_EN_GLOBAL)
);

cache_controller dcache_controller_inst (
    .rst(rst), .clk(clk),
    .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN),
    .DATA_BUS(DATA_BUS),
    .ACKS(DCC_ACKS[2:0]),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .REQS(DCC_REQS[2:0]),
    .CACHE_MISS(DCACHE_MISS),
    .CACHE_RD_DATA(DCACHE_RD_DATA),
    .CACHE_PHYS_ADDR(DCACHE_RD_PHYS_ADDR),
    .CACHE_VICT_WAY(DCACHE_VICT_WAY),
    .CC_STREAM_BUF_HIT(DCC_STREAM_BUF_HIT),
    .CC_FSM_FILL_BUSY(DCC_FSM_FILL_BUSY),
    .CC_WR_DATA_OUT(DCC_WR_DATA_OUT),
    .CC_HIT_DATA_OUT(DCC_HIT_DATA_OUT),
    .CC_ADDR_OUT(DCC_ADDR_OUT),
    .CC_DATA_WR_MASK_OUT(DCC_DATA_WR_MASK_OUT),
    .CC_TAG_WR_MASK_OUT(DCC_TAG_WR_MASK_OUT),
    .CC_TAG_IN(DCC_TAG_IN),
    .CC_VALID_SET_OR_CLR(DCC_VALID_SET_OR_CLR),
    .CC_VALID_WR_EN(DCC_VALID_WR_EN),
    .CC_FSM_VALID_WR_EN_GLOBAL(DCC_FSM_VALID_WR_EN_GLOBAL)
);

off_core_top #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) off_core_top_inst (
  .rst(rst),
  .clk(clk),
  .DC_MEM_WR_RQ(DCC_REQS[5]),
  .DC_DMA_WR_RQ(DCC_REQS[4]),
  .DC_KB_WR_RQ(DCC_REQS[3]),
  .DC_MEM_RD_RQ(DCC_REQS[2]),
  .DC_DMA_RD_RQ(DCC_REQS[1]),
  .DC_KB_RD_RQ(DCC_REQS[0]),
  .IC_MEM_RD_RQ(ICC_REQS[2]),
  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),
  .WR_mask(WR_mask),
  .ADDR_BUS(ADDR_BUS),
  .DATA_BUS(DATA_BUS),
  .DATA_VALID_BAR(DATA_VALID_BAR),
  .DC_MEM_WR_ACK(DCC_ACKS[5]),
  .DC_DMA_WR_ACK(DCC_ACKS[4]),
  .DC_KB_WR_ACK(DCC_ACKS[3]),
  .DC_MEM_RD_ACK(DCC_ACKS[2]),
  .DC_DMA_RD_ACK(DCC_ACKS[1]),
  .DC_KB_RD_ACK(DCC_ACKS[0]),
  .IC_MEM_RD_ACK(ICC_ACKS[2]),
  .DMA_INT(DMA_INT)
);

endmodule