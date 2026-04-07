module full_cc_off_core_tb;

initial begin
    // $vcdplusfile("full_cc_off_core_tb.dump.vpd");
    // $vcdpluson(0, full_cc_off_core_tb);
    // $vcdpluson(0, full_cc_off_core_tb.DUT);
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
localparam MASK_WIDTH                   = NUM_WAYS * RANK_BURST_SIZE;
localparam CYCLE_TIME                   = CYCLE_TIME_X10 / 10.0;

reg                                     clk;
reg                                     rst;
reg  [2:0]                              KB_PFN, DMA_PFN;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS;
wire [CHIPS_PER_RANK-1:0]               WR_mask;

reg                                     ICACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]               ICACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                    ICACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]                   ICC_DATA_WR_MASK_DEFAULT;

wire                                    ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]               ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICC_ADDR_OUT;
wire [MASK_WIDTH-1:0]                   ICC_DATA_WR_MASK_OUT;
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

reg  [7:0]                              TEST_CASE_NEW_CHAR;
reg  [7:0]                              TEST_CASE_NEW_CHAR_WR; 
reg                                     TEST_CASE_NEW_READY;
reg                                     TEST_CASE_NEW_READY_WR;

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

integer FAILURES = 0;
integer SUCCESSES = 0;

task check_wr_data;
  input [RANK_BIT_WIDTH-1:0]  ICC_WR_DATA_OUT_EXP;
  begin
    if (ICC_WR_DATA_OUT !== ICC_WR_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_WR_DATA_OUT exp=%h got=%h", $time, ICC_WR_DATA_OUT_EXP, ICC_WR_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_stream_buffer;
  input [RANK_BIT_WIDTH-1:0]  SB_DATA_OUT_EXP;
  begin
    if (DUT.icache_controller_inst.SB_DATA_OUT !== SB_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: SB_DATA_OUT exp=%h got=%h", $time, SB_DATA_OUT_EXP, DUT.icache_controller_inst.SB_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_wr_data_D;
  input [RANK_BIT_WIDTH-1:0]  DCC_WR_DATA_OUT_EXP;
  begin
    if (DCC_WR_DATA_OUT !== DCC_WR_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: DCC_WR_DATA_OUT exp=%h got=%h", $time, DCC_WR_DATA_OUT_EXP, DCC_WR_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_stream_buffer_D;
  input [RANK_BIT_WIDTH-1:0]  SB_DATA_OUT_EXP;
  begin
    if (DUT.dcache_controller_inst.SB_DATA_OUT !== SB_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: SB_DATA_OUT exp=%h got=%h", $time, SB_DATA_OUT_EXP, DUT.dcache_controller_inst.SB_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

integer i, j;
reg   [RANK_BIT_WIDTH-1:0] RAND_DATA0, RAND_DATA1;
reg   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  ICACHE_PHYS_ADDR_SAVED, DCACHE_RD_PHYS_ADDR_SAVED;

task check_full_line_fill;
  input integer i;
  begin
    ICACHE_MISS                 <= 1'b1;
    #(CYCLE_TIME);
    ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR + 2;
    while (DUT.DATA_VALID_BAR !== 1'b0) begin
      @(DUT.DATA_VALID_BAR);
    end
    @(posedge clk);
    check_wr_data({{96{1'b0}}, i+0});
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+1}) << 32);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+2}) << 64);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+3}) << 96);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+4}));
    ICACHE_MISS                 <= 1'b0;
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+5}) << 32);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+6}) << 64);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, i+7}) << 96);
    #(CYCLE_TIME);
    check_stream_buffer({i+7, i+6, i+5, i+4});
    #(CYCLE_TIME);
  end
endtask

task check_raw_data;
  input [RANK_BIT_WIDTH-1:0]  DATA, DATA_NEXT;
  begin
    ICACHE_MISS                 <= 1'b1;
    #(CYCLE_TIME);
    ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR + 2;
    while (DUT.DATA_VALID_BAR !== 1'b0) begin
      @(DUT.DATA_VALID_BAR);
    end
    @(posedge clk);
    check_wr_data({{96{1'b0}}, DATA[31:0]});
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA[63:32]}) << 32);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA[95:64]}) << 64);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA[127:96]}) << 96);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA_NEXT[31:0]}));
    ICACHE_MISS                 <= 1'b0;
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA_NEXT[63:32]}) << 32);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA_NEXT[95:64]}) << 64);
    #(CYCLE_TIME);
    check_wr_data(({{96{1'b0}}, DATA_NEXT[127:96]}) << 96);
    #(CYCLE_TIME);
    check_stream_buffer(DATA_NEXT);
    #(CYCLE_TIME);
  end
endtask

task check_raw_data_no_NL;
  input [RANK_BIT_WIDTH-1:0]  DATA;
  begin
    DCACHE_MISS                 <= 1'b1;
    #(CYCLE_TIME);
    DCACHE_RD_PHYS_ADDR         <= DCACHE_RD_PHYS_ADDR + 2;
    while (DUT.DATA_VALID_BAR !== 1'b0) begin
      @(DUT.DATA_VALID_BAR);
    end
    @(posedge clk);
    check_wr_data_D({{96{1'b0}}, DATA[31:0]});
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, DATA[63:32]}) << 32);
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, DATA[95:64]}) << 64);
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, DATA[127:96]}) << 96);
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, {BUS_BIT_WIDTH{1'bZ}}}));
    DCACHE_MISS                 <= 1'b0;
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, {BUS_BIT_WIDTH{1'bZ}}}) << 32);
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, {BUS_BIT_WIDTH{1'bZ}}}) << 64);
    #(CYCLE_TIME);
    check_wr_data_D(({{96{1'b0}}, {BUS_BIT_WIDTH{1'bZ}}}) << 96);
    #(CYCLE_TIME);
    check_stream_buffer_D({RANK_BIT_WIDTH{1'bX}});
    #(CYCLE_TIME);
  end
endtask

reg [7:0] BYTE_VAL;
reg [RANK_BIT_WIDTH-1:0]  DATA_EXP, DATA_NEXT_EXP;

initial begin
  rst <= 1'b0;
  

  ICACHE_MISS                <= 1'b0;
  ICACHE_RD_DATA             <= {RANK_BIT_WIDTH{1'b0}};
  ICACHE_PHYS_ADDR           <= 0;
  ICACHE_VICT_WAY            <= {WAY_WIDTH{1'b0}};
  ICC_DATA_WR_MASK_DEFAULT   <= {MASK_WIDTH{1'b1}};


  DCACHE_MISS                <= 1'b0;
  DCACHE_RD_DATA             <= {RANK_BIT_WIDTH{1'b0}};
  DCACHE_RD_PHYS_ADDR        <= 0;
  DCACHE_RD_PHYS_ADDR_SAVED  <= 0;
  DCACHE_VICT_WAY            <= {WAY_WIDTH{1'b0}};
  DCC_DATA_WR_MASK_DEFAULT   <= {MASK_WIDTH{1'b1}};


  DCACHE_NEED_WR_BUS         <= 1'b0;
  DCACHE_WBE_DATA            <= {RANK_BIT_WIDTH{1'b0}};
  DCACHE_WR_PHYS_ADDR        <= 0;
  DCACHE_WR_MASK             <= {CHIPS_PER_RANK{1'b0}};

  TEST_CASE_NEW_CHAR         <= 8'd0;
  TEST_CASE_NEW_CHAR_WR      <= 8'd0;
  TEST_CASE_NEW_READY        <= 1'b0;
  TEST_CASE_NEW_READY_WR     <= 1'b0;

  DMA_PFN                    <= 3'd1;
  KB_PFN                     <= 3'd3;

  #(1.5 * CYCLE_TIME);
  rst <= 1'b1;
  #(CYCLE_TIME);

  /*** Enable keyboard and put in the test case ***/

  // Enable KB

  DCACHE_NEED_WR_BUS         <= 1'b1;
  DCACHE_WBE_DATA            <= {RANK_BIT_WIDTH{1'b1}}; // Only the write to KBER should take effect!
  DCACHE_WR_PHYS_ADDR        <= {KB_PFN, 8'd0}; // KBER in bit [0], KBSR in bit [64]
  #(CYCLE_TIME);
  DCACHE_NEED_WR_BUS         <= 1'b0;
  @(negedge WBE_BUSY); @(negedge WBE_BUSY); @(posedge clk);
  @(posedge clk);

  // Verify only KBER was updated

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd0};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd0};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL(128'd1);

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd1};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd1};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL(128'd0);

  TEST_CASE_NEW_CHAR         <= 8'h67;
  TEST_CASE_NEW_CHAR_WR      <= {8{1'b1}};
  TEST_CASE_NEW_READY        <= 1'b1;
  TEST_CASE_NEW_READY_WR     <= 1'b1;

  #(CYCLE_TIME);

  TEST_CASE_NEW_CHAR         <= 8'd0;
  TEST_CASE_NEW_CHAR_WR      <= 8'd0;
  TEST_CASE_NEW_READY        <= 1'b0;
  TEST_CASE_NEW_READY_WR     <= 1'b0;

  // Verify KBSR and KBDR

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd0};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd0};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL({64'd1, 64'd1});

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd1};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd1};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL({120'd0, 8'h67});

  // Verify self-clearing KBSR

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd0};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd0};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL(128'd1);

  DCACHE_RD_PHYS_ADDR         <= {KB_PFN, 8'd1};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {KB_PFN, 8'd1};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL({120'd0, 8'h67});

  /*** Setting up DMA Test Case (DISK ADDR = 0xFFFFFF67, MEM_ADDR = 0x00000067,
                                 NUM_BYTES = 32'd3988 (END MEM_ADDR = 0x00000FFA))
                                 First 0x66 bytes = 8'hXX, Last 0x5 bytes = 8'hXX ***/
  
  DCACHE_NEED_WR_BUS         <= 1'b1;
  DCACHE_WBE_DATA            <= {32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67};
  DCACHE_WR_PHYS_ADDR        <= {DMA_PFN, 8'd0}; // KBER in bit [0], KBSR in bit [64]
  #(CYCLE_TIME);
  DCACHE_NEED_WR_BUS         <= 1'b0;
  @(negedge WBE_BUSY); @(negedge WBE_BUSY); @(posedge clk);
  @(posedge clk);

  DCACHE_RD_PHYS_ADDR         <= {DMA_PFN, 8'd0};
  DCACHE_RD_PHYS_ADDR_SAVED   <= {DMA_PFN, 8'd0};
  DCACHE_VICT_WAY             <= 0;
  check_raw_data_no_NL({32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67});

  // Ensure this can occur with other processor operations

  #(200 * CYCLE_TIME);
  ICACHE_PHYS_ADDR            <= 0;
  ICACHE_PHYS_ADDR_SAVED      <= 0;
  ICACHE_VICT_WAY             <= 0;
  ICACHE_MISS                 <= 1'b1;
  #(CYCLE_TIME);
  ICACHE_MISS                 <= 1'b0;

  #(200 * CYCLE_TIME);
  ICACHE_MISS                 <= 1'b1;
  #(CYCLE_TIME);
  ICACHE_MISS                 <= 1'b0;

  @(posedge DMA_INT);

  #(20 * CYCLE_TIME);

  ICACHE_VICT_WAY             <= 0;
  BYTE_VAL = 8'h67;
  DATA_EXP = 0;
  DATA_NEXT_EXP = 0;

  for (i = 0; i < 256; i = i + 2) begin
    if (i < 6) begin
      DATA_EXP      = {RANK_BIT_WIDTH{1'bX}};
      DATA_NEXT_EXP = {RANK_BIT_WIDTH{1'bX}};
    end else if (i == 6) begin
      DATA_EXP      = {BYTE_VAL+8'd8, BYTE_VAL+8'd7, BYTE_VAL+8'd6, BYTE_VAL+8'd5, 
                       BYTE_VAL+8'd4, BYTE_VAL+8'd3, BYTE_VAL+8'd2, BYTE_VAL+8'd1, 
                       BYTE_VAL, 8'hXX, 8'hXX, 8'hXX, 
                       8'hXX, 8'hXX, 8'hXX, 8'hXX};
      DATA_NEXT_EXP = {BYTE_VAL+8'd24, BYTE_VAL+8'd23, BYTE_VAL+8'd22, BYTE_VAL+8'd21,
                       BYTE_VAL+8'd20, BYTE_VAL+8'd19, BYTE_VAL+8'd18, BYTE_VAL+8'd17,
                       BYTE_VAL+8'd16, BYTE_VAL+8'd15, BYTE_VAL+8'd14, BYTE_VAL+8'd13,
                       BYTE_VAL+8'd12, BYTE_VAL+8'd11, BYTE_VAL+8'd10, BYTE_VAL+8'd9};
      BYTE_VAL      = BYTE_VAL + 8'd25;
    end else if (i == 254) begin
      DATA_EXP      = {BYTE_VAL+8'd15, BYTE_VAL+8'd14, BYTE_VAL+8'd13, BYTE_VAL+8'd12,
                       BYTE_VAL+8'd11, BYTE_VAL+8'd10, BYTE_VAL+8'd9,  BYTE_VAL+8'd8,
                       BYTE_VAL+8'd7,  BYTE_VAL+8'd6,  BYTE_VAL+8'd5,  BYTE_VAL+8'd4,
                       BYTE_VAL+8'd3,  BYTE_VAL+8'd2,  BYTE_VAL+8'd1,  BYTE_VAL+8'd0};
      DATA_NEXT_EXP = {8'hXX, 8'hXX, 8'hXX, 8'hXX,
                       8'hXX, BYTE_VAL+8'd26, BYTE_VAL+8'd25, BYTE_VAL+8'd24,
                       BYTE_VAL+8'd23, BYTE_VAL+8'd22, BYTE_VAL+8'd21, BYTE_VAL+8'd20,
                       BYTE_VAL+8'd19, BYTE_VAL+8'd18, BYTE_VAL+8'd17, BYTE_VAL+8'd16};
    end else begin
      DATA_EXP =      {BYTE_VAL+8'd15, BYTE_VAL+8'd14, BYTE_VAL+8'd13, BYTE_VAL+8'd12,
                       BYTE_VAL+8'd11, BYTE_VAL+8'd10, BYTE_VAL+8'd9,  BYTE_VAL+8'd8,
                       BYTE_VAL+8'd7,  BYTE_VAL+8'd6,  BYTE_VAL+8'd5,  BYTE_VAL+8'd4,
                       BYTE_VAL+8'd3,  BYTE_VAL+8'd2,  BYTE_VAL+8'd1,  BYTE_VAL+8'd0};
      DATA_NEXT_EXP = {BYTE_VAL+8'd31, BYTE_VAL+8'd30, BYTE_VAL+8'd29, BYTE_VAL+8'd28,
                       BYTE_VAL+8'd27, BYTE_VAL+8'd26, BYTE_VAL+8'd25, BYTE_VAL+8'd24,
                       BYTE_VAL+8'd23, BYTE_VAL+8'd22, BYTE_VAL+8'd21, BYTE_VAL+8'd20,
                       BYTE_VAL+8'd19, BYTE_VAL+8'd18, BYTE_VAL+8'd17, BYTE_VAL+8'd16};
      BYTE_VAL      = BYTE_VAL + 8'd32;
    end

    ICACHE_PHYS_ADDR            <= i[10:0];
    ICACHE_PHYS_ADDR_SAVED      <= i[10:0];
    check_raw_data(DATA_EXP, DATA_NEXT_EXP);
    ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR_SAVED + 1;
    ICACHE_PHYS_ADDR_SAVED      <= ICACHE_PHYS_ADDR_SAVED + 1;
    ICACHE_MISS                 <= 1'b1;
    #(2 * CYCLE_TIME);
    check_wr_data(DATA_NEXT_EXP);
  end

  ICACHE_MISS                 <= 1'b0;

  /*** MEMORY CONTROLLER TESTING ***/
  for (i = 0; i < 2048; i = i + 2) begin
    if (i[10:8] !== DMA_PFN && i[10:8] !== KB_PFN) begin
      DCACHE_NEED_WR_BUS         <= 1'b1;
      DCACHE_WBE_DATA            <= {i+3, i+2, i+1, i+0};
      DCACHE_WR_PHYS_ADDR        <= i[10:0];
      #(CYCLE_TIME);
      DCACHE_NEED_WR_BUS         <= 1'b0;
      @(negedge WBE_BUSY); @(negedge WBE_BUSY); @(posedge clk);
      @(posedge clk);
      DCACHE_NEED_WR_BUS         <= 1'b1;
      DCACHE_WBE_DATA            <= {i+7, i+6, i+5, i+4};
      DCACHE_WR_PHYS_ADDR        <= (i[10:0]) + 11'd1;
      #(CYCLE_TIME);
      DCACHE_NEED_WR_BUS         <= 1'b0;
      @(negedge WBE_BUSY); @(negedge WBE_BUSY); @(posedge clk);
      @(posedge clk);
    end
  end

  #(CYCLE_TIME);
  ICACHE_MISS                 <= 1'b1;
  
  for (i = 0; i < 2048; i = i + 2) begin
    if (i[10:8] !== DMA_PFN && i[10:8] !== KB_PFN) begin
      for (j = 0; j < 4; j = j + 1) begin
        ICACHE_PHYS_ADDR            <= i[10:0];
        ICACHE_PHYS_ADDR_SAVED      <= i[10:0];
        ICACHE_VICT_WAY             <= j[1:0];
        check_full_line_fill(i);
        ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR_SAVED + 1;
        ICACHE_PHYS_ADDR_SAVED      <= ICACHE_PHYS_ADDR_SAVED + 1;
        ICACHE_MISS                 <= 1'b1;
        #(2 * CYCLE_TIME);
        check_wr_data({i+7, i+6, i+5, i+4});
      end
    end
  end
  

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);


  $finish;
end

endmodule