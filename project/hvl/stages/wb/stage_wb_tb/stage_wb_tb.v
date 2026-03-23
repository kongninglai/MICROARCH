module stage_wb_tb;

initial begin
  $vcdplusfile("stage_wb_tb.dump.vpd");
  $vcdpluson(0, stage_wb_tb);
  $vcdpluson(0, stage_wb_tb.DUT);
end

localparam MEM_BYTE_CAPACITY    = 32768;
localparam MEM_ADDR_WIDTH       = $clog2(MEM_BYTE_CAPACITY);

localparam CHIP_BIT_WIDTH       = 8;
localparam CHIP_BYTE_WIDTH      = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT       = 128;
localparam CHIP_BYTE_CAPACITY   = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT           = MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;

localparam BUS_BIT_WIDTH        = 32;
localparam RANK_BIT_WIDTH       = 128;
localparam RANK_BURST_SIZE      = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK       = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;

localparam RANK_BYTE_CAPACITY   = CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT           = MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH       = $clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH      = MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);

localparam PHYS_LINE_BIT_WIDTH  = MEM_ADDR_WIDTH-RANK_BURST_SIZE;
localparam BYTES_PER_BUS        = 4;
localparam NUM_SETS             = 8;
localparam INDEX_WIDTH          = $clog2(NUM_SETS);
localparam NUM_WAYS             = 4;
localparam WAY_WIDTH            = $clog2(NUM_WAYS);
localparam TAG_WIDTH            = 8;

localparam PAGE_SIZE_BYTES      = 4096;
localparam PAGE_BIT_WIDTH       = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH        = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;

localparam ENTRY_BIT_WIDTH      = CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH;

localparam NUM_ENTRIES          = 4;
localparam PTR_WIDTH            = $clog2(NUM_ENTRIES);
localparam COUNT_WIDTH          = PTR_WIDTH+1;
localparam MULTI_WRITE_AMT      = 2;

localparam STORE_DATA_BIT_WIDTH = 64;
localparam TWO_LINES_BIT_WIDTH  = 2*RANK_BIT_WIDTH;
localparam TWO_LINES_NUM_BYTES  = TWO_LINES_BIT_WIDTH/8;
localparam TWO_LINES_SHF_AMT_BIT_WIDTH = $clog2(TWO_LINES_NUM_BYTES);

localparam CYCLE_TIME_X10       = 98;
localparam TRUE_LRU             = 1;
localparam CYCLE_TIME           = CYCLE_TIME_X10 / 10.0;

reg clk;
reg rst_n;

reg  [STORE_DATA_BIT_WIDTH-1:0] to_wb_store_data;
reg                             to_wb_store_is_io_line_0;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] to_wb_store_addr_line_0;
reg  [CHIPS_PER_RANK-1:0]               to_wb_store_mask_line_0;
reg                                     to_wb_store_queue_alloc_line_0;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] to_wb_store_addr_line_1;
reg  [CHIPS_PER_RANK-1:0]               to_wb_store_mask_line_1;
reg                                     to_wb_store_queue_alloc_line_1;

reg  [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] to_wb_store_data_shf_amt;
reg  [1:0]  to_wb_exception;
reg         to_wb_valid;

wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [CHIPS_PER_RANK-1:0] WR_mask;

reg  [PFN_BIT_WIDTH-1:0] D_RD_TLB_PFN_OUT;
reg                      D_RD_TLB_CACHE_ENABLE_OUT;
reg  [PAGE_BIT_WIDTH-1:0] MEM_PAGE_OFFSET;

reg  [PAGE_BIT_WIDTH-1:0] F_PAGE_OFFSET;
wire [RANK_BIT_WIDTH-1:0] ICACHE_HIT_DATA;
wire                      ICACHE_VALID;

reg  MEM_VALID_LOAD_INST;

wire [RANK_BIT_WIDTH-1:0] DCACHE_HIT_DATA;
wire WBE_BUSY;
wire DCACHE_HIT;
wire DCACHE_STALL;

wire DMA_INT;

reg  [7:0]                     TEST_CASE_NEW_CHAR;
reg  [7:0]                     TEST_CASE_NEW_CHAR_WR;
reg                            TEST_CASE_NEW_READY;
reg                            TEST_CASE_NEW_READY_WR;

wire                                      STOREQ_STORING;
wire                                      STOREQ_LAST_ENTRY;
wire  [RANK_BIT_WIDTH-1:0]                STOREQ_DATA;
wire  [RANK_BURST_SIZE*BYTES_PER_BUS-1:0] STOREQ_DATA_WR_MASK;
wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  STOREQ_PHYS_ADDR;
wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  WB_PR_ST_ADDR_L0;
wire  [CHIPS_PER_RANK-1:0]                WB_PR_ST_MASK_L0;
wire  [RANK_BIT_WIDTH-1:0]                WB_SHF_ST_DATA_L0;
wire                                      WB_VALID_IO_STORE_INST;

reg  [PFN_BIT_WIDTH-1:0]       ITLB_PFN_OUT;
reg                            ITLB_PAGE_FAULT_OUT;

wire from_wb_stall_if_mem_en;
wire from_wb_valid_store_inst;
wire from_wb_flush;
reg  EX_FLUSH;

reg [PFN_BIT_WIDTH-1:0] KB_PFN, DMA_PFN;

integer FAILURES  = 0;
integer SUCCESSES = 0;

stage_wb #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10),
  .TRUE_LRU(TRUE_LRU)
) DUT (
  .clk(clk),
  .rst_n(rst_n),

  .to_wb_store_data(to_wb_store_data),
  .to_wb_store_is_io_line_0(to_wb_store_is_io_line_0),

  .to_wb_store_addr_line_0(to_wb_store_addr_line_0),
  .to_wb_store_mask_line_0(to_wb_store_mask_line_0),
  .to_wb_store_queue_alloc_line_0(to_wb_store_queue_alloc_line_0),

  .to_wb_store_addr_line_1(to_wb_store_addr_line_1),
  .to_wb_store_mask_line_1(to_wb_store_mask_line_1),
  .to_wb_store_queue_alloc_line_1(to_wb_store_queue_alloc_line_1),

  .to_wb_store_data_shf_amt(to_wb_store_data_shf_amt),
  .to_wb_exception(to_wb_exception),
  .to_wb_valid(to_wb_valid),

  .WBE_BUSY(WBE_BUSY),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .from_wb_stall_if_mem_en(from_wb_stall_if_mem_en),
  .from_wb_valid_store_inst(from_wb_valid_store_inst),
  .from_wb_flush(from_wb_flush)
);

full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) full_cache_inst (
  .rst(rst_n),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),

  .F_PAGE_OFFSET(F_PAGE_OFFSET),
  .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
  .ICACHE_VALID(ICACHE_VALID),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),
  .WBE_BUSY(WBE_BUSY),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),

  .WB_FLUSH(from_wb_flush),
  .EX_FLUSH(EX_FLUSH)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

integer rand_int;

initial begin
  ITLB_PFN_OUT = 0;
  ITLB_PAGE_FAULT_OUT = 0;
  F_PAGE_OFFSET = 0;
  #(0.5 * CYCLE_TIME);
  forever begin
    #(200 * CYCLE_TIME);
    rand_int = $random;
    F_PAGE_OFFSET = {rand_int[10:0], 4'd0};
  end
end


task reset_dut;
begin
  rst_n = 0;

  KB_PFN = 3'd1;
  DMA_PFN = 3'd3;

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
  to_wb_store_data = 0;

  to_wb_store_is_io_line_0 = 0;
  to_wb_store_data_shf_amt = 0;
  to_wb_exception = 2'b00;
  to_wb_valid = 1'b1;

  D_RD_TLB_PFN_OUT = 0;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b1;
  MEM_PAGE_OFFSET = 0;
  MEM_VALID_LOAD_INST = 0;

  TEST_CASE_NEW_CHAR = 0;
  TEST_CASE_NEW_CHAR_WR = 0;
  TEST_CASE_NEW_READY = 0;
  TEST_CASE_NEW_READY_WR = 0;

  EX_FLUSH = 0;

  #(2*CYCLE_TIME);
  rst_n = 1;
  #(1.5*CYCLE_TIME);
end
endtask

task write_entry;
  input integer addr0;
  input integer addr1;
  input [1:0]  mode;
begin
  to_wb_store_data = {(addr0 << 4), (addr0 << 4)};

  to_wb_store_addr_line_0 = addr0;
  to_wb_store_mask_line_0 = 16'hFF00;
  to_wb_store_queue_alloc_line_0 = mode[0];

  to_wb_store_addr_line_1 = addr1;
  to_wb_store_mask_line_1 = 16'hFF00;
  to_wb_store_queue_alloc_line_1 = mode[1];

  #(CYCLE_TIME);

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
end
endtask

task write_entry_custom;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr0;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr1;
  input [CHIPS_PER_RANK-1:0]  mask0;
  input [CHIPS_PER_RANK-1:0]  mask1;
  input [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] shf_amt;
  input [1:0]  mode;
  input [STORE_DATA_BIT_WIDTH-1:0] data;
begin
  to_wb_store_data = data;

  to_wb_store_addr_line_0 = addr0;
  to_wb_store_mask_line_0 = mask0;
  to_wb_store_queue_alloc_line_0 = mode[0];

  to_wb_store_addr_line_1 = addr1;
  to_wb_store_mask_line_1 = mask1;
  to_wb_store_queue_alloc_line_1 = mode[1];

  to_wb_store_data_shf_amt = shf_amt;

  #(CYCLE_TIME);

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
  to_wb_store_data_shf_amt = 0;
end
endtask

task check_dcache_write_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr;
begin
  if (DCACHE_HIT_DATA !== {{64{1'bX}}, {2{{16{1'b0}}, 1'b0, addr, 4'd0}}}) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, {{64{1'bX}}, {2{{16{1'b0}}, 1'b0, addr, 4'd0}}}, DCACHE_HIT_DATA);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

task check_dcache_write_data_custom;
  input [RANK_BIT_WIDTH-1:0] data;
begin
  if (DCACHE_HIT_DATA !== data) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, data, DCACHE_HIT_DATA);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;

integer rand_dcache_addr;

initial begin
  reset_dut();

  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== KB_PFN && 
        i[10:8] !== DMA_PFN) begin
      j = i + 1;

      if (~DCACHE_STALL) begin
        write_entry(i, j, 2'b01);
      end else begin
        i = i - 1;
        #(CYCLE_TIME);
      end
      #(CYCLE_TIME);
    end
  end

  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end

  for (i = 0; i < 2048; i = i + 1) begin
    MEM_VALID_LOAD_INST = 1'b1;
    D_RD_TLB_CACHE_ENABLE_OUT = 1'b1;
    if (i[10:8] !== KB_PFN && 
        i[10:8] !== DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
      #(CYCLE_TIME);
      while (DCACHE_STALL === 1'b1) begin
        #(CYCLE_TIME);
      end
      check_dcache_write_data(i[10:0]);
    end
  end

  MEM_VALID_LOAD_INST = 1'b0;

  #(10 * CYCLE_TIME);

  for (i = 0; i < 128; i = i + 1) begin
    rand_dcache_addr = $random;
    if (rand_dcache_addr[10:8] !== KB_PFN && 
        rand_dcache_addr[10:8] !== DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {rand_dcache_addr[10:0], 4'b0000};
      D_RD_TLB_CACHE_ENABLE_OUT = 1'b1;
      MEM_VALID_LOAD_INST = 1'b1;
      #(CYCLE_TIME);
      while (DCACHE_STALL === 1'b1) begin
        #(CYCLE_TIME);
      end
      check_dcache_write_data(rand_dcache_addr[10:0]);
    end
  end

  MEM_VALID_LOAD_INST = 1'b0;

  #(20 * CYCLE_TIME);

  

  // write_entry_custom(addr0, addr1, mask0, mask1, shf_amt, mode, data);

  write_entry_custom(11'd0, 11'd1, 16'h01FF, 16'hFFFE, 5'd9, 2'b11, 64'h6767676767676767);

  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end

  for (i = 0; i < 2; i = i + 1) begin
    MEM_VALID_LOAD_INST = 1'b1;
    {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
    #(CYCLE_TIME);
    while (DCACHE_STALL === 1'b1) begin
      #(CYCLE_TIME);
    end
    if (i == 0) begin
      check_dcache_write_data_custom(128'h67676767676767XX0000000000000000);
    end else begin
      check_dcache_write_data_custom(128'hXXXXXXXXXXXXXXXX0000001000000067);
    end
  end

  /* KB Enable */
  to_wb_store_addr_line_0 = {KB_PFN, 8'b00000010};
  to_wb_store_mask_line_0 = 16'hFFFE;
  to_wb_store_data = 64'd1;
  to_wb_store_is_io_line_0 = 1'b1;

  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  to_wb_store_is_io_line_0 = 1'b0;

  TEST_CASE_NEW_CHAR = 8'h67;
  TEST_CASE_NEW_CHAR_WR = {8{1'b1}};
  TEST_CASE_NEW_READY = 1'b1;
  TEST_CASE_NEW_READY_WR = 1'b1;

  #(CYCLE_TIME);

  TEST_CASE_NEW_CHAR = 8'h55;
  TEST_CASE_NEW_CHAR_WR = {8{1'b0}};
  TEST_CASE_NEW_READY = 1'b0;
  TEST_CASE_NEW_READY_WR = 1'b0;

  #(CYCLE_TIME);

  /* KB READ */
  MEM_VALID_LOAD_INST = 1'b1;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b0;
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_dcache_write_data_custom({64'd1, 64'd1});
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000101, 4'b0000};
  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_dcache_write_data_custom(128'd103); // 0x67 = 103
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_dcache_write_data_custom(128'd1); // Self-clearing ready
  MEM_VALID_LOAD_INST = 1'b0;

  /* DMA CONFIG INIT */
  to_wb_store_addr_line_0 = {DMA_PFN, 8'd1};
  to_wb_store_mask_line_0 = 16'hFF00;
  to_wb_store_data = {32'h00000067, 32'hFFFFFF67};
  to_wb_store_is_io_line_0 = 1'b1;
  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  to_wb_store_addr_line_0 = {DMA_PFN, 8'd1};
  to_wb_store_mask_line_0 = 16'h00FF;
  to_wb_store_data_shf_amt = 5'd8;
  to_wb_store_data = {32'd1, 32'd3988};
  to_wb_store_is_io_line_0 = 1'b1;
  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end
  to_wb_store_is_io_line_0 = 1'b0;
  to_wb_store_data_shf_amt = 0;
  
  @(posedge DMA_INT);
  @(posedge clk);
  #(10 * CYCLE_TIME);

  /*** END I/O TEST ***/

  #(50 * CYCLE_TIME);

  if (from_wb_flush !== 1'b0) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: FLUSH exp=%h got=%h", $time, 1'b0, from_wb_flush);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end

  to_wb_exception = 2'd1;

  #(CYCLE_TIME);

  if (from_wb_flush !== 1'b1) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: FLUSH exp=%h got=%h", $time, 1'b1, from_wb_flush);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end

  to_wb_valid = 1'b0;

  #(CYCLE_TIME);

  if (from_wb_flush !== 1'b0) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: FLUSH exp=%h got=%h", $time, 1'b0, from_wb_flush);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end

  #(CYCLE_TIME);

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule