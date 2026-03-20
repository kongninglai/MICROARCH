module cc_off_core_tb;

initial begin
    $vcdplusfile("cc_off_core_tb.dump.vpd");
    $vcdpluson(0, cc_off_core_tb);
    $vcdpluson(0, cc_off_core_tb.DUT);
end

localparam MEM_BYTE_CAPACITY=32768;
localparam MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH=8;
localparam CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT=128;
localparam CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam BUS_BIT_WIDTH=32;
localparam RANK_BIT_WIDTH=128;
localparam RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH=$clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam ADDR_SETUP_X10            = 280;
localparam CE_SETUP_X10              = 370;
localparam DOE_TIME_X10              = 620;
localparam HZ_TIME_X10               = 175;
localparam CYCLE_TIME_X10            = 100;
localparam RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam V_CT_WRITE_DONE           = WR_AND_DATA_EN_CYCLES - 1;
localparam V_CT_RD_EN_DONE           = RD_EN_CYCLES - 1;
localparam V_CT_SHORT_BRST_DONE      = (RANK_BURST_SIZE - 1) - 1;
localparam NUM_SETS                   = 8;
localparam NUM_WAYS                   = 4;
localparam INDEX_WIDTH                = $clog2(NUM_SETS);
localparam WAY_WIDTH                  = $clog2(NUM_WAYS);
localparam TAG_WIDTH                  = 8;
localparam MASK_WIDTH                 = NUM_WAYS * RANK_BURST_SIZE;
localparam CYCLE_TIME                 = CYCLE_TIME_X10 / 10.0;
localparam DELAY_ADJ                  = 7;

reg                                   clk;
reg                                   rst;

reg  [BUS_BIT_WIDTH-1:0]                DATA_driver;
reg                                     DATA_driver_enable;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};

reg  [MEM_ADDR_WIDTH-1:0]               ADDR_driver;
reg                                     ADDR_driver_enable;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {MEM_ADDR_WIDTH{1'bz}};

reg  [CHIPS_PER_RANK-1:0]               WR_mask_driver;
reg                                     WR_mask_driver_enable;
wire [CHIPS_PER_RANK-1:0]               WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {CHIPS_PER_RANK{1'bz}};

reg                                     CACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]               CACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                    CACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]                   CC_DATA_WR_MASK_DEFAULT;

wire                                    CC_STREAM_BUF_HIT;
wire                                    CC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]               CC_WR_DATA_OUT;
wire [RANK_BIT_WIDTH-1:0]               CC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CC_ADDR_OUT;
wire [MASK_WIDTH-1:0]                   CC_DATA_WR_MASK_OUT;

wire [NUM_WAYS-1:0]                     CC_TAG_WR_MASK_OUT;
wire [TAG_WIDTH-1:0]                    CC_TAG_IN;

wire                                    CC_VALID_SET_OR_CLR;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]        CC_VALID_WR_EN;
wire                                    CC_FSM_VALID_WR_EN_GLOBAL;

reg                                     DC_MEM_WR_RQ;
wire                                    DC_MEM_WR_ACK;

reg  [2:0]                              KB_PFN, DMA_PFN;

initial begin
    clk = 0;
    forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

integer FAILURES  = 0;
integer SUCCESSES = 0;

cc_off_core #(
    .CYCLE_TIME_X10           (CYCLE_TIME_X10)
) DUT (
    .rst                        (rst),
    .clk                        (clk),
    .KB_PFN                     (KB_PFN),
    .DMA_PFN                    (DMA_PFN),
    .DATA_BUS                   (DATA_BUS),
    .ADDR_BUS                   (ADDR_BUS),
    .WR_mask                    (WR_mask),
    .CACHE_MISS                (CACHE_MISS),
    .CACHE_RD_DATA             (CACHE_RD_DATA),
    .CACHE_PHYS_ADDR           (CACHE_PHYS_ADDR),
    .CACHE_VICT_WAY            (CACHE_VICT_WAY),
    .CC_STREAM_BUF_HIT         (CC_STREAM_BUF_HIT),
    .CC_FSM_FILL_BUSY          (CC_FSM_FILL_BUSY),
    .CC_WR_DATA_OUT            (CC_WR_DATA_OUT),
    .CC_HIT_DATA_OUT           (CC_HIT_DATA_OUT),
    .CC_ADDR_OUT               (CC_ADDR_OUT),
    .CC_DATA_WR_MASK_OUT       (CC_DATA_WR_MASK_OUT),
    .CC_TAG_WR_MASK_OUT        (CC_TAG_WR_MASK_OUT),
    .CC_TAG_IN                 (CC_TAG_IN),
    .CC_VALID_SET_OR_CLR       (CC_VALID_SET_OR_CLR),
    .CC_VALID_WR_EN            (CC_VALID_WR_EN),
    .CC_FSM_VALID_WR_EN_GLOBAL (CC_FSM_VALID_WR_EN_GLOBAL),
    .DC_MEM_WR_RQ               (DC_MEM_WR_RQ),
    .DC_MEM_WR_ACK              (DC_MEM_WR_ACK)
);

task stopAllDrivers;
  begin
    WR_mask_driver_enable        <= 1'b0;
    WR_mask_driver               <= {CHIPS_PER_RANK{1'bz}};
    DATA_driver_enable           <= 1'b0;
    DATA_driver                  <= {BUS_BIT_WIDTH{1'bz}};
    ADDR_driver_enable           <= 1'b0;
    ADDR_driver                  <= {MEM_ADDR_WIDTH{1'bz}};
  end
endtask

task assertTwoCycles;
  begin
    #(DELAY_ADJ);
    DC_MEM_WR_RQ     <= 1'b1;
    #(2 * CYCLE_TIME - DELAY_ADJ);
    DC_MEM_WR_RQ     <= 1'b0;
  end
endtask

task driveRDaddr;
  input [MEM_ADDR_WIDTH-1:0]  MEM_ADDR;
  begin
    #(DELAY_ADJ);
    ADDR_driver             <= MEM_ADDR;
    ADDR_driver_enable      <= 1'b1;
    #(1 * CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task driveWRmaskWRaddr;
  input [15:0]  WR_mask_val;
  input [14:0]  MEM_ADDR;
  begin
    #(DELAY_ADJ);
    WR_mask_driver          <= WR_mask_val;
    WR_mask_driver_enable   <= 1'b1;
    ADDR_driver             <= MEM_ADDR;
    ADDR_driver_enable      <= 1'b1;
    #(RANK_BURST_SIZE * CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task driveWRdata;
  input [RANK_BIT_WIDTH-1:0] WR_DATA;
  begin
    #(DELAY_ADJ);
    DATA_driver             <= WR_DATA[BUS_BIT_WIDTH-1:0];
    DATA_driver_enable      <= 1'b1;    
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task check_wr_data;
  input [RANK_BIT_WIDTH-1:0]  CC_WR_DATA_OUT_EXP;
  begin
    if (CC_WR_DATA_OUT !== CC_WR_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_WR_DATA_OUT exp=%h got=%h", $time, CC_WR_DATA_OUT_EXP, CC_WR_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_stream_buffer;
  input [RANK_BIT_WIDTH-1:0]  SB_DATA_OUT_EXP;
  begin
    if (DUT.cache_controller_inst.SB_DATA_OUT !== SB_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: SB_DATA_OUT exp=%h got=%h", $time, SB_DATA_OUT_EXP, DUT.cache_controller_inst.SB_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

integer i, j;
reg   [RANK_BIT_WIDTH-1:0] RAND_DATA0, RAND_DATA1;
reg   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  CACHE_PHYS_ADDR_SAVED;

initial begin
  rst <= 1'b0;
  DC_MEM_WR_RQ  <= 1'b0;
  stopAllDrivers();
  CACHE_MISS                 <= 1'b0;
  CACHE_RD_DATA              <= {RANK_BIT_WIDTH{1'b0}};
  CACHE_PHYS_ADDR            <= 0;
  CACHE_PHYS_ADDR_SAVED      <= 0;
  CACHE_VICT_WAY             <= {WAY_WIDTH{1'b0}};
  CC_DATA_WR_MASK_DEFAULT    <= {MASK_WIDTH{1'b1}};
  DMA_PFN                    <= 3'd1;
  KB_PFN                     <= 3'd3;

  #(1.5 * CYCLE_TIME);
  rst <= 1'b1;
  #(CYCLE_TIME);

  /*** MEMORY CONTROLLER TESTING ***/
  for (i = 0; i < 2048; i = i + 2) begin
    assertTwoCycles();
    RAND_DATA0 = {i+3, i+2, i+1, i+0};
    RAND_DATA1 = {i+7, i+6, i+5, i+4};
    fork
      driveWRmaskWRaddr(16'h0000, (i << 4));
      driveWRdata(RAND_DATA0);
    join
    #(20 * CYCLE_TIME);

    assertTwoCycles();
    fork
      driveWRmaskWRaddr(16'h0000, ((i+1) << 4));
      driveWRdata(RAND_DATA1);
    join
    #(20 * CYCLE_TIME);
  end

  for (i = 0; i < 2048; i = i + 2) begin
    if (i[10:8] !== DMA_PFN && i[10:8] !== KB_PFN) begin
      for (j = 0; j < 4; j = j + 1) begin
        CACHE_PHYS_ADDR            <= i[10:0];
        CACHE_PHYS_ADDR_SAVED      <= i[10:0];
        CACHE_VICT_WAY             <= j[1:0];

        CACHE_MISS                 <= 1'b1;
        #(CYCLE_TIME);
        CACHE_MISS                 <= 1'b1;
        #(CYCLE_TIME);
        CACHE_PHYS_ADDR            <= CACHE_PHYS_ADDR + 2;
        @(negedge DUT.DATA_VALID_BAR);
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
        CACHE_MISS                 <= 1'b0;
        #(CYCLE_TIME);
        check_wr_data(({{96{1'b0}}, i+5}) << 32);
        #(CYCLE_TIME);
        check_wr_data(({{96{1'b0}}, i+6}) << 64);
        #(CYCLE_TIME);
        check_wr_data(({{96{1'b0}}, i+7}) << 96);
        #(CYCLE_TIME);
        check_stream_buffer({i+7, i+6, i+5, i+4});
        #(CYCLE_TIME);
        CACHE_PHYS_ADDR            <= CACHE_PHYS_ADDR_SAVED + 1;
        CACHE_PHYS_ADDR_SAVED      <= CACHE_PHYS_ADDR_SAVED + 1;
        CACHE_MISS                 <= 1'b1;
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