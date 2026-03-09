module full_cc_off_core_tb;

initial begin
    $vcdplusfile("full_cc_off_core_tb.dump.vpd");
    $vcdpluson(0, full_cc_off_core_tb);
    $vcdpluson(0, full_cc_off_core_tb.DUT);
end

localparam MEM_BYTE_CAPACITY            = 32768;
localparam MEM_ADDR_WIDTH               = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH               = 8;
localparam CHIP_BYTE_WIDTH              = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT               = 128;
localparam CHIP_BYTE_CAPACITY           = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT                   = MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam BUS_BIT_WIDTH                = 32;
localparam RANK_BIT_WIDTH               = 128;
localparam RANK_BURST_SIZE              = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK               = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY           = CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT                   = MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH               = $clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH              = MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam CYCLE_TIME_X10               = 100;
localparam NUM_SETS                     = 8;
localparam INDEX_WIDTH                  = $clog2(NUM_SETS);
localparam NUM_WAYS                     = 4;
localparam WAY_WIDTH                    = $clog2(NUM_WAYS);
localparam TAG_WIDTH                    = 8;
localparam MASK_WIDTH                   = NUM_SETS * NUM_WAYS * RANK_BURST_SIZE;
localparam CYCLE_TIME                   = CYCLE_TIME_X10 / 10.0;

reg                                     clk;
reg                                     rst;
reg  [2:0]                              KB_PFN, DMA_PFN;

reg  [BUS_BIT_WIDTH-1:0]                DATA_driver;
reg                                     DATA_driver_enable;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};

reg  [MEM_ADDR_WIDTH-1:0]               ADDR_driver;
reg                                     ADDR_driver_enable;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {MEM_ADDR_WIDTH{1'bz}};

reg  [CHIPS_PER_RANK-1:0]               WR_mask_driver;
reg                                     WR_mask_driver_enable;
wire [CHIPS_PER_RANK-1:0]               WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {CHIPS_PER_RANK{1'bz}};

reg                                     ICACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]               ICACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                    ICACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]                   ICC_DATA_WR_MASK_DEFAULT;

wire                                    ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]               ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICC_ADDR_OUT;
wire [MASK_WIDTH-1:0]                   ICC_DATA_WR_MASK_OUT;
wire [INDEX_WIDTH-1:0]                  ICC_TAG_VALID_SET_INDEX;
wire [NUM_WAYS-1:0]                     ICC_TAG_WR_MASK_OUT;
wire [TAG_WIDTH-1:0]                    ICC_TAG_IN;
wire                                    ICC_VALID_SET_OR_CLR;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]        ICC_VALID_WR_EN;
wire                                    ICC_FSM_VALID_WR_EN_GLOBAL;

reg                                     DCACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]               DCACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCACHE_RD_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                    DCACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]                   DCC_DATA_WR_MASK_DEFAULT;

wire                                    DCC_STREAM_BUF_HIT, DCC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]               DCC_WR_DATA_OUT, DCC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCC_ADDR_OUT;
wire [MASK_WIDTH-1:0]                   DCC_DATA_WR_MASK_OUT;
wire [INDEX_WIDTH-1:0]                  DCC_TAG_VALID_SET_INDEX;
wire [NUM_WAYS-1:0]                     DCC_TAG_WR_MASK_OUT;
wire [TAG_WIDTH-1:0]                    DCC_TAG_IN;
wire                                    DCC_VALID_SET_OR_CLR;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]        DCC_VALID_WR_EN;
wire                                    DCC_FSM_VALID_WR_EN_GLOBAL;

reg                                     DCACHE_NEED_WR_BUS;
reg  [RANK_BIT_WIDTH-1:0]               DCACHE_WBE_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCACHE_WR_PHYS_ADDR;
reg  [CHIPS_PER_RANK-1:0]               DCACHE_WR_MASK;
wire                                    WBE_BUSY;
wire                                    DMA_INT;

initial begin
    clk = 0;
    forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

full_cc_off_core #(
  .MEM_BYTE_CAPACITY         (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10            (CYCLE_TIME_X10),
  .NUM_SETS                  (NUM_SETS),
  .NUM_WAYS                  (NUM_WAYS),
  .TAG_WIDTH                 (TAG_WIDTH)
) DUT (
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
  .ICC_DATA_WR_MASK_DEFAULT  (ICC_DATA_WR_MASK_DEFAULT),
  .ICC_STREAM_BUF_HIT        (ICC_STREAM_BUF_HIT),
  .ICC_FSM_FILL_BUSY         (ICC_FSM_FILL_BUSY),
  .ICC_WR_DATA_OUT           (ICC_WR_DATA_OUT),
  .ICC_HIT_DATA_OUT          (ICC_HIT_DATA_OUT),
  .ICC_ADDR_OUT              (ICC_ADDR_OUT),
  .ICC_DATA_WR_MASK_OUT      (ICC_DATA_WR_MASK_OUT),
  .ICC_TAG_VALID_SET_INDEX   (ICC_TAG_VALID_SET_INDEX),
  .ICC_TAG_WR_MASK_OUT       (ICC_TAG_WR_MASK_OUT),
  .ICC_TAG_IN                (ICC_TAG_IN),
  .ICC_VALID_SET_OR_CLR      (ICC_VALID_SET_OR_CLR),
  .ICC_VALID_WR_EN           (ICC_VALID_WR_EN),
  .ICC_FSM_VALID_WR_EN_GLOBAL(ICC_FSM_VALID_WR_EN_GLOBAL),
  .DCACHE_MISS               (DCACHE_MISS),
  .DCACHE_RD_DATA            (DCACHE_RD_DATA),
  .DCACHE_RD_PHYS_ADDR       (DCACHE_RD_PHYS_ADDR),
  .DCACHE_VICT_WAY           (DCACHE_VICT_WAY),
  .DCC_DATA_WR_MASK_DEFAULT  (DCC_DATA_WR_MASK_DEFAULT),
  .DCC_STREAM_BUF_HIT        (DCC_STREAM_BUF_HIT),
  .DCC_FSM_FILL_BUSY         (DCC_FSM_FILL_BUSY),
  .DCC_WR_DATA_OUT           (DCC_WR_DATA_OUT),
  .DCC_HIT_DATA_OUT          (DCC_HIT_DATA_OUT),
  .DCC_ADDR_OUT              (DCC_ADDR_OUT),
  .DCC_DATA_WR_MASK_OUT      (DCC_DATA_WR_MASK_OUT),
  .DCC_TAG_VALID_SET_INDEX   (DCC_TAG_VALID_SET_INDEX),
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
  .DMA_INT                   (DMA_INT)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

initial begin
  // rst = 1;
  // KB_PFN = 0; DMA_PFN = 0;
  // DATA_driver_enable = 0;
  // ADDR_driver_enable = 0;
  // WR_mask_driver_enable = 0;
  // ICACHE_MISS = 0;
  // DCACHE_MISS = 0;
  // DCACHE_NEED_WR_BUS = 0;
  // repeat(10) @(posedge clk);
  // rst = 0;

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  // test
  $finish;
end

endmodule