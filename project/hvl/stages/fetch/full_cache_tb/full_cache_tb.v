module full_cache_tb;

initial begin
  $vcdplusfile("full_cache_tb.dump.vpd");
  $vcdpluson(0, full_cache_tb);
  $vcdpluson(0, full_cache_tb.DUT);
  $vcdpluson(0, full_cache_tb.DUT.icache_tag_store.tag_store_generation[0].ram8b8w$_tag_store_one_way.mem);
  $vcdpluson(0, full_cache_tb.DUT.dcache_data_store.data_store_generation[0].data_position_generation[0].ram8b8w$_data_store_one_bus.mem);
end

localparam MEM_BYTE_CAPACITY   = 32768;
localparam MEM_ADDR_WIDTH      = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH      = 8;
localparam CHIP_BYTE_WIDTH     = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT      = 128;
localparam CHIP_BYTE_CAPACITY  = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT          = MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam BUS_BIT_WIDTH       = 32;
localparam RANK_BIT_WIDTH      = 128;
localparam RANK_BURST_SIZE     = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK      = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY  = CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT          = MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH      = $clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH     = MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam CYCLE_TIME_X10      = 150;
localparam CYCLE_TIME          = CYCLE_TIME_X10/10.0;
localparam BYTES_PER_BUS       = 4;
localparam NUM_SETS            = 8;
localparam INDEX_WIDTH         = $clog2(NUM_SETS);
localparam NUM_WAYS            = 4;
localparam WAY_WIDTH           = $clog2(NUM_WAYS);
localparam TAG_WIDTH           = 8;
localparam PAGE_SIZE_BYTES     = 4096;
localparam PAGE_BIT_WIDTH      = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH       = MEM_ADDR_WIDTH-PAGE_BIT_WIDTH;
localparam TRUE_LRU            = 0;
localparam STOREQ_MASK_WIDTH   = NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS;

reg  clk;
reg  rst;

reg  [2:0]                     KB_PFN;
reg  [2:0]                     DMA_PFN;

wire [BUS_BIT_WIDTH-1:0]       DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0]      ADDR_BUS;
wire [CHIPS_PER_RANK-1:0]      WR_mask;

reg                            STOREQ_STORING;
reg  [RANK_BIT_WIDTH-1:0]      STOREQ_DATA;
reg  [STOREQ_MASK_WIDTH-1:0]   STOREQ_DATA_WR_MASK;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] STOREQ_PHYS_ADDR;

reg  [PFN_BIT_WIDTH-1:0]       ITLB_PFN_OUT;
reg                            ITLB_PAGE_FAULT_OUT;

reg  [PFN_BIT_WIDTH-1:0]       D_RD_TLB_PFN_OUT;
reg                            D_RD_TLB_CACHE_ENABLE_OUT;

reg  [PAGE_BIT_WIDTH-1:0]      F_PAGE_OFFSET;

wire [RANK_BIT_WIDTH-1:0]      ICACHE_HIT_DATA;
wire                           ICACHE_VALID;

reg  [PAGE_BIT_WIDTH-1:0]      MEM_PAGE_OFFSET;
reg                            MEM_VALID_LOAD_INST;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] WB_PR_ST_ADDR_L0;
reg  [CHIPS_PER_RANK-1:0]      WB_PR_ST_MASK_L0;
reg  [RANK_BIT_WIDTH-1:0]      WB_SHF_ST_DATA_L0;
reg                            WB_VALID_IO_STORE_INST;

wire [RANK_BIT_WIDTH-1:0]      DCACHE_HIT_DATA;
wire                           DCACHE_STALL;

wire                           DMA_INT;

reg  [7:0]                     TEST_CASE_NEW_CHAR;
reg  [7:0]                     TEST_CASE_NEW_CHAR_WR;
reg                            TEST_CASE_NEW_READY;
reg                            TEST_CASE_NEW_READY_WR;

reg                            WB_FLUSH;
reg                            EX_FLUSH;

wire  ICACHE_RQ_TAG = {ITLB_PFN_OUT, F_PAGE_OFFSET[11:7]};
wire  ICACHE_RQ_SET = {F_PAGE_OFFSET[6:4]};


integer FAILURES  = 0;
integer SUCCESSES = 0;


full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) DUT (
  .rst(rst),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(STOREQ_STORING),
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
  .DCACHE_STALL(DCACHE_STALL),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),

  .WB_FLUSH(WB_FLUSH),
  .EX_FLUSH(EX_FLUSH)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

integer i, j;

initial begin

  KB_PFN = 3'd1;
  DMA_PFN = 3'd3;

  STOREQ_STORING = 0;
  STOREQ_DATA = 0;
  STOREQ_DATA_WR_MASK = 0;
  STOREQ_PHYS_ADDR = 0;

  ITLB_PFN_OUT = 0;
  ITLB_PAGE_FAULT_OUT = 0;

  D_RD_TLB_PFN_OUT = 0;
  D_RD_TLB_CACHE_ENABLE_OUT = 0;

  F_PAGE_OFFSET = 0;

  MEM_PAGE_OFFSET = 0;
  MEM_VALID_LOAD_INST = 1'b0;

  WB_PR_ST_ADDR_L0 = 0;
  WB_PR_ST_MASK_L0 = 0;
  WB_SHF_ST_DATA_L0 = 0;
  WB_VALID_IO_STORE_INST = 1'b1;

  TEST_CASE_NEW_CHAR = 0;
  TEST_CASE_NEW_CHAR_WR = 0;
  TEST_CASE_NEW_READY = 0;
  TEST_CASE_NEW_READY_WR = 0;

  WB_FLUSH = 0;
  EX_FLUSH = 0;

  rst = 0;
  #(1.5*CYCLE_TIME);
  rst = 1;

  @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  @(posedge clk);

  for (i = 1; i < 2048; i = i + 1) begin
    if (i[10:8] != KB_PFN && i[10:8] != DMA_PFN) begin
      WB_PR_ST_ADDR_L0 = i[10:0];
      WB_SHF_ST_DATA_L0 = {4{17'd0, i[10:0], 4'd0}};
      @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
      @(posedge clk);
    end
  end

  WB_VALID_IO_STORE_INST = 1'b0;

  #(30*CYCLE_TIME);

  {ITLB_PFN_OUT, F_PAGE_OFFSET} = 0;

  #(20 * CYCLE_TIME);

  {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 7);

  #(20 * CYCLE_TIME);

  {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 8);

  #(20 * CYCLE_TIME);

  {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 9);

  #(20 * CYCLE_TIME);



  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);


  $finish;

end

endmodule