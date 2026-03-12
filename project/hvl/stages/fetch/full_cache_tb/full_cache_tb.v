module full_cache_tb;

initial begin
  $vcdplusfile("full_cache_tb.dump.vpd");
  $vcdpluson(0, full_cache_tb);
  $vcdpluson(0, full_cache_tb.DUT);
  // $vcdpluson(0, full_cache_tb.DUT.icache_tag_store.tag_store_generation[0].ram8b8w$_tag_store_one_way.mem);
end

localparam MEM_BYTE_CAPACITY = 32768;
localparam MEM_ADDR_WIDTH    = $clog2(MEM_BYTE_CAPACITY);
localparam RANK_BIT_WIDTH    = 128;
localparam NUM_WAYS          = 4;
localparam NUM_SETS          = 8;
localparam RANK_BURST_SIZE   = 4;
localparam BYTES_PER_BUS     = 4;
localparam TAG_WIDTH         = 8;
localparam PAGE_SIZE_BYTES   = 4096;
localparam PAGE_BIT_WIDTH    = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH     = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;
localparam CYCLE_TIME_X10    = 100;
localparam CYCLE_TIME        = CYCLE_TIME_X10 / 10.0;
localparam BUS_BIT_WIDTH     = 32;
localparam CHIPS_PER_RANK    = 16;

reg                     clk;
reg                     rst;

reg        [2:0]        KB_PFN;
reg        [2:0]        DMA_PFN;

reg                     STOREQ_STORING;
reg        [RANK_BIT_WIDTH-1:0]  STOREQ_DATA;
reg        [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  STOREQ_DATA_WR_MASK;

reg        [PFN_BIT_WIDTH-1:0]   ITLB_PFN_OUT;
reg                     ITLB_PAGE_FAULT_OUT;

reg        [PFN_BIT_WIDTH-1:0]   D_RD_TLB_PFN_OUT;
reg                     D_RD_TLB_CACHE_ENABLE_OUT;
reg                     D_RD_TLB_PAGE_FAULT_OUT;

reg        [PAGE_BIT_WIDTH-1:0]  F_PAGE_OFFSET;

wire       [RANK_BIT_WIDTH-1:0]  ICACHE_HIT_DATA;
wire                             ICACHE_VALID;

reg        [PAGE_BIT_WIDTH-1:0]  MEM_PAGE_OFFSET;
reg        [1:0]                 MEM_RD_OR_WR_OHE, MEM_EXCEPTION;
reg                              MEM_VALID;

wire       [RANK_BIT_WIDTH-1:0]  DCACHE_HIT_DATA;
wire       [1:0]                 DCACHE_EXCEPTION;
wire                             DCACHE_VALID;
wire                             DCACHE_STALL;

wire                             DMA_INT;

reg        [7:0]                 TEST_CASE_NEW_CHAR, TEST_CASE_NEW_CHAR_WR;
reg                              TEST_CASE_NEW_READY;
reg                              TEST_CASE_NEW_READY_WR;


wire [BUS_BIT_WIDTH-1:0]                DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS;
wire [CHIPS_PER_RANK-1:0]               WR_mask;


full_cache #(
  .MEM_BYTE_CAPACITY         (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10            (CYCLE_TIME_X10),
  .NUM_SETS                  (NUM_SETS),
  .NUM_WAYS                  (NUM_WAYS),
  .TAG_WIDTH                 (TAG_WIDTH)
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

  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

  .F_PAGE_OFFSET(F_PAGE_OFFSET),

  .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
  .ICACHE_VALID(ICACHE_VALID),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_RD_OR_WR_OHE(MEM_RD_OR_WR_OHE),
  .MEM_EXCEPTION(MEM_EXCEPTION),
  .MEM_VALID(MEM_VALID),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_EXCEPTION(DCACHE_EXCEPTION),
  .DCACHE_VALID(DCACHE_VALID),
  .DCACHE_STALL(DCACHE_STALL),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR)
);

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

integer FAILURES = 0;
integer SUCCESSES = 0;


initial begin

  rst = 0;

  DMA_PFN                    <= 3'd1;
  KB_PFN                     <= 3'd3;

  STOREQ_STORING       = 0;
  STOREQ_DATA          = 0;
  STOREQ_DATA_WR_MASK  = 0;

  ITLB_PFN_OUT            = 0;
  ITLB_PAGE_FAULT_OUT     = 0;

  D_RD_TLB_PFN_OUT          = 0;
  D_RD_TLB_CACHE_ENABLE_OUT = 1;
  D_RD_TLB_PAGE_FAULT_OUT   = 0;

  F_PAGE_OFFSET = 0;

  MEM_PAGE_OFFSET = 0;
  MEM_RD_OR_WR_OHE = 0;
  MEM_EXCEPTION = 0;
  MEM_VALID = 0;

  TEST_CASE_NEW_CHAR = 0;
  TEST_CASE_NEW_CHAR_WR = 0;
  TEST_CASE_NEW_READY = 0;
  TEST_CASE_NEW_READY_WR = 0;

  #(1.5 * CYCLE_TIME);
  rst = 1;
  #(20 * CYCLE_TIME);
  
  F_PAGE_OFFSET = 1 << 7;
  #(20 * CYCLE_TIME);

  F_PAGE_OFFSET = 1 << 8;
  #(20 * CYCLE_TIME);


  F_PAGE_OFFSET = 1 << 9;
  #(20 * CYCLE_TIME);

  F_PAGE_OFFSET = 0;
  #(20 * CYCLE_TIME);
  F_PAGE_OFFSET = 1 << 7;
  #(20 * CYCLE_TIME);

  F_PAGE_OFFSET = 1 << 10;
  #(20 * CYCLE_TIME);

  F_PAGE_OFFSET = 1 << 7;
  #(20 * CYCLE_TIME);
  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);


  $finish;

end

endmodule