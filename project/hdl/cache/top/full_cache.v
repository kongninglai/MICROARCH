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
  parameter PFN_BIT_WIDTH=MEM_ADDR_WIDTH-PAGE_BIT_WIDTH,

  parameter TRUE_LRU=0
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
  input                                                   STOREQ_LAST_ENTRY,
  input     [RANK_BIT_WIDTH-1:0]                          STOREQ_DATA,
  input     [RANK_BURST_SIZE*BYTES_PER_BUS-1:0]           STOREQ_DATA_WR_MASK,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            STOREQ_PHYS_ADDR,

  /*** BETWEEN TLB & CACHE, for READS ***/
  input     [PFN_BIT_WIDTH-1:0]                           ITLB_PFN_OUT,
  input                                                   ITLB_PAGE_FAULT_OUT,

  input     [PFN_BIT_WIDTH-1:0]                           D_RD_TLB_PFN_OUT,
  input                                                   D_RD_TLB_CACHE_ENABLE_OUT,

  /*** BETWEEN THE PIPELINE REGISTERS & CACHE ***/
  input     [PAGE_BIT_WIDTH-1:0]                          F_PAGE_OFFSET,

  output    [RANK_BIT_WIDTH-1:0]                          ICACHE_HIT_DATA,
  output                                                  ICACHE_VALID,
  
  input     [PAGE_BIT_WIDTH-1:0]                          MEM_PAGE_OFFSET,
  input                                                   MEM_VALID_LOAD_INST,

  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            WB_PR_ST_ADDR_L0,
  input     [CHIPS_PER_RANK-1:0]                          WB_PR_ST_MASK_L0,
  input     [RANK_BIT_WIDTH-1:0]                          WB_SHF_ST_DATA_L0,
  input                                                   WB_VALID_IO_STORE_INST,

  output    [RANK_BIT_WIDTH-1:0]                          DCACHE_HIT_DATA,
  output                                                  DCACHE_HIT,
  output                                                  DCACHE_STALL,
  output                                                  WBE_BUSY,

  /*** DMA INTERRUPT ***/
  output                                                  DMA_INT,

  /*** KB TEST CASE ***/
  input     [7:0]                                         TEST_CASE_NEW_CHAR      ,
                                                          TEST_CASE_NEW_CHAR_WR   ,
  input                                                   TEST_CASE_NEW_READY     ,
                                                          TEST_CASE_NEW_READY_WR  ,

  /*** FLUSH SIGNAL ***/
  input                                                   WB_FLUSH, EX_FLUSH
);

wire [2:0] KB_PFN_buf16, DMA_PFN_buf16;
bufferH16$    bufferH16$_KB_PFN_buf16[2:0](KB_PFN_buf16, KB_PFN);
bufferH16$    bufferH16$_DMA_PFN_buf16[2:0](DMA_PFN_buf16, DMA_PFN);


/************************************************************/
/************************************************************/
/************************ DATA CACHE ************************/
/************************************************************/
/************************************************************/

/*** BETWEEN CACHE CONTROLLER & DCACHE ***/                 
wire                                                   DCACHE_MISS;
wire     [RANK_BIT_WIDTH-1:0]                          DCACHE_RD_DATA;
wire     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]            DCACHE_PHYS_ADDR;
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

wire                                                   DCACHE_NEED_WR_BUS;
wire     [RANK_BIT_WIDTH-1:0]                          DCACHE_WBE_DATA;
wire     [CHIPS_PER_RANK-1:0]                          DCACHE_WR_MASK;


/************************************************************/
/************************ EASY  ONES ************************/
/************************************************************/

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

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  DCC_ADDR_OUT_buf256;

bufferH256$    bufferH256$_DCC_ADDR_OUT_buf256[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCC_ADDR_OUT_buf256, DCC_ADDR_OUT);

wire    [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  final_dcache_wr_en_bar_one_hot, final_dcache_wr_en_bar_one_hot_gated, final_dcache_wr_en_bar_one_hot_gated_rst;

wire    STOREQ_STORE_COND, STOREQ_STORE_COND_buf1024;

wire    STOREQ_STORING_buf16;

bufferH16$    bufferH16$_STOREQ_STORING_buf16(STOREQ_STORING_buf16, STOREQ_STORING);

and2$   and2$_STOREQ_STORE_COND(STOREQ_STORE_COND, STOREQ_STORING_buf16, DCACHE_HIT);
bufferH1024$  bufferH1024$_STOREQ_STORE_COND_buf1024(STOREQ_STORE_COND_buf1024, STOREQ_STORE_COND);

wire [RANK_BURST_SIZE*BYTES_PER_BUS-1:0] STOREQ_DATA_WR_MASK_buf64;
wire [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0] STOREQ_DATA_WR_MASK_SHF, STOREQ_DATA_WR_MASK_SHF_GATED;

bufferH64$    bufferH64$_STOREQ_DATA_WR_MASK_buf64[RANK_BURST_SIZE*BYTES_PER_BUS-1:0](STOREQ_DATA_WR_MASK_buf64, STOREQ_DATA_WR_MASK);

wire    [WAY_WIDTH-1:0]   DCACHE_TAG_HIT_WAY, DCACHE_TAG_HIT_WAY_buf16;

lshf_chunks_var_64b lshf_chunks_var_64b_STOREQ_DATA_WR_MASK_SHF (
  .in({{48{1'b1}}, STOREQ_DATA_WR_MASK_buf64}),
  .shf_amt(DCACHE_TAG_HIT_WAY_buf16),
  .out(STOREQ_DATA_WR_MASK_SHF)
);

wire DCACHE_VALID, DCACHE_VALID_buf64;

bufferH64$    bufferH64$_DCACHE_VALID_buf64(DCACHE_VALID_buf64,DCACHE_VALID);

mux2$   mux2$_STOREQ_DATA_WR_MASK_SHF_GATED[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](STOREQ_DATA_WR_MASK_SHF_GATED, STOREQ_DATA_WR_MASK_SHF, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){1'b1}}, DCACHE_VALID_buf64);

mux2$   mux2$_final_dcache_wr_en_bar_one_hot[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](final_dcache_wr_en_bar_one_hot, dcache_wr_en_bar_one_hot, STOREQ_DATA_WR_MASK_SHF, STOREQ_STORE_COND_buf1024);

/* You can also just gate DCACHE_HIT with whether or not SET[2:0] changed from last cycle using a reg_n and a 3-bit comparator...
   can force STOREQ writes to take 2 cycles if really necessary */

wire    clk_bar, clk_bar_buf4096, clk_buf4096;

bufferHInv4096$   bufferHInv4096$_clk_bar_buf4096(clk_bar_buf4096, clk);

bufferHInv4096$   bufferHInv4096$_clk_buf4096(clk_buf4096, clk_bar_buf4096);

inv1$   inv1$_clk_bar(clk_bar, clk);

or3$    or3$_final_dcache_wr_en_bar_one_hot_gated[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](final_dcache_wr_en_bar_one_hot_gated, final_dcache_wr_en_bar_one_hot, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk}}, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk_buf4096}});

wire    [RANK_BIT_WIDTH-1:0]  FINAL_DCACHE_WR_DATA_OUT, STOREQ_DATA_REG;

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_STOREQ_DATA_REG (
  .clk(clk_bar), .rst(rst),
  .en({RANK_BIT_WIDTH{1'b1}}), .d(STOREQ_DATA),
  .q(STOREQ_DATA_REG)
);

mux2$   mux2$_FINAL_DCACHE_WR_DATA_OUT[RANK_BIT_WIDTH-1:0](FINAL_DCACHE_WR_DATA_OUT, DCC_WR_DATA_OUT, STOREQ_DATA_REG, STOREQ_STORE_COND_buf1024);

mux2$   mux2$_DCACHE_PHYS_ADDR[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCACHE_PHYS_ADDR, {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE]}, STOREQ_PHYS_ADDR, STOREQ_STORING_buf16);

wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCACHE_PHYS_ADDR_buf16;

bufferH16$    bufferH16$_DCACHE_PHYS_ADDR_buf16[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCACHE_PHYS_ADDR_buf16, DCACHE_PHYS_ADDR);

mux2$   mux2$_final_dcache_wr_en_bar_one_hot_gated_rst[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](
                                                                                                      final_dcache_wr_en_bar_one_hot_gated_rst,
                                                                                                      {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){1'b1}},
                                                                                                      final_dcache_wr_en_bar_one_hot_gated,
                                                                                                      rst
                                                                                                  );

data_store dcache_data_store (
  .set_index(DCC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(final_dcache_wr_en_bar_one_hot_gated_rst),
  .data_in(FINAL_DCACHE_WR_DATA_OUT),

  .data_out(DCACHE_RD_DATA_ALL_WAYS)
);

/************************************************************/
/************************ TAG  STORE ************************/
/************************************************************/

wire [NUM_WAYS-1:0] DCACHE_VALID_OUT;

wire  [NUM_WAYS*TAG_WIDTH-1:0]        DCACHE_TAG_OUT_ALL_WAYS;

wire     [NUM_WAYS-1:0]                                DCC_TAG_WR_MASK_OUT_gated, DCC_TAG_WR_MASK_OUT_gated_rst;

or2$    or2$_DCC_TAG_WR_MASK_OUT_gated[NUM_WAYS-1:0](DCC_TAG_WR_MASK_OUT_gated, DCC_TAG_WR_MASK_OUT, {(NUM_WAYS){clk}});

mux2$   mux2$_DCC_TAG_WR_MASK_OUT_gated_rst[NUM_WAYS-1:0] (
                                                              DCC_TAG_WR_MASK_OUT_gated_rst,
                                                              {NUM_WAYS{1'b1}},
                                                              DCC_TAG_WR_MASK_OUT_gated,
                                                              rst
                                                          );


wire  [RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE] DCACHE_TAG_SET, DCACHE_TAG_SET_buf64;

wire  DCACHE_TAG_SET_SEL;

wire DCC_FSM_VALID_WR_EN_GLOBAL_REG, DCC_FSM_VALID_WR_EN_GLOBAL_BAR, DCC_FSM_VALID_WR_EN_GLOBAL_buf16;

bufferH16$    bufferH16$_DCC_FSM_VALID_WR_EN_GLOBAL_buf16(DCC_FSM_VALID_WR_EN_GLOBAL_buf16, DCC_FSM_VALID_WR_EN_GLOBAL);

inv1$ inv1$_DCC_FSM_VALID_WR_EN_GLOBAL_BAR(DCC_FSM_VALID_WR_EN_GLOBAL_BAR, DCC_FSM_VALID_WR_EN_GLOBAL_buf16);

dff$  dff$_DCC_FSM_VALID_WR_EN_GLOBAL_REG(clk, DCC_FSM_VALID_WR_EN_GLOBAL_buf16, DCC_FSM_VALID_WR_EN_GLOBAL_REG, , rst, 1'b1);

nor2$ nor2$_DCACHE_TAG_SET_SEL(DCACHE_TAG_SET_SEL, DCC_FSM_VALID_WR_EN_GLOBAL_REG, DCC_FSM_VALID_WR_EN_GLOBAL_BAR);

/* Originally had simply DCC_FSM_VALID_WR_EN_GLOBAL as sel here, but HAD to save 0.2 ns */
mux2$   mux2$_DCACHE_TAG_SET[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE](DCACHE_TAG_SET, DCACHE_PHYS_ADDR_buf16[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], DCC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], DCACHE_TAG_SET_SEL);

bufferH64$    bufferH64$_DCACHE_TAG_SET_buf64[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE](DCACHE_TAG_SET_buf64, DCACHE_TAG_SET);

wire    [TAG_WIDTH-1:0]   DCC_TAG_IN_buf16;

bufferH16$    bufferH16$_DCC_TAG_IN_buf16[TAG_WIDTH-1:0](DCC_TAG_IN_buf16, DCC_TAG_IN);

tag_store dcache_tag_store (
  .set_index(DCACHE_TAG_SET_buf64),
  .wr_en_bar_one_hot(DCC_TAG_WR_MASK_OUT_gated_rst),
  .tag_in(DCC_TAG_IN_buf16),

  .tag_out(DCACHE_TAG_OUT_ALL_WAYS)
);

wire    [NUM_WAYS-1:0]    DCACHE_TAG_HIT, DCACHE_TAG_HIT_FINAL;


bufferH16$    bufferH16$_DCACHE_TAG_HIT_WAY_buf16[WAY_WIDTH-1:0](DCACHE_TAG_HIT_WAY_buf16, DCACHE_TAG_HIT_WAY);

tag_hit_logic tag_hit_logic_DCACHE_TAG_HIT (
  .tag_store_out(DCACHE_TAG_OUT_ALL_WAYS),
  .tag_compare_val(DCC_ADDR_OUT_buf256[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7]),
  .cache_valid_out(DCACHE_VALID_OUT),

  .tag_hit(DCACHE_TAG_HIT),
  .tag_hit_way(DCACHE_TAG_HIT_WAY)
);

mux2$   mux2$_DCACHE_TAG_HIT_FINAL[NUM_WAYS-1:0](DCACHE_TAG_HIT_FINAL, DCACHE_TAG_HIT, {NUM_WAYS{1'b0}}, DCC_FSM_VALID_WR_EN_GLOBAL_buf16);

wire    [WAY_WIDTH-1:0]   FINAL_DCACHE_RD_DATA_MUX_SEL, FINAL_DCACHE_RD_DATA_MUX_SEL_buf16;

wire    DIRTY_WB_NEEDED;

wire    [WAY_WIDTH-1:0]   DCACHE_VICT_WAY_buf16;
bufferH16$    bufferH16$_DCACHE_VICT_WAY_buf16[WAY_WIDTH-1:0](DCACHE_VICT_WAY_buf16, DCACHE_VICT_WAY);

mux2$         mux2$_FINAL_DCACHE_RD_DATA_MUX_SEL[WAY_WIDTH-1:0](FINAL_DCACHE_RD_DATA_MUX_SEL, DCACHE_TAG_HIT_WAY_buf16, DCACHE_VICT_WAY_buf16, DIRTY_WB_NEEDED);

bufferH16$    bufferH16$_FINAL_DCACHE_RD_DATA_MUX_SEL_buf16[WAY_WIDTH-1:0](FINAL_DCACHE_RD_DATA_MUX_SEL_buf16, FINAL_DCACHE_RD_DATA_MUX_SEL);

genvar j;
generate
  for (j = 0; j < 8; j = j + 1) begin : DCACHE_MUX4_16b_GEN
    mux4_16$ mux4_16_DCACHE_RD_DATA (
      .IN0 (DCACHE_RD_DATA_ALL_WAYS[(0*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN1 (DCACHE_RD_DATA_ALL_WAYS[(1*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN2 (DCACHE_RD_DATA_ALL_WAYS[(2*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN3 (DCACHE_RD_DATA_ALL_WAYS[(3*RANK_BIT_WIDTH+j*16) +: 16]),
      .S0(FINAL_DCACHE_RD_DATA_MUX_SEL_buf16[0]),
      .S1(FINAL_DCACHE_RD_DATA_MUX_SEL_buf16[1]),
      .Y(DCACHE_RD_DATA[j*16 +: 16])
    );
  end
endgenerate

/************************************************************/
/************************ LRU  STORE ************************/
/************************************************************/

wire DCACHE_HIT_WITH_ACCESS, DCACHE_STREAM_BUF_HIT_WITH_ACCESS;

lru_store #(.TRUE_LRU(TRUE_LRU)) lru_store_DCACHE_VICT_WAY (
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(DCACHE_TAG_HIT_WAY_buf16),
  .CACHE_HIT(DCACHE_HIT_WITH_ACCESS),
  .CC_ADDR_OUT(DCC_ADDR_OUT_buf256),
  .CC_STREAM_BUF_HIT(DCACHE_STREAM_BUF_HIT_WITH_ACCESS),

  .VICT_WAY(DCACHE_VICT_WAY)
);

/************************************************************/
/*********************** VALID  STORE ***********************/
/************************************************************/

valid_or_dirty_store dcache_valid_store (
  .clk(clk), .rst(rst),
  .set_index(DCACHE_TAG_SET_buf64),
  .set_or_clr(DCC_VALID_SET_OR_CLR),
  .wr_en(DCC_VALID_WR_EN),
  .wr_en_global(DCC_FSM_VALID_WR_EN_GLOBAL_buf16),

  .out(DCACHE_VALID_OUT)
);

wire  [NUM_WAYS-1:0]  DCACHE_HIT_ALL_WAYS;

generate 
  for (j = 0; j < NUM_WAYS; j = j + 1) begin : DCACHE_VALID_AND_TAG_HIT_GEN
    and2$   and2$_DCACHE_HIT_ALL_WAYS(DCACHE_HIT_ALL_WAYS[j], DCACHE_TAG_HIT_FINAL[j], DCACHE_VALID_OUT[j]);
  end
endgenerate

mux4$   mux4$_DCACHE_HIT( DCACHE_HIT, 
                          DCACHE_HIT_ALL_WAYS[0], DCACHE_HIT_ALL_WAYS[1], DCACHE_HIT_ALL_WAYS[2], DCACHE_HIT_ALL_WAYS[3],
                          DCACHE_TAG_HIT_WAY_buf16[0], DCACHE_TAG_HIT_WAY_buf16[1]);

/************************************************************/
/*********************** DIRTY  STORE ***********************/
/************************************************************/

wire [NUM_WAYS-1:0] DCACHE_DIRTY_OUT;

wire    [INDEX_WIDTH+WAY_WIDTH-1:0] FINAL_DCACHE_DIRTY_WR_EN;

mux2$   mux2$_FINAL_DCACHE_DIRTY_WR_EN[INDEX_WIDTH+WAY_WIDTH-1:0](FINAL_DCACHE_DIRTY_WR_EN, 
                                                                  {DCC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE],DCACHE_TAG_HIT_WAY_buf16},
                                                                  DCC_VALID_WR_EN,
                                                                  DCC_FSM_VALID_WR_EN_GLOBAL_buf16);

wire    FINAL_DCACHE_DIRTY_WR_EN_GLOBAL;

or2$    or2$_FINAL_DCACHE_DIRTY_WR_EN_GLOBAL(FINAL_DCACHE_DIRTY_WR_EN_GLOBAL, DCC_FSM_VALID_WR_EN_GLOBAL_buf16, STOREQ_STORE_COND_buf1024);

valid_or_dirty_store dcache_dirty_store (
  .clk(clk), .rst(rst),
  .set_index(DCACHE_TAG_SET_buf64),
  .set_or_clr(STOREQ_STORE_COND_buf1024),
  .wr_en(FINAL_DCACHE_DIRTY_WR_EN),
  .wr_en_global(FINAL_DCACHE_DIRTY_WR_EN_GLOBAL),

  .out(DCACHE_DIRTY_OUT)
);

wire  DIRTY_VICTIM;

mux4$   mux4$_DIRTY_VICTIM(DIRTY_VICTIM, DCACHE_DIRTY_OUT[0], DCACHE_DIRTY_OUT[1], DCACHE_DIRTY_OUT[2], DCACHE_DIRTY_OUT[3],
                           DCACHE_VICT_WAY_buf16[0], DCACHE_VICT_WAY_buf16[1]);

/************************************************************/
/********************** STICKY BIT FSM **********************/
/************************************************************/

wire STICKY, FLUSH, FLUSH_BAR, FILL_BUSY_BAR, IO_READ, IO_READ_BAR;

wire IO_READ_AND_NOT_FLUSH, FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ;


wire    D_RD_TLB_CACHE_DISABLE;

wire    MEM_VALID_LOAD_INST_buf16;

bufferH16$    bufferH16$_MEM_VALID_LOAD_INST_buf16(MEM_VALID_LOAD_INST_buf16, MEM_VALID_LOAD_INST);

and2$   and2$_IO_READ(IO_READ, D_RD_TLB_CACHE_DISABLE, MEM_VALID_LOAD_INST_buf16);
nand2$  nand2$_IO_READ_BAR(IO_READ_BAR, D_RD_TLB_CACHE_DISABLE, MEM_VALID_LOAD_INST_buf16);

inv1$   inv1$_FILL_BUSY_BAR(FILL_BUSY_BAR, DCC_FSM_FILL_BUSY);

or2$    or2$_FLUSH(FLUSH, EX_FLUSH, WB_FLUSH);
nor2$   nor2$_FLUSH_BAR(FLUSH_BAR, EX_FLUSH, WB_FLUSH);

/* Wire name is misnomer...should include AND_FILL_BUSY */
nor3$   nor3$_IO_READ_AND_NOT_FLUSH(IO_READ_AND_NOT_FLUSH, IO_READ_BAR, FLUSH, FILL_BUSY_BAR);

wire    NEITHER_BUSY;
nor2$   nor2$_NEITHER_BUSY(NEITHER_BUSY, DCC_FSM_FILL_BUSY, WBE_BUSY);

/* Wire name is misnomer...should be OR_NOT_FILL_BUSY_AND_NOT_WBE_BUSY */
or3$    or3$_FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ(FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ, FLUSH, NEITHER_BUSY, IO_READ_BAR);

sticky_bit_fsm sticky_bit_fsm_STICKY (
  .rst(rst), 
  .clk(clk), 
  .IO_READ_AND_NOT_FLUSH(IO_READ_AND_NOT_FLUSH), 
  .FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ(FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ), 
  .FILL_BUSY(DCC_FSM_FILL_BUSY),
  .STICKY(STICKY)
);

/*********************************************************/
/********************** WBE OUTPUTS **********************/
/*********************************************************/
wire    [TAG_WIDTH-1:0]                       DCACHE_WR_PHYS_TAG_DIRTY;
wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]    DCACHE_WR_PHYS_ADDR_DIRTY, DCACHE_WR_PHYS_ADDR;

wire    WB_VALID_IO_STORE_INST_buf1024;
bufferH1024$    bufferH1024$_WB_VALID_IO_STORE_INST_buf1024(WB_VALID_IO_STORE_INST_buf1024, WB_VALID_IO_STORE_INST);

mux4_8$   mux4_8$_DCACHE_WR_PHYS_TAG_DIRTY( DCACHE_WR_PHYS_TAG_DIRTY, 
                                            DCACHE_TAG_OUT_ALL_WAYS[7:0], DCACHE_TAG_OUT_ALL_WAYS[15:8], 
                                            DCACHE_TAG_OUT_ALL_WAYS[23:16], DCACHE_TAG_OUT_ALL_WAYS[31:24],
                                            DCACHE_VICT_WAY_buf16[0], DCACHE_VICT_WAY_buf16[1]);

assign DCACHE_WR_PHYS_ADDR_DIRTY = {DCACHE_WR_PHYS_TAG_DIRTY, DCC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]};

mux2$   mux2$_DCACHE_WR_PHYS_ADDR[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCACHE_WR_PHYS_ADDR, DCACHE_WR_PHYS_ADDR_DIRTY, WB_PR_ST_ADDR_L0, WB_VALID_IO_STORE_INST_buf1024);

wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCACHE_WR_PHYS_ADDR_buf16;

bufferH16$    bufferH16$_DCACHE_WR_PHYS_ADDR_buf16[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](DCACHE_WR_PHYS_ADDR_buf16, DCACHE_WR_PHYS_ADDR);

mux2_16$   mux2_16$_DCACHE_WR_MASK(DCACHE_WR_MASK, {CHIPS_PER_RANK{1'b0}}, WB_PR_ST_MASK_L0, WB_VALID_IO_STORE_INST_buf1024);

mux2$   mux2$_DCACHE_WBE_DATA[RANK_BIT_WIDTH-1:0](DCACHE_WBE_DATA, DCACHE_RD_DATA, WB_SHF_ST_DATA_L0, WB_VALID_IO_STORE_INST_buf1024);

/************************************************************/
/********************** DCACHE OUTPUTS **********************/
/************************************************************/

wire DCACHE_GENERAL_MISS;
nor2$     nor2$_DCACHE_GENERAL_MISS(DCACHE_GENERAL_MISS, DCACHE_HIT, DCC_STREAM_BUF_HIT);

wire  VALID_CACHE_OPERATION;
or2$      or2$_VALID_CACHE_OPERATION(VALID_CACHE_OPERATION, MEM_VALID_LOAD_INST_buf16, STOREQ_STORING_buf16);

wire  VALID_CACHE_OPERATION_BAR;
nor2$     nor2$_VALID_CACHE_OPERATION_BAR(VALID_CACHE_OPERATION_BAR, MEM_VALID_LOAD_INST_buf16, STOREQ_STORING_buf16);

nor2$   nor2$_DCACHE_MISS(DCACHE_MISS, DCACHE_HIT, VALID_CACHE_OPERATION_BAR);

and2$   and2$_DIRTY_WB_NEEDED(DIRTY_WB_NEEDED, DIRTY_VICTIM, DCACHE_MISS);

wire    DCACHE_MISS_TO_CC;
wire    STOREQ_MISS, MEM_NO_IO_MISS, MEM_IO_MISS;

/* I/O Read misses are based on sticky bit FSM...other misses are based on regular tag compares */
or2$    or2$_DCACHE_MISS_TO_CC(DCACHE_MISS_TO_CC, DCACHE_MISS, MEM_IO_MISS);

or2$    or2$_DCACHE_NEED_WR_BUS(DCACHE_NEED_WR_BUS, DIRTY_WB_NEEDED, WB_VALID_IO_STORE_INST_buf1024);

wire    THREE_STALL_REASONS, WBE_BUSY_REG, DOUBLE_WBE_NOT_BUSY, THIRD_STALL_REASON;

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_WBE_BUSY_REG (
  .clk(clk), .rst(rst),
  .en(1'b1), .d(WBE_BUSY),
  .q(WBE_BUSY_REG)
);

nor2$   nor2$_DOUBLE_WBE_NOT_BUSY(DOUBLE_WBE_NOT_BUSY, WBE_BUSY, WBE_BUSY_REG);
and2$   and2$_THIRD_STALL_REASON(THIRD_STALL_REASON, DOUBLE_WBE_NOT_BUSY, DCACHE_NEED_WR_BUS);

or3$    or3$_THREE_STALL_REASONS(THREE_STALL_REASONS, DCC_FSM_FILL_BUSY, WBE_BUSY, THIRD_STALL_REASON);

/* Importantly, stream buffer hits DO NOT MEAN a STOREQ hit!!! */
wire    STOREQ_LAST_ENTRY_BAR, STOREQ_STALL_CONDITION;
inv1$   inv1$_STOREQ_LAST_ENTRY_BAR(STOREQ_LAST_ENTRY_BAR, STOREQ_LAST_ENTRY);
or2$    or2$_STOREQ_STALL_CONDITION(STOREQ_STALL_CONDITION, DCACHE_MISS, STOREQ_LAST_ENTRY_BAR);
and2$   and2$_STOREQ_MISS(STOREQ_MISS, STOREQ_STORING_buf16, STOREQ_STALL_CONDITION);

and3$   and3$_MEM_NO_IO_MISS(MEM_NO_IO_MISS, MEM_VALID_LOAD_INST_buf16, DCACHE_GENERAL_MISS, D_RD_TLB_CACHE_ENABLE_OUT);

wire    STICKY_BAR;

inv1$   inv1$_D_RD_TLB_CACHE_DISABLE(D_RD_TLB_CACHE_DISABLE, D_RD_TLB_CACHE_ENABLE_OUT);
inv1$   inv1$_STICKY_BAR(STICKY_BAR, STICKY);
and3$   and3$_MEM_IO_MISS(MEM_IO_MISS, MEM_VALID_LOAD_INST_buf16, D_RD_TLB_CACHE_DISABLE, STICKY_BAR);

or4$    or4$_DCACHE_STALL(DCACHE_STALL, THREE_STALL_REASONS, STOREQ_MISS, MEM_NO_IO_MISS, MEM_IO_MISS);

wire DCACHE_VALID_INT;
nor4$   nor4$_DCACHE_VALID_INT(DCACHE_VALID_INT, THREE_STALL_REASONS, STOREQ_MISS, MEM_NO_IO_MISS, MEM_IO_MISS);

and2$   and2$_DCACHE_VALID(DCACHE_VALID, DCACHE_VALID_INT, VALID_CACHE_OPERATION);

wire  STOREQ_STORING_bar;

inv1$   inv1_STOREQ_STORING_bar(STOREQ_STORING_bar, STOREQ_STORING_buf16);

and3$   and3$_DCACHE_HIT_WITH_ACCESS(DCACHE_HIT_WITH_ACCESS, DCACHE_HIT, VALID_CACHE_OPERATION, D_RD_TLB_CACHE_ENABLE_OUT);
and4$   and4$_DCACHE_STREAM_BUF_HIT_WITH_ACCESS(DCACHE_STREAM_BUF_HIT_WITH_ACCESS, DCC_STREAM_BUF_HIT, VALID_CACHE_OPERATION, D_RD_TLB_CACHE_ENABLE_OUT, STOREQ_STORING_bar);


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

wire [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  icache_wr_en_bar_one_hot, icache_wr_en_bar_one_hot_gated, icache_wr_en_bar_one_hot_gated_rst;

bit_duplicator bit_duplicator_icache_wr_en_bar_one_hot(
  .in(ICC_DATA_WR_MASK_OUT),
  .out(icache_wr_en_bar_one_hot)
);

wire  [NUM_WAYS*RANK_BIT_WIDTH-1:0]   ICACHE_RD_DATA_ALL_WAYS;

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  ICC_ADDR_OUT_buf256;

bufferH256$    bufferH256$_ICC_ADDR_OUT_buf256[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](ICC_ADDR_OUT_buf256, ICC_ADDR_OUT);

or3$    or3$_icache_wr_en_bar_one_hot_gated[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](icache_wr_en_bar_one_hot_gated, icache_wr_en_bar_one_hot, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk}}, {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){clk_buf4096}});

mux2$   mux2$_icache_wr_en_bar_one_hot_gated_rst[NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0](
                                                                                                icache_wr_en_bar_one_hot_gated_rst,
                                                                                                {(NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS){1'b1}},
                                                                                                icache_wr_en_bar_one_hot_gated,
                                                                                                rst
                                                                                            );

data_store icache_data_store (
  .set_index(ICC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]),
  .wr_en_bar_one_hot(icache_wr_en_bar_one_hot_gated_rst),
  .data_in(ICC_WR_DATA_OUT),

  .data_out(ICACHE_RD_DATA_ALL_WAYS)
);

/************************************************************/
/************************ TAG  STORE ************************/
/************************************************************/

wire [NUM_WAYS-1:0] ICACHE_VALID_OUT;

wire  [NUM_WAYS*TAG_WIDTH-1:0]        ICACHE_TAG_OUT_ALL_WAYS;

wire     [NUM_WAYS-1:0]                                ICC_TAG_WR_MASK_OUT_gated, ICC_TAG_WR_MASK_OUT_gated_rst;

or2$    or2$_ICC_TAG_WR_MASK_OUT_gated[NUM_WAYS-1:0](ICC_TAG_WR_MASK_OUT_gated, ICC_TAG_WR_MASK_OUT, {(NUM_WAYS){clk}});

mux2$   mux2$_ICC_TAG_WR_MASK_OUT_gated_rst[NUM_WAYS-1:0](
                                                            ICC_TAG_WR_MASK_OUT_gated_rst,
                                                            {NUM_WAYS{1'b1}},
                                                            ICC_TAG_WR_MASK_OUT_gated,
                                                            rst
                                                         );

wire  [RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE] ICACHE_TAG_SET;

wire  ICACHE_TAG_SET_SEL;

wire ICC_FSM_VALID_WR_EN_GLOBAL_REG, ICC_FSM_VALID_WR_EN_GLOBAL_BAR, ICC_FSM_VALID_WR_EN_GLOBAL_buf16;

bufferH16$    bufferH16$_ICC_FSM_VALID_WR_EN_GLOBAL_buf16(ICC_FSM_VALID_WR_EN_GLOBAL_buf16, ICC_FSM_VALID_WR_EN_GLOBAL);

inv1$ inv1$_ICC_FSM_VALID_WR_EN_GLOBAL_BAR(ICC_FSM_VALID_WR_EN_GLOBAL_BAR, ICC_FSM_VALID_WR_EN_GLOBAL_buf16);

dff$  dff$_ICC_FSM_VALID_WR_EN_GLOBAL_REG(clk, ICC_FSM_VALID_WR_EN_GLOBAL_buf16, ICC_FSM_VALID_WR_EN_GLOBAL_REG, , rst, 1'b1);

nor2$ nor2$_ICACHE_TAG_SET_SEL(ICACHE_TAG_SET_SEL, ICC_FSM_VALID_WR_EN_GLOBAL_REG, ICC_FSM_VALID_WR_EN_GLOBAL_BAR);

/* Originally had simply ICC_FSM_VALID_WR_EN_GLOBAL as sel here, but HAD to save 0.2 ns */

wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]    ICACHE_PHYS_ADDR_buf16;

bufferH16$    bufferH16$_ICACHE_PHYS_ADDR_buf16[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](ICACHE_PHYS_ADDR_buf16, ICACHE_PHYS_ADDR);

mux2$   mux2$_ICACHE_TAG_SET[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE](ICACHE_TAG_SET, ICACHE_PHYS_ADDR_buf16[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICC_ADDR_OUT_buf256[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_TAG_SET_SEL);

wire  [RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE] ICACHE_TAG_SET_buf16;

bufferH16$    bufferH16$_ICACHE_TAG_SET_buf16[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE](ICACHE_TAG_SET_buf16, ICACHE_TAG_SET);

wire  [TAG_WIDTH-1:0]   ICC_TAG_IN_buf16;

bufferH16$    bufferH16$_ICC_TAG_IN_buf16[TAG_WIDTH-1:0](ICC_TAG_IN_buf16, ICC_TAG_IN);

tag_store icache_tag_store (
  .set_index(ICACHE_TAG_SET_buf16),
  .wr_en_bar_one_hot(ICC_TAG_WR_MASK_OUT_gated_rst),
  .tag_in(ICC_TAG_IN_buf16),

  .tag_out(ICACHE_TAG_OUT_ALL_WAYS)
);

wire    [NUM_WAYS-1:0]    ICACHE_TAG_HIT, ICACHE_TAG_HIT_FINAL;

wire    [WAY_WIDTH-1:0]   ICACHE_TAG_HIT_WAY, ICACHE_TAG_HIT_WAY_buf16;

bufferH16$    bufferH16$_ICACHE_TAG_HIT_WAY_buf16[WAY_WIDTH-1:0](ICACHE_TAG_HIT_WAY_buf16, ICACHE_TAG_HIT_WAY);

tag_hit_logic tag_hit_logic_ICACHE_TAG_HIT (
  .tag_store_out(ICACHE_TAG_OUT_ALL_WAYS),
  .tag_compare_val(ICC_ADDR_OUT_buf256[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7]),
  .cache_valid_out(ICACHE_VALID_OUT),

  .tag_hit(ICACHE_TAG_HIT),
  .tag_hit_way(ICACHE_TAG_HIT_WAY)
);

mux2$   mux2$_ICACHE_TAG_HIT_FINAL[NUM_WAYS-1:0](ICACHE_TAG_HIT_FINAL, ICACHE_TAG_HIT, {NUM_WAYS{1'b0}}, ICC_FSM_VALID_WR_EN_GLOBAL_buf16);

generate
  for (j = 0; j < 8; j = j + 1) begin : ICACHE_MUX4_16b_GEN
    mux4_16$ mux4_16_ICACHE_RD_DATA (
      .IN0 (ICACHE_RD_DATA_ALL_WAYS[(0*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN1 (ICACHE_RD_DATA_ALL_WAYS[(1*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN2 (ICACHE_RD_DATA_ALL_WAYS[(2*RANK_BIT_WIDTH+j*16) +: 16]),
      .IN3 (ICACHE_RD_DATA_ALL_WAYS[(3*RANK_BIT_WIDTH+j*16) +: 16]),
      .S0(ICACHE_TAG_HIT_WAY_buf16[0]),
      .S1(ICACHE_TAG_HIT_WAY_buf16[1]),
      .Y(ICACHE_RD_DATA[j*16 +: 16])
    );
  end
endgenerate

/************************************************************/
/************************ LRU  STORE ************************/
/************************************************************/

wire    ICACHE_HIT;
wire    ICACHE_HIT_WITH_ACCESS, ICACHE_STREAM_BUF_HIT_WITH_ACCESS, ITLB_NO_PAGE_FAULT_OUT;

lru_store #(.TRUE_LRU(TRUE_LRU)) lru_store_ICACHE_VICT_WAY (
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(ICACHE_TAG_HIT_WAY_buf16),
  .CACHE_HIT(ICACHE_HIT_WITH_ACCESS),
  .CC_ADDR_OUT(ICC_ADDR_OUT_buf256),
  .CC_STREAM_BUF_HIT(ICACHE_STREAM_BUF_HIT_WITH_ACCESS),

  .VICT_WAY(ICACHE_VICT_WAY)
);

/************************************************************/
/*********************** VALID  STORE ***********************/
/************************************************************/

valid_or_dirty_store icache_valid_store (
  .clk(clk), .rst(rst),
  .set_index(ICACHE_TAG_SET_buf16),
  .set_or_clr(ICC_VALID_SET_OR_CLR),
  .wr_en(ICC_VALID_WR_EN),
  .wr_en_global(ICC_FSM_VALID_WR_EN_GLOBAL_buf16),

  .out(ICACHE_VALID_OUT)
);

wire  [NUM_WAYS-1:0]  ICACHE_HIT_ALL_WAYS;

generate 
  for (j = 0; j < NUM_WAYS; j = j + 1) begin : VALID_AND_TAG_HIT_GEN
    and2$   and2$_ICACHE_HIT_ALL_WAYS(ICACHE_HIT_ALL_WAYS[j], ICACHE_TAG_HIT_FINAL[j], ICACHE_VALID_OUT[j]);
  end
endgenerate

mux4$   mux4$_ICACHE_HIT( ICACHE_HIT, 
                          ICACHE_HIT_ALL_WAYS[0], ICACHE_HIT_ALL_WAYS[1], ICACHE_HIT_ALL_WAYS[2], ICACHE_HIT_ALL_WAYS[3],
                          ICACHE_TAG_HIT_WAY_buf16[0], ICACHE_TAG_HIT_WAY_buf16[1]);

nor2$   nor2$_ICACHE_MISS(ICACHE_MISS, ICACHE_HIT, ITLB_PAGE_FAULT_OUT);

/************************************************************/
/********************** ICACHE OUTPUTS **********************/
/************************************************************/

wire ICACHE_GENERAL_MISS;
nor3$     nor3$_ICACHE_GENERAL_MISS(ICACHE_GENERAL_MISS, ICACHE_HIT, ICC_STREAM_BUF_HIT, ITLB_PAGE_FAULT_OUT);

/* 
 * In case X's aren't allowed on ICACHE_VALID ...
 
wire ICACHE_VALID_INT;
nor3$     nor3$_ICACHE_VALID_INT(ICACHE_VALID_INT, ICACHE_GENERAL_MISS, ICC_FSM_FILL_BUSY, ICC_FSM_VALID_WR_EN_GLOBAL_buf16);

mux2$     mux2$_ICACHE_VALID(ICACHE_VALID, ICACHE_VALID_INT, 1'b0, clk);
*/

nor3$     nor3$_ICACHE_VALID_INT(ICACHE_VALID, ICACHE_GENERAL_MISS, ICC_FSM_FILL_BUSY, ICC_FSM_VALID_WR_EN_GLOBAL_buf16);

inv1$     inv1$_ITLB_NO_PAGE_FAULT_OUT(ITLB_NO_PAGE_FAULT_OUT, ITLB_PAGE_FAULT_OUT);
and2$     and2$_ICACHE_HIT_WITH_ACCESS(ICACHE_HIT_WITH_ACCESS, ICACHE_HIT, ITLB_NO_PAGE_FAULT_OUT);
and2$     and2$_ICACHE_STREAM_BUF_HIT_WITH_ACCESS(ICACHE_STREAM_BUF_HIT_WITH_ACCESS, ICC_STREAM_BUF_HIT, ITLB_NO_PAGE_FAULT_OUT);








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
  .KB_PFN                    (KB_PFN_buf16),
  .DMA_PFN                   (DMA_PFN_buf16),
  .DATA_BUS                  (DATA_BUS),
  .ADDR_BUS                  (ADDR_BUS),
  .WR_mask                   (WR_mask),
  .ICACHE_MISS               (ICACHE_MISS),
  .ICACHE_RD_DATA            (ICACHE_RD_DATA),
  .ICACHE_PHYS_ADDR          (ICACHE_PHYS_ADDR_buf16),
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
  .DCACHE_MISS               (DCACHE_MISS_TO_CC),
  .DCACHE_RD_DATA            (DCACHE_RD_DATA),
  .DCACHE_RD_PHYS_ADDR       (DCACHE_PHYS_ADDR_buf16),
  .DCACHE_VICT_WAY           (DCACHE_VICT_WAY_buf16),
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
  .DCACHE_WR_PHYS_ADDR       (DCACHE_WR_PHYS_ADDR_buf16),
  .DCACHE_WR_MASK            (DCACHE_WR_MASK),
  .WBE_BUSY                  (WBE_BUSY),
  .DMA_INT                   (DMA_INT),
  .TEST_CASE_NEW_CHAR        (TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR     (TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY       (TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR    (TEST_CASE_NEW_READY_WR)
);

endmodule