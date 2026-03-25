module stage_wb #(
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

  parameter TRUE_LRU=0,
  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,

  parameter NUM_ENTRIES=4,
  parameter PTR_WIDTH=$clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH=PTR_WIDTH+1,
  parameter MULTI_WRITE_AMT=2,

  parameter STORE_DATA_BIT_WIDTH=64,
  parameter TWO_LINES_BIT_WIDTH=2*RANK_BIT_WIDTH,
  parameter TWO_LINES_NUM_BYTES=TWO_LINES_BIT_WIDTH/8,
  parameter TWO_LINES_SHF_AMT_BIT_WIDTH=$clog2(TWO_LINES_NUM_BYTES)
) (
  input                                       clk,
  input                                       rst_n,

  /*** Inputs from pipeline registers (memory-related) ***/
  input   [STORE_DATA_BIT_WIDTH-1:0]          to_wb_store_data,
  input                                       to_wb_store_is_io_line_0,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  to_wb_store_addr_line_0,
  input   [CHIPS_PER_RANK-1:0]                to_wb_store_mask_line_0,
  input                                       to_wb_store_queue_alloc_line_0,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  to_wb_store_addr_line_1,
  input   [CHIPS_PER_RANK-1:0]                to_wb_store_mask_line_1,
  input                                       to_wb_store_queue_alloc_line_1,
  input   [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0]   to_wb_store_data_shf_amt,

  /*** Valid / exception inputs from pipeline registers ***/
  input   [1:0]                               to_wb_exception,
  input                                       to_wb_valid,

  /*** Inputs from full_cache module ***/
  input                                       WBE_BUSY,
  input                                       DCACHE_HIT,
  input                                       DCACHE_STALL,

  /*** Outputs to full_cache module (store-queue-related) ***/
  output                                      STOREQ_STORING,
  output                                      STOREQ_LAST_ENTRY,
  output  [RANK_BIT_WIDTH-1:0]                STOREQ_DATA,
  output  [RANK_BURST_SIZE*BYTES_PER_BUS-1:0] STOREQ_DATA_WR_MASK,
  output  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  STOREQ_PHYS_ADDR,

  /*** Outputs to full_cache module (I/O-store-related) ***/
  output  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  WB_PR_ST_ADDR_L0,
  output  [CHIPS_PER_RANK-1:0]                WB_PR_ST_MASK_L0,
  output  [RANK_BIT_WIDTH-1:0]                WB_SHF_ST_DATA_L0,
  output                                      WB_VALID_IO_STORE_INST,

  /*** Outputs to other stages in the pipeline ***/
  output                                      from_wb_stall_if_mem_en,
  output                                      from_wb_valid_store_inst,
  output                                      from_wb_flush
);

/*** STORE QUEUE "HOOKS" ***/
wire    [MULTI_WRITE_AMT-1:0]               wr;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in0;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in1;

/* Neither page fault exception nor general protection exception */
wire    no_exception;
nor2$   nor2$_no_exception(no_exception, to_wb_exception[0], to_wb_exception[1]);

/* Is a store instruction if it's an I/O store or a D$ store */
wire    wb_store_inst;
or2$    or2$_wb_store_inst(wb_store_inst, to_wb_store_is_io_line_0, to_wb_store_queue_alloc_line_0);

/* Qualify with valid signal & no_exception signal */
and3$   and3$_from_wb_valid_store_inst(from_wb_valid_store_inst, to_wb_valid, no_exception, wb_store_inst);

/* Flush from WB if there's an exception for a valid instruction */
wire    any_exception;
or2$    or2$_any_exception(any_exception, to_wb_exception[0], to_wb_exception[1]);
and2$   and2$_from_wb_flush(from_wb_flush, any_exception, to_wb_valid);

/* 
    This block aligns the 64-bit store data to cache line boundaries.
    Its output is 256 bits because accesses may cross cache lines.
    Two cache lines hold 256 bits of data.
 */
wire    [RANK_BIT_WIDTH-1:0]    store_data_line_0, store_data_line_1;

lshf_bytes_var_256b lshf_bytes_var_256b_store_data (
  .in({192'd0, to_wb_store_data}),
  .shf_amt(to_wb_store_data_shf_amt),
  .out({store_data_line_1, store_data_line_0})
);

/* Format: {data, cache_line_addr, write_mask} */
assign    data_in0 = {store_data_line_0, to_wb_store_addr_line_0, to_wb_store_mask_line_0};
assign    data_in1 = {store_data_line_1, to_wb_store_addr_line_1, to_wb_store_mask_line_1};

/* 
    Qualify store queue enqueue with to_wb_store_is_io_line_0_bar, valid, no_exception.
    Note that any I/O writes will ONLY be in line_0 pipeline registers, as I/O writes
    cannot cross 16B boundaries.
 */
wire    to_wb_store_is_io_line_0_bar;
inv1$   inv1$_to_wb_store_is_io_line_0_bar(to_wb_store_is_io_line_0_bar, to_wb_store_is_io_line_0);

and4$   and4$_wr_0(wr[0], to_wb_store_is_io_line_0_bar, to_wb_store_queue_alloc_line_0, to_wb_valid, no_exception);
and3$   and3$_wr_1(wr[1], to_wb_store_queue_alloc_line_1, to_wb_valid, no_exception);

/*** Easy I/O Write Wires ***/
assign WB_PR_ST_ADDR_L0 = to_wb_store_addr_line_0;
assign WB_PR_ST_MASK_L0 = to_wb_store_mask_line_0;
assign WB_SHF_ST_DATA_L0 = store_data_line_0;
and3$   and3$_WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST, to_wb_store_is_io_line_0, to_wb_valid, no_exception);

wire    stalling_for_store_queue;
and2$   and2$_stalling_for_store_queue(stalling_for_store_queue, DCACHE_STALL, STOREQ_STORING);
or2$    or2$_from_wb_stall_if_mem_en(from_wb_stall_if_mem_en, WB_VALID_IO_STORE_INST, stalling_for_store_queue);

/*** BETWEEN STORE QUEUE & CACHE, for WRITES ***/
wire    WBE_BUSY_BAR;
wire    empty, rd;

inv1$   inv1$_WBE_BUSY_BAR(WBE_BUSY_BAR, WBE_BUSY);

/* Only dequeue when D$ hits and any pending dirty line writebacks are done */
wire    [COUNT_WIDTH-1:0]   entry_count;
and3$   and3$_rd(rd, STOREQ_STORING, DCACHE_HIT, WBE_BUSY_BAR);

/* 
    Right now, we say the store queue MUST store as long as it isn't empty.
    In an optimized design, we can say the store queue stores if:
    (1) The store queue is full
    (2) (a) The store queue is not empty, AND
        (b) There is nothing using the D$ in the memory or writeback stage.
 */
inv1$   inv1$_STOREQ_STORING(STOREQ_STORING, empty);

/* 
   This comparator tells if the store queue has only 1 entry left.
   it allows the D$ to deassert the stall signal 1 cycle early if
   it gets a hit on the last store queue entry
 */
big_eq #(
  .WIDTH(3)
) big_eq_STOREQ_LAST_ENTRY (
  .in0(entry_count), .in1(3'b001),
  .eq(STOREQ_LAST_ENTRY)
);

/* Store Queue Instantiation */
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

endmodule