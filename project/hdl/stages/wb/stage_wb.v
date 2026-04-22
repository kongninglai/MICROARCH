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

  parameter TRUE_LRU=1,
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

  /*** Inputs from pipeline registers (execute-related) ***/
  input   [16:0]                              to_wb_control_sigs,
  input   [2:0]                               to_wb_dstidA, 
  input   [2:0]                               to_wb_dstidB,
  input   [31:0]                              to_wb_gp_wr_data_1,
  input   [31:0]                              to_wb_gp_wr_data_2,
  input   [15:0]                              to_wb_seg_wr_data,
  input   [63:0]                              to_wb_mmx_wr_data,
  input   [31:0]                              to_wb_oeip,
  input   [31:0]                              to_wb_ieip,
  input   [15:0]                              to_wb_cs,

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

  /*** Outputs to regunit module (register-related) ***/
  output  [2:0]                               from_wb_gpwr0_idx,
  output  [31:0]                              from_wb_gpwr0_data,
  output  [1:0]                               from_wb_gpwr0_size,
  output                                      from_wb_gpwr0_en,
  output  [2:0]                               from_wb_gpwr1_idx,
  output  [31:0]                              from_wb_gpwr1_data,
  output  [1:0]                               from_wb_gpwr1_size,
  output                                      from_wb_gpwr1_en,
  output  [2:0]                               from_wb_segwr_idx,
  output  [15:0]                              from_wb_segwr_data,
  output                                      from_wb_segwr_en,
  output  [2:0]                               from_wb_mmxwr_idx,
  output  [63:0]                              from_wb_mmxwr_data,
  output                                      from_wb_mmxwr_en,

  /*** Outputs to temp registers (exception-related) ***/
  output  [15:0]                              from_wb_temp_cs,
  output  [31:0]                              from_wb_temp_eip,
  output  [1:0]                               from_wb_temp_exception,

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
  output                                      from_wb_flush,

  input                                       DMA_INT
);

assign from_wb_temp_cs = to_wb_cs;
assign from_wb_temp_exception = to_wb_exception;

/*** REGFILE UPDATE LOGIC ***/
wire gpwr0_en, gp_wr1_en, segwr_en, mmxwr_en;
wire movs0, movs1, cmps0, cmps1, cmps2;

wire [1:0] dstA_size, dstB_size, rw, ds;
wb_sig dut_wb_sig(
    .ucode_sig(to_wb_control_sigs),
    .gpwr0_en(gpwr0_en),
    .gpwr1_en(gpwr1_en),
    .segwr_en(segwr_en),
    .mmxwr_en(mmxwr_en),
    .dstA_size(dstA_size),
    .dstB_size(dstB_size),
    .rw(rw),
    .ds(ds),
    .movs0(movs0),
    .movs1(movs1),
    .cmps0(cmps0),
    .cmps1(cmps1),
    .cmps2(cmps2)
);

bufferH256$ bufferH256$_from_wb_gpwr0_idx[2:0](from_wb_gpwr0_idx, to_wb_dstidA);
bufferH256$ bufferH256$_from_wb_gpwr0_data[31:0](from_wb_gpwr0_data, to_wb_gp_wr_data_1);
bufferH64$  bufferH64$_from_wb_gpwr0_en(from_wb_gpwr0_en, gpwr0_en);
bufferH64$  bufferH64$_from_wb_gpwr0_size[1:0](from_wb_gpwr0_size, dstA_size);
wire clear_int, pending_int;
pending_int pending_int_inst(
    .clk(clk),
    .rst_n(rst_n),
    .set_int(DMA_INT),
    .clear_int(clear_int),
    .pending_int(pending_int)
); 

bufferH64$ bufferH64$_from_wb_gpwr1_idx[2:0](from_wb_gpwr1_idx, to_wb_dstidB);
bufferH256$ bufferH256$_from_wb_gpwr1_data[31:0](from_wb_gpwr1_data, to_wb_gp_wr_data_2);
bufferH64$  bufferH64$_from_wb_gpwr1_en(from_wb_gpwr1_en, gpwr1_en);
bufferH64$  bufferH64$_from_wb_gpwr1_size[1:0](from_wb_gpwr1_size, dstB_size);

bufferH64$  bufferH64$_from_wb_segwr_idx[2:0](from_wb_segwr_idx, to_wb_dstidA);
bufferH16$  bufferH16$_from_wb_segwr_data[15:0](from_wb_segwr_data, to_wb_seg_wr_data);
bufferH16$  bufferH16$_from_wb_segwr_en(from_wb_segwr_en, segwr_en);

assign from_wb_mmxwr_idx = to_wb_dstidA;
bufferH16$  bufferH16$_from_wb_mmxwr_data[63:0](from_wb_mmxwr_data, to_wb_mmx_wr_data);
bufferH16$  bufferH16$_from_wb_mmxwr_en(from_wb_mmxwr_en, mmxwr_en);

wire to_wb_valid_buf16;
bufferH16$  bufferH16$_to_wb_valid_buf16(to_wb_valid_buf16, to_wb_valid);

wire pending_int_bar, movs0_bar, cmps0_bar, cmps1_bar, wb_valid_buf16_bar;
inv1$ inv_pending_int(pending_int_bar, pending_int);
inv1$ inv_movs0(movs0_bar,movs0);
inv1$ inv_cmps0(cmps0_bar, cmps0);
inv1$ inv_cmps1(cmps1_bar, cmps1);
big_and #(.WIDTH(5)) big_and_clear_int(clear_int, {pending_int, to_wb_valid_buf16, movs0_bar, cmps0_bar, cmps1_bar});

/*** STORE QUEUE "HOOKS" ***/
wire    [MULTI_WRITE_AMT-1:0]               wr, wr_buf16;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in0;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in1;

bufferH16$    bufferH16$_wr_buf16[MULTI_WRITE_AMT-1:0](wr_buf16, wr);

/* Neither page fault exception nor general protection exception */
wire    no_exception;
nor2$   nor2$_no_exception(no_exception, to_wb_exception[0], to_wb_exception[1]);

/* Is a store instruction if it's an I/O store or a D$ store */
wire    wb_store_inst;
or2$    or2$_wb_store_inst(wb_store_inst, to_wb_store_is_io_line_0, to_wb_store_queue_alloc_line_0);

/* Qualify with valid signal & no_exception signal */
and3$   and3$_from_wb_valid_store_inst(from_wb_valid_store_inst, to_wb_valid_buf16, no_exception, wb_store_inst);

/* Flush from WB if there's an exception for a valid instruction */
wire    any_exception_or_interrupt, any_interrupt;
nor4$   nor4_any_interrupt(any_interrupt, pending_int_bar, movs0, cmps0, cmps1);
or3$    or2$_any_exception_or_interrupt(any_exception_or_interrupt, to_wb_exception[0], to_wb_exception[1], any_interrupt);
wire from_wb_flush_bar;
nand2$   nand2$_from_wb_flush_bar(from_wb_flush_bar, any_exception_or_interrupt, to_wb_valid_buf16);
    bufferHInv64$ bufferHInv64$_from_wb_flush(from_wb_flush, from_wb_flush_bar);

mux2_32 mux2_temp_eip(from_wb_temp_eip, to_wb_oeip, to_wb_ieip, any_interrupt);
/* 
    This block aligns the 64-bit store data to cache line boundaries.
    Its output is 256 bits because accesses may cross cache lines.
    Two cache lines hold 256 bits of data.
 */
wire    [RANK_BIT_WIDTH-1:0]    store_data_line_0, store_data_line_1;

wire    [TWO_LINES_BIT_WIDTH-1:0] shifter_input;
bufferH64$    bufferH64$_shifter_input[TWO_LINES_BIT_WIDTH-1:0](shifter_input, {192'd0, to_wb_store_data});

lshf_bytes_var_256b lshf_bytes_var_256b_store_data (
  .in(shifter_input),
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

and4$   and4$_wr_0(wr[0], to_wb_store_is_io_line_0_bar, to_wb_store_queue_alloc_line_0, to_wb_valid_buf16, no_exception);
and3$   and3$_wr_1(wr[1], to_wb_store_queue_alloc_line_1, to_wb_valid_buf16, no_exception);

/*** Easy I/O Write Wires ***/
assign WB_PR_ST_ADDR_L0 = to_wb_store_addr_line_0;
assign WB_PR_ST_MASK_L0 = to_wb_store_mask_line_0;
assign WB_SHF_ST_DATA_L0 = store_data_line_0;
and3$   and3$_WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST, to_wb_store_is_io_line_0, to_wb_valid_buf16, no_exception);

or3$    or3$_from_wb_stall_if_mem_en(from_wb_stall_if_mem_en, WB_VALID_IO_STORE_INST, STOREQ_STORING, WBE_BUSY);

/*** BETWEEN STORE QUEUE & CACHE, for WRITES ***/
wire    WBE_BUSY_BAR;
wire    empty, rd, rd_buf16;

bufferH16$    bufferH16$_rd_buf16(rd_buf16, rd);

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
  .wr(wr_buf16),
  .rd(rd_buf16),
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