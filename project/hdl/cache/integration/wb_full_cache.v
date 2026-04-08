module wb_full_cache #(
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
  input   [STORE_DATA_BIT_WIDTH-1:0]          to_wb_store_data,
  input                                       to_wb_store_is_io_line_0,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  to_wb_store_addr_line_0,
  input   [CHIPS_PER_RANK-1:0]                to_wb_store_mask_line_0,
  input                                       to_wb_store_queue_alloc_line_0,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  to_wb_store_addr_line_1,
  input   [CHIPS_PER_RANK-1:0]                to_wb_store_mask_line_1,
  input                                       to_wb_store_queue_alloc_line_1,
  input   [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0]   to_wb_store_data_shf_amt,
  input   [1:0]                               to_wb_exception,
  input                                       to_wb_valid,

  /*** BUS SIGNALS ***/               
  inout     [BUS_BIT_WIDTH-1:0]               DATA_BUS,
  inout     [MEM_ADDR_WIDTH-1:0]              ADDR_BUS,
  inout     [CHIPS_PER_RANK-1:0]              WR_mask,  

  /*** READ SIGNALS TO VERIFY DATA ***/
  input     [PFN_BIT_WIDTH-1:0]               D_RD_TLB_PFN_OUT,
  input     [PAGE_BIT_WIDTH-1:0]              MEM_PAGE_OFFSET,
  input                                       MEM_VALID_LOAD_INST,

  /*** BETWEEN THE PIPELINE REGISTERS & CACHE ***/
  output    [RANK_BIT_WIDTH-1:0]              DCACHE_HIT_DATA,
  output                                      DCACHE_HIT,
  output                                      DCACHE_STALL,

  output                                      from_wb_valid_store_inst,
  output                                      from_wb_flush
);

/*** STORE QUEUE "HOOKS" ***/
wire    [MULTI_WRITE_AMT-1:0]               wr;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in0;
wire    [ENTRY_BIT_WIDTH-1:0]               data_in1;

wire    no_exception;
nor2$   nor2$_no_exception(no_exception, to_wb_exception[0], to_wb_exception[1]);

wire    wb_store_inst;
or2$    or2$_wb_store_inst(wb_store_inst, to_wb_store_is_io_line_0, to_wb_store_queue_alloc_line_0);

and3$   and3$_from_wb_valid_store_inst(from_wb_valid_store_inst, to_wb_valid, no_exception, wb_store_inst);

assign  from_wb_flush = 1'b0;

wire    [RANK_BIT_WIDTH-1:0]    store_data_line_0, store_data_line_1;

lshf_bytes_var_256b lshf_bytes_var_256b_store_data (
  .in({192'd0, to_wb_store_data}),
  .shf_amt(to_wb_store_data_shf_amt),
  .out({store_data_line_1, store_data_line_0})
);

assign    data_in0 = {store_data_line_0, to_wb_store_addr_line_0, to_wb_store_mask_line_0};
assign    data_in1 = {store_data_line_1, to_wb_store_addr_line_1, to_wb_store_mask_line_1};

wire    to_wb_store_is_io_line_0_bar;
inv1$   inv1$_to_wb_store_is_io_line_0_bar(to_wb_store_is_io_line_0_bar, to_wb_store_is_io_line_0);

and4$   and4$_wr_0(wr[0], to_wb_store_is_io_line_0_bar, to_wb_store_queue_alloc_line_0, to_wb_valid, no_exception);
and3$   and3$_wr_1(wr[1], to_wb_store_queue_alloc_line_1, to_wb_valid, no_exception);

store_queue_full_cache #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME_X10(CYCLE_TIME_X10), .TRUE_LRU(TRUE_LRU)
) store_queue_full_cache_inst (
  .rst_n(rst_n),
  .clk(clk),
  .wr(wr),
  .data_in0(data_in0),
  .data_in1(data_in1),
  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),
  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL)
);

endmodule