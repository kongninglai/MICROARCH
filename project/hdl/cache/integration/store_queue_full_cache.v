module store_queue_full_cache #(

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
  
  parameter PHYS_LINE_BIT_WIDTH=MEM_ADDR_WIDTH-RANK_BURST_SIZE,
  parameter BYTES_PER_BUS=4,
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter PAGE_SIZE_BYTES=4096,
  parameter PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES),
  parameter PFN_BIT_WIDTH=MEM_ADDR_WIDTH-PAGE_BIT_WIDTH,

  parameter TRUE_LRU=1,

  /**
    * ORDER (MSB to LSB):
    * 
    * PENDING      - alone
    *
    * DATA         - [154:27]
    * PHYS_ADDR    - [26:16]
    * DATA_WR_MASK - [15:0]
    *
    **/
  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,

  parameter NUM_ENTRIES=4,
  parameter PTR_WIDTH=$clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH=PTR_WIDTH+1,
  parameter MULTI_WRITE_AMT=2
) (
  input                                       rst_n,
                                              clk,
  /*** STORE QUEUE "HOOKS" ***/
  input   [MULTI_WRITE_AMT-1:0]               wr,
  input   [ENTRY_BIT_WIDTH-1:0]               data_in0,
  input   [ENTRY_BIT_WIDTH-1:0]               data_in1,

  /*** BUS SIGNALS ***/               
  inout     [BUS_BIT_WIDTH-1:0]               DATA_BUS,
  inout     [MEM_ADDR_WIDTH-1:0]              ADDR_BUS,
  inout     [CHIPS_PER_RANK-1:0]              WR_mask,  

  input     [PFN_BIT_WIDTH-1:0]               D_RD_TLB_PFN_OUT,
  input     [PAGE_BIT_WIDTH-1:0]              MEM_PAGE_OFFSET,
  input                                       MEM_VALID_LOAD_INST,

  /*** BETWEEN THE PIPELINE REGISTERS & CACHE ***/
  output    [RANK_BIT_WIDTH-1:0]              DCACHE_HIT_DATA,
  output                                      DCACHE_HIT,
  output                                      DCACHE_STALL
);

/*** BETWEEN STORE QUEUE & CACHE, for WRITES ***/
wire                                          WBE_BUSY, WBE_BUSY_BAR;
wire                                          STOREQ_STORING;
wire                                          STOREQ_LAST_ENTRY;
wire    [RANK_BIT_WIDTH-1:0]                  STOREQ_DATA;
wire    [RANK_BURST_SIZE*BYTES_PER_BUS-1:0]   STOREQ_DATA_WR_MASK;
wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]    STOREQ_PHYS_ADDR;

wire    empty, rd;

inv1$   inv1$_WBE_BUSY_BAR(WBE_BUSY_BAR, WBE_BUSY);

wire    [COUNT_WIDTH-1:0]   entry_count;
and3$   and3$_rd(rd, STOREQ_STORING, DCACHE_HIT, WBE_BUSY_BAR);

big_eq #(
  .WIDTH(3)
) big_eq_STOREQ_LAST_ENTRY (
  .in0(entry_count), .in1(3'b001),
  .eq(STOREQ_LAST_ENTRY)
);

store_queue #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)
) store_queue_inst (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .data_in0(data_in0),
  .data_in1(data_in1),
  .empty(empty),
  .full(),
  .entry_count(entry_count),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR)
);

inv1$   inv1$_STOREQ_STORING(STOREQ_STORING, empty);

full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) full_cache_inst (
  .rst(rst_n),
  .clk(clk),

  .KB_PFN(3'd1),
  .DMA_PFN(3'd3),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  .ITLB_PFN_OUT(3'd0),
  .ITLB_PAGE_FAULT_OUT(1'b0),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(1'b1),

  .F_PAGE_OFFSET(12'd0),
  .ICACHE_HIT_DATA(),
  .ICACHE_VALID(),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(11'd0),
  .WB_PR_ST_MASK_L0(16'd0),
  .WB_SHF_ST_DATA_L0(128'd0),
  .WB_VALID_IO_STORE_INST(1'b0),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),
  .WBE_BUSY(WBE_BUSY),

  .DMA_INT(),

  .TEST_CASE_NEW_CHAR(8'd0),
  .TEST_CASE_NEW_CHAR_WR(8'd0),
  .TEST_CASE_NEW_READY(1'b0),
  .TEST_CASE_NEW_READY_WR(1'b0),

  .WB_FLUSH(1'b0),
  .EX_FLUSH(1'b0)
);

endmodule