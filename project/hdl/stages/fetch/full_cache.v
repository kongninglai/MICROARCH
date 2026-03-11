module full_cache #(

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
  
  parameter BYTES_PER_BUS=4,
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter PAGE_SIZE_BYTES=4096,
  parameter PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES),
  parameter PFN_BIT_WIDTH=MEM_ADDR_WIDTH-PAGE_BIT_WIDTH
) (
  input                                                   rst,
                                                          clk,
  input     [2:0]                                         KB_PFN, 
                                                          DMA_PFN,

  /*** BUS SIGNALS ***/               
  inout     [BUS_BIT_WIDTH-1:0]                           DATA_BUS,
  inout     [MEM_ADDR_WIDTH-1:0]                          ADDR_BUS,
  inout     [CHIPS_PER_RANK-1:0]                          WR_mask,  

  /*** BETWEEN STORE QUEUE & CACHE, for WRITES ***/
  input                                                   STOREQ_STORING,
  input     [RANK_BIT_WIDTH-1:0]                          STOREQ_DATA,
  input     [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  STOREQ_DATA_WR_MASK,

  /*** BETWEEN TLB & CACHE, for READS ***/
  input     [PFN_BIT_WIDTH-1:0]                           ITLB_PFN_OUT,
  input                                                   ITLB_PAGE_FAULT_OUT,

  input     [PFN_BIT_WIDTH-1:0]                           D_RD_TLB_PFN_OUT,
  input                                                   D_RD_TLB_CACHE_ENABLE_OUT, 
  input                                                   D_RD_TLB_PAGE_FAULT_OUT,

  /*** BETWEEN THE PIPELINE REGISTERS & CACHE ***/
  input     [PAGE_BIT_WIDTH-1:0]                          F_PAGE_OFFSET,

  output    [RANK_BIT_WIDTH-1:0]                          ICACHE_HIT_DATA,
  output    [1:0]                                         ICACHE_EXCEPTION,
  output                                                  ICACHE_VALID,
  
  input     [PAGE_BIT_WIDTH-1:0]                          MEM_PAGE_OFFSET,
  input     [1:0]                                         MEM_RD_OR_WR_OHE,
                                                          MEM_EXCEPTION,
  input                                                   MEM_VALID,

  output    [RANK_BIT_WIDTH-1:0]                          DCACHE_HIT_DATA,
  output    [1:0]                                         DCACHE_EXCEPTION,
  output                                                  DCACHE_VALID,
  output                                                  DCACHE_STALL,

  /*** DMA INTERRUPT ***/
  output                                                  DMA_INT,

  /*** KB TEST CASE ***/
  input     [7:0]                                         TEST_CASE_NEW_CHAR      ,
                                                          TEST_CASE_NEW_CHAR_WR   ,
  input                                                   TEST_CASE_NEW_READY     ,
                                                          TEST_CASE_NEW_READY_WR  
);

/************************************************************/
/********************* INSTRUCTION CACHE ********************/
/************************************************************/

/*** BETWEEN CACHE CONTROLLER & ICACHE ***/                 
wire                                                   ICACHE_MISS;
wire     [RANK_BIT_WIDTH-1:0]                          ICACHE_RD_DATA;
wire     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            ICACHE_PHYS_ADDR;
wire     [WAY_WIDTH-1:0]                               ICACHE_VICT_WAY;     
wire                                                   ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY;
wire     [RANK_BIT_WIDTH-1:0]                          ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT;
wire     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            ICC_ADDR_OUT;
wire     [NUM_WAYS*RANK_BURST_SIZE-1:0]                ICC_DATA_WR_MASK_OUT;

/*** TO TAG STORE ***/
wire     [NUM_WAYS-1:0]                                ICC_TAG_WR_MASK_OUT;
wire     [TAG_WIDTH-1:0]                               ICC_TAG_IN;

/*** TO VALID STORE ***/
wire                                                   ICC_VALID_SET_OR_CLR;
wire     [INDEX_WIDTH+WAY_WIDTH-1:0]                   ICC_VALID_WR_EN;
wire                                                   ICC_FSM_VALID_WR_EN_GLOBAL;

/************************************************************/
/************************ EASY  ONES ************************/
/************************************************************/

assign ICACHE_PHYS_ADDR = {ITLB_PFN_OUT, F_PAGE_OFFSET[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE]};
assign ICACHE_HIT_DATA = ICC_HIT_DATA_OUT;

/************************************************************/
/************************ DATA STORE ************************/
/************************************************************/

wire [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  icache_wr_en_bar_one_hot, icache_wr_en_bar_one_hot_gated;

bit_duplicator bit_duplicator_icache_wr_en_bar_one_hot(
  .in(ICC_DATA_WR_MASK_OUT),
  .out(icache_wr_en_bar_one_hot)
);

wire  [NUM_WAYS*RANK_BIT_WIDTH-1:0]   ICACHE_RD_DATA_ALL_WAYS;

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  ICC_ADDR_OUT_buf64;

bufferH64$    bufferH64$_ICC_ADDR_OUT_buf64[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](ICC_ADDR_OUT_buf64, ICC_ADDR_OUT);

or2$    or2$_icache_wr_en_bar_one_hot_gated[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](icache_wr_en_bar_one_hot_gated, icache_wr_en_bar_one_hot, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk}});

data_store icache_data_store (
  .set_index(ICC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(icache_wr_en_bar_one_hot_gated),
  .data_in(ICC_WR_DATA_OUT),

  .data_out(ICACHE_RD_DATA_ALL_WAYS)
);

/************************************************************/
/************************ TAG  STORE ************************/
/************************************************************/

wire [NUM_WAYS-1:0] ICACHE_VALID_OUT;

wire  [NUM_WAYS*TAG_WIDTH-1:0]        ICACHE_TAG_OUT_ALL_WAYS;

wire     [NUM_WAYS-1:0]                                ICC_TAG_WR_MASK_OUT_gated;

or2$    or2$_ICC_TAG_WR_MASK_OUT_gated[NUM_WAYS-1:0](ICC_TAG_WR_MASK_OUT_gated, ICC_TAG_WR_MASK_OUT, {(NUM_WAYS){clk}});

tag_store icache_tag_store (
  .set_index(ICC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(ICC_TAG_WR_MASK_OUT_gated),
  .tag_in(ICC_TAG_IN),

  .tag_out(ICACHE_TAG_OUT_ALL_WAYS)
);

wire    [NUM_WAYS-1:0]    ICACHE_TAG_HIT;

wire    [WAY_WIDTH-1:0]   ICACHE_TAG_HIT_WAY, ICACHE_TAG_HIT_WAY_buf64;

bufferH64$    bufferH64$_ICACHE_TAG_HIT_WAY_buf64[WAY_WIDTH-1:0](ICACHE_TAG_HIT_WAY_buf64, ICACHE_TAG_HIT_WAY);

tag_hit_logic tag_hit_logic_ICACHE_TAG_HIT (
  .tag_store_out(ICACHE_TAG_OUT_ALL_WAYS),
  .tag_compare_val(ICC_ADDR_OUT_buf64[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7]),
  .cache_valid_out(ICACHE_VALID_OUT),

  .tag_hit(ICACHE_TAG_HIT),
  .tag_hit_way(ICACHE_TAG_HIT_WAY)
);

genvar j;
generate
  for (j = 0; j < 8; j = j + 1) begin : MUX16_16b_GEN
    mux4_16$ mux4_16_ICACHE_RD_DATA (
      .IN0 (ICACHE_RD_DATA_ALL_WAYS[(0*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN1 (ICACHE_RD_DATA_ALL_WAYS[(1*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN2 (ICACHE_RD_DATA_ALL_WAYS[(2*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN3 (ICACHE_RD_DATA_ALL_WAYS[(3*RANK_BIT_WIDTH+j*16) +: 16]),
      .S0(ICACHE_TAG_HIT_WAY_buf64[0]),
      .S1(ICACHE_TAG_HIT_WAY_buf64[1]),
      .Y(ICACHE_RD_DATA[j*16 +: 16])
    );
  end
endgenerate

/************************************************************/
/************************ LRU  STORE ************************/
/************************************************************/

wire    ICACHE_HIT;

lru_store lru_store_ICACHE_VICT_WAY (
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(ICACHE_TAG_HIT_WAY_buf64),
  .CACHE_HIT(ICACHE_HIT),
  .CC_ADDR_OUT(ICC_ADDR_OUT_buf64),

  .VICT_WAY(ICACHE_VICT_WAY)
);

/************************************************************/
/*********************** VALID  STORE ***********************/
/************************************************************/

valid_or_dirty_store icache_valid_store (
  .clk(clk), .rst(rst),
  .set_index(ICC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .set_or_clr(ICC_VALID_SET_OR_CLR),
  .wr_en(ICC_VALID_WR_EN),
  .wr_en_global(ICC_FSM_VALID_WR_EN_GLOBAL),

  .out(ICACHE_VALID_OUT)
);

wire  [NUM_WAYS-1:0]  ICACHE_HIT_ALL_WAYS;

generate 
  for (j = 0; j < NUM_WAYS; j = j + 1) begin : VALID_AND_TAG_HIT_GEN
    and2$   and2$_ICACHE_HIT_ALL_WAYS(ICACHE_HIT_ALL_WAYS[j], ICACHE_TAG_HIT[j], ICACHE_VALID_OUT[j]);
  end
endgenerate

mux4$   mux4$_ICACHE_HIT( ICACHE_HIT, 
                          ICACHE_HIT_ALL_WAYS[0], ICACHE_HIT_ALL_WAYS[1], ICACHE_HIT_ALL_WAYS[2], ICACHE_HIT_ALL_WAYS[3],
                          ICACHE_TAG_HIT_WAY_buf64[0], ICACHE_TAG_HIT_WAY_buf64[1]);

inv1$   inv1$_ICACHE_MISS(ICACHE_MISS, ICACHE_HIT);

/************************************************************/
/********************** ICACHE OUTPUTS **********************/
/************************************************************/

assign ICACHE_EXCEPTION = {1'b0, ITLB_PAGE_FAULT_OUT};

wire ICACHE_GENERAL_MISS;
nor2$     nor2$_ICACHE_GENERAL_MISS(ICACHE_GENERAL_MISS, ICACHE_HIT, ICC_STREAM_BUF_HIT);

nor3$     nor3$_ICACHE_VALID(ICACHE_VALID, ICACHE_GENERAL_MISS, ICACHE_EXCEPTION[0], ICC_FSM_FILL_BUSY);











/************************************************************/
/************************************************************/
/************************ DATA CACHE ************************/
/************************************************************/
/************************************************************/

/*** BETWEEN CACHE CONTROLLER & DCACHE ***/                 
wire                                                   DCACHE_MISS;
wire     [RANK_BIT_WIDTH-1:0]                          DCACHE_RD_DATA;
wire     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            DCACHE_RD_PHYS_ADDR;
wire     [WAY_WIDTH-1:0]                               DCACHE_VICT_WAY;     
wire                                                   DCC_STREAM_BUF_HIT, DCC_FSM_FILL_BUSY;
wire     [RANK_BIT_WIDTH-1:0]                          DCC_WR_DATA_OUT, DCC_HIT_DATA_OUT;
wire     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            DCC_ADDR_OUT;
wire     [NUM_WAYS*RANK_BURST_SIZE-1:0]                DCC_DATA_WR_MASK_OUT;

/*** TO TAG STORE ***/
wire     [NUM_WAYS-1:0]                                DCC_TAG_WR_MASK_OUT;
wire     [TAG_WIDTH-1:0]                               DCC_TAG_IN;

/*** TO VALID STORE ***/
wire                                                   DCC_VALID_SET_OR_CLR;
wire     [INDEX_WIDTH+WAY_WIDTH-1:0]                   DCC_VALID_WR_EN;
wire                                                   DCC_FSM_VALID_WR_EN_GLOBAL;

/*** BETWEEN WRITEBACK ENGINE & CACHE ***/
wire     [CHIPS_PER_RANK-1:0]                          WBE_BUSY;

wire                                                   DCACHE_NEED_WR_BUS;
wire     [RANK_BIT_WIDTH-1:0]                          DCACHE_WBE_DATA;
wire     [CHIPS_PER_RANK-1:0]                          DCACHE_WR_MASK;


/************************************************************/
/************************ EASY  ONES ************************/
/************************************************************/

assign DCACHE_RD_PHYS_ADDR = {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE]};
assign DCACHE_HIT_DATA = DCC_HIT_DATA_OUT;

/************************************************************/
/************************ DATA STORE ************************/
/************************************************************/

wire [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  dcache_wr_en_bar_one_hot, dcache_wr_en_bar_one_hot_gated;

bit_duplicator bit_duplicator_dcache_wr_en_bar_one_hot(
  .in(DCC_DATA_WR_MASK_OUT),
  .out(dcache_wr_en_bar_one_hot)
);

wire  [NUM_WAYS*RANK_BIT_WIDTH-1:0]   DCACHE_RD_DATA_ALL_WAYS;

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  DCC_ADDR_OUT_buf64;

bufferH64$    bufferH64$_DCC_ADDR_OUT_buf64[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCC_ADDR_OUT_buf64, DCC_ADDR_OUT);

or2$    or2$_dcache_wr_en_bar_one_hot_gated[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](dcache_wr_en_bar_one_hot_gated, dcache_wr_en_bar_one_hot, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk}});

data_store dcache_data_store (
  .set_index(DCC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(dcache_wr_en_bar_one_hot_gated),
  .data_in(DCC_WR_DATA_OUT),

  .data_out(DCACHE_RD_DATA_ALL_WAYS)
);

/************************************************************/
/************************ TAG  STORE ************************/
/************************************************************/

wire [NUM_WAYS-1:0] DCACHE_VALID_OUT;

wire  [NUM_WAYS*TAG_WIDTH-1:0]        DCACHE_TAG_OUT_ALL_WAYS;

wire     [NUM_WAYS-1:0]                                DCC_TAG_WR_MASK_OUT_gated;

or2$    or2$_DCC_TAG_WR_MASK_OUT_gated[NUM_WAYS-1:0](DCC_TAG_WR_MASK_OUT_gated, DCC_TAG_WR_MASK_OUT, {(NUM_WAYS){clk}});

tag_store dcache_tag_store (
  .set_index(DCC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(DCC_TAG_WR_MASK_OUT_gated),
  .tag_in(DCC_TAG_IN),

  .tag_out(DCACHE_TAG_OUT_ALL_WAYS)
);

wire    [NUM_WAYS-1:0]    DCACHE_TAG_HIT;

wire    [WAY_WIDTH-1:0]   DCACHE_TAG_HIT_WAY, DCACHE_TAG_HIT_WAY_buf64;

bufferH64$    bufferH64$_DCACHE_TAG_HIT_WAY_buf64[WAY_WIDTH-1:0](DCACHE_TAG_HIT_WAY_buf64, DCACHE_TAG_HIT_WAY);

tag_hit_logic tag_hit_logic_DCACHE_TAG_HIT (
  .tag_store_out(DCACHE_TAG_OUT_ALL_WAYS),
  .tag_compare_val(DCC_ADDR_OUT_buf64[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7]),
  .cache_valid_out(DCACHE_VALID_OUT),

  .tag_hit(DCACHE_TAG_HIT),
  .tag_hit_way(DCACHE_TAG_HIT_WAY)
);

genvar j;
generate
  for (j = 0; j < 8; j = j + 1) begin : DCACHE_MUX16_16b_GEN
    mux4_16$ mux4_16_DCACHE_RD_DATA (
      .IN0 (DCACHE_RD_DATA_ALL_WAYS[(0*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN1 (DCACHE_RD_DATA_ALL_WAYS[(1*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN2 (DCACHE_RD_DATA_ALL_WAYS[(2*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN3 (DCACHE_RD_DATA_ALL_WAYS[(3*RANK_BIT_WIDTH+j*16) +: 16]),
      .S0(DCACHE_TAG_HIT_WAY_buf64[0]),
      .S1(DCACHE_TAG_HIT_WAY_buf64[1]),
      .Y(DCACHE_RD_DATA[j*16 +: 16])
    );
  end
endgenerate

/************************************************************/
/************************ LRU  STORE ************************/
/************************************************************/

wire    DCACHE_HIT;

lru_store lru_store_DCACHE_VICT_WAY (
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(DCACHE_TAG_HIT_WAY_buf64),
  .CACHE_HIT(DCACHE_HIT),
  .CC_ADDR_OUT(DCC_ADDR_OUT_buf64),

  .VICT_WAY(DCACHE_VICT_WAY)
);

/************************************************************/
/*********************** VALID  STORE ***********************/
/************************************************************/

valid_or_dirty_store dcache_valid_store (
  .clk(clk), .rst(rst),
  .set_index(DCC_ADDR_OUT_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .set_or_clr(DCC_VALID_SET_OR_CLR),
  .wr_en(DCC_VALID_WR_EN),
  .wr_en_global(DCC_FSM_VALID_WR_EN_GLOBAL),

  .out(DCACHE_VALID_OUT)
);

wire  [NUM_WAYS-1:0]  DCACHE_HIT_ALL_WAYS;

generate 
  for (j = 0; j < NUM_WAYS; j = j + 1) begin : DCACHE_VALID_AND_TAG_HIT_GEN
    and2$   and2$_DCACHE_HIT_ALL_WAYS(DCACHE_HIT_ALL_WAYS[j], DCACHE_TAG_HIT[j], DCACHE_VALID_OUT[j]);
  end
endgenerate

mux4$   mux4$_DCACHE_HIT( DCACHE_HIT, 
                          DCACHE_HIT_ALL_WAYS[0], DCACHE_HIT_ALL_WAYS[1], DCACHE_HIT_ALL_WAYS[2], DCACHE_HIT_ALL_WAYS[3],
                          DCACHE_TAG_HIT_WAY_buf64[0], DCACHE_TAG_HIT_WAY_buf64[1]);

// inv1$   inv1$_DCACHE_MISS(DCACHE_MISS, DCACHE_HIT);
assign DCACHE_MISS = 1'b0;
assign DCACHE_NEED_WR_BUS = 1'b0;

/************************************************************/
/********************** DCACHE OUTPUTS **********************/
/************************************************************/

or2$      or2$_DCACHE_EXCEPTION[1:0](DCACHE_EXCEPTION, MEM_EXCEPTION, {1'b0, D_RD_TLB_PAGE_FAULT_OUT});

wire DCACHE_GENERAL_MISS;
nor2$     nor2$_DCACHE_GENERAL_MISS(DCACHE_GENERAL_MISS, DCACHE_HIT, DCC_STREAM_BUF_HIT);

nor3$     nor3$_DCACHE_VALID(DCACHE_VALID, DCACHE_GENERAL_MISS, DCACHE_EXCEPTION[0], DCC_FSM_FILL_BUSY);





/************************************************************/
/************************************************************/
/************************ CC OFFCORE ************************/
/************************************************************/
/************************************************************/

full_cc_off_core #(
  .MEM_BYTE_CAPACITY         (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10            (CYCLE_TIME_X10),
  .NUM_SETS                  (NUM_SETS),
  .NUM_WAYS                  (NUM_WAYS),
  .TAG_WIDTH                 (TAG_WIDTH)
) full_cc_off_core_inst (
  .rst                       (rst),
  .clk                       (clk),
  .KB_PFN                    (KB_PFN),
  .DMA_PFN                   (DMA_PFN),
  .DATA_BUS                  (DATA_BUS),
  .ADDR_BUS                  (ADDR_BUS),
  .WR_mask                   (WR_mask),
  .ICACHE_MISS               (ICACHE_MISS),
  .ICACHE_RD_DATA            (ICACHE_RD_DATA),
  .ICACHE_PHYS_ADDR          (ICACHE_PHYS_ADDR),
  .ICACHE_VICT_WAY           (ICACHE_VICT_WAY),
  .ICC_STREAM_BUF_HIT        (ICC_STREAM_BUF_HIT),
  .ICC_FSM_FILL_BUSY         (ICC_FSM_FILL_BUSY),
  .ICC_WR_DATA_OUT           (ICC_WR_DATA_OUT),
  .ICC_HIT_DATA_OUT          (ICC_HIT_DATA_OUT),
  .ICC_ADDR_OUT              (ICC_ADDR_OUT),
  .ICC_DATA_WR_MASK_OUT      (ICC_DATA_WR_MASK_OUT),
  .ICC_TAG_WR_MASK_OUT       (ICC_TAG_WR_MASK_OUT),
  .ICC_TAG_IN                (ICC_TAG_IN),
  .ICC_VALID_SET_OR_CLR      (ICC_VALID_SET_OR_CLR),
  .ICC_VALID_WR_EN           (ICC_VALID_WR_EN),
  .ICC_FSM_VALID_WR_EN_GLOBAL(ICC_FSM_VALID_WR_EN_GLOBAL),
  .DCACHE_MISS               (DCACHE_MISS),
  .DCACHE_RD_DATA            (DCACHE_RD_DATA),
  .DCACHE_RD_PHYS_ADDR       (DCACHE_RD_PHYS_ADDR),
  .DCACHE_VICT_WAY           (DCACHE_VICT_WAY),
  .DCC_STREAM_BUF_HIT        (DCC_STREAM_BUF_HIT),
  .DCC_FSM_FILL_BUSY         (DCC_FSM_FILL_BUSY),
  .DCC_WR_DATA_OUT           (DCC_WR_DATA_OUT),
  .DCC_HIT_DATA_OUT          (DCC_HIT_DATA_OUT),
  .DCC_ADDR_OUT              (DCC_ADDR_OUT),
  .DCC_DATA_WR_MASK_OUT      (DCC_DATA_WR_MASK_OUT),
  .DCC_TAG_WR_MASK_OUT       (DCC_TAG_WR_MASK_OUT),
  .DCC_TAG_IN                (DCC_TAG_IN),
  .DCC_VALID_SET_OR_CLR      (DCC_VALID_SET_OR_CLR),
  .DCC_VALID_WR_EN           (DCC_VALID_WR_EN),
  .DCC_FSM_VALID_WR_EN_GLOBAL(DCC_FSM_VALID_WR_EN_GLOBAL),
  .DCACHE_NEED_WR_BUS        (DCACHE_NEED_WR_BUS),
  .DCACHE_WBE_DATA           (DCACHE_WBE_DATA),
  .DCACHE_WR_PHYS_ADDR       (DCACHE_WR_PHYS_ADDR),
  .DCACHE_WR_MASK            (DCACHE_WR_MASK),
  .WBE_BUSY                  (WBE_BUSY),
  .DMA_INT                   (DMA_INT),
  .TEST_CASE_NEW_CHAR        (TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR     (TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY       (TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR    (TEST_CASE_NEW_READY_WR)
);

endmodule