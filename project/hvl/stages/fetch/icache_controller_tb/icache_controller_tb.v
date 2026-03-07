module icache_controller_tb;

initial begin
    $vcdplusfile("icache_controller_tb.dump.vpd");
    $vcdpluson(0, icache_controller_tb); 
    $vcdpluson(0, icache_controller_tb.DUT); 
end

localparam RANK_BIT_WIDTH               = 128;
localparam BUS_BIT_WIDTH                = 32;
localparam RANK_BURST_SIZE              = 4;
localparam MEM_ADDR_WIDTH               = 15;
localparam NUM_SETS                     = 8;
localparam INDEX_WIDTH                  = $clog2(NUM_SETS);
localparam NUM_WAYS                     = 4;
localparam WAY_WIDTH                    = $clog2(NUM_WAYS);
localparam TAG_WIDTH                    = 8;
localparam V_CT_CACHE_FILL_DONE         = 2;
localparam V_CT_SB_FILL_DONE            = 6;

localparam CYCLE_TIME                   = 10.0;
localparam MASK_WIDTH                   = NUM_SETS * NUM_WAYS * RANK_BURST_SIZE;

reg  clk, rst;

reg  [BUS_BIT_WIDTH-1:0]                DATA_driver;
reg                                     DATA_driver_enable;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};

reg                                     IC_MEM_RD_ACK;
reg                                     DATA_VALID_BAR;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS;
wire                                    IC_MEM_RD_RQ;

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

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

integer FAILURES  = 0;
integer SUCCESSES = 0;

icache_controller #(
    .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
    .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
    .RANK_BURST_SIZE(RANK_BURST_SIZE),
    .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
    .NUM_SETS(NUM_SETS),
    .NUM_WAYS(NUM_WAYS),
    .TAG_WIDTH(TAG_WIDTH),
    .V_CT_CACHE_FILL_DONE(V_CT_CACHE_FILL_DONE),
    .V_CT_SB_FILL_DONE(V_CT_SB_FILL_DONE)
) DUT (
    .rst(rst), .clk(clk),
    .DATA_BUS(DATA_BUS),
    .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .IC_MEM_RD_RQ(IC_MEM_RD_RQ),
    .ICACHE_MISS(ICACHE_MISS),
    .ICACHE_RD_DATA(ICACHE_RD_DATA),
    .ICACHE_PHYS_ADDR(ICACHE_PHYS_ADDR),
    .ICACHE_VICT_WAY(ICACHE_VICT_WAY),
    .ICC_DATA_WR_MASK_DEFAULT(ICC_DATA_WR_MASK_DEFAULT),
    .ICC_STREAM_BUF_HIT(ICC_STREAM_BUF_HIT),
    .ICC_FSM_FILL_BUSY(ICC_FSM_FILL_BUSY),
    .ICC_WR_DATA_OUT(ICC_WR_DATA_OUT),
    .ICC_HIT_DATA_OUT(ICC_HIT_DATA_OUT),
    .ICC_ADDR_OUT(ICC_ADDR_OUT),
    .ICC_DATA_WR_MASK_OUT(ICC_DATA_WR_MASK_OUT),
    .ICC_TAG_VALID_SET_INDEX(ICC_TAG_VALID_SET_INDEX),
    .ICC_TAG_WR_MASK_OUT(ICC_TAG_WR_MASK_OUT),
    .ICC_TAG_IN(ICC_TAG_IN),
    .ICC_VALID_SET_OR_CLR(ICC_VALID_SET_OR_CLR),
    .ICC_VALID_WR_EN(ICC_VALID_WR_EN),
    .ICC_FSM_VALID_WR_EN_GLOBAL(ICC_FSM_VALID_WR_EN_GLOBAL)
);

task check;
  input [2:0]                                   STATE_EXP;
  input [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS_EXP;
  input                                         IC_MEM_RD_RQ_EXP;
  input                                         ICC_STREAM_BUF_HIT_EXP, ICC_FSM_FILL_BUSY_EXP;
  input [RANK_BIT_WIDTH-1:0]                    ICC_HIT_DATA_OUT_EXP;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICC_ADDR_OUT_EXP;
  input [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] ICC_DATA_WR_MASK_OUT_EXP;
  input [INDEX_WIDTH-1:0]                       ICC_TAG_VALID_SET_INDEX_EXP;
  input [NUM_WAYS-1:0]                          ICC_TAG_WR_MASK_OUT_EXP;
  input [TAG_WIDTH-1:0]                         ICC_TAG_IN_EXP;
  input                                         ICC_VALID_SET_OR_CLR_EXP;
  input [INDEX_WIDTH+WAY_WIDTH-1:0]             ICC_VALID_WR_EN_EXP;
  input                                         ICC_FSM_VALID_WR_EN_GLOBAL_EXP;
  begin
    if (DUT.STATE !== STATE_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: STATE exp=%h got=%h", $time, STATE_EXP, DUT.STATE);
    end
    if (ADDR_BUS !== ADDR_BUS_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ADDR_BUS exp=%h got=%h", $time, ADDR_BUS_EXP, ADDR_BUS);
    end
    if (IC_MEM_RD_RQ !== IC_MEM_RD_RQ_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: IC_MEM_RD_RQ exp=%h got=%h", $time, IC_MEM_RD_RQ_EXP, IC_MEM_RD_RQ);
    end
    if (ICC_STREAM_BUF_HIT !== ICC_STREAM_BUF_HIT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_STREAM_BUF_HIT exp=%h got=%h", $time, ICC_STREAM_BUF_HIT_EXP, ICC_STREAM_BUF_HIT);
    end
    if (ICC_FSM_FILL_BUSY !== ICC_FSM_FILL_BUSY_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_FSM_FILL_BUSY exp=%h got=%h", $time, ICC_FSM_FILL_BUSY_EXP, ICC_FSM_FILL_BUSY);
    end
    if (ICC_HIT_DATA_OUT !== ICC_HIT_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_HIT_DATA_OUT exp=%h got=%h", $time, ICC_HIT_DATA_OUT_EXP, ICC_HIT_DATA_OUT);
    end
    if (ICC_ADDR_OUT !== ICC_ADDR_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_ADDR_OUT exp=%h got=%h", $time, ICC_ADDR_OUT_EXP, ICC_ADDR_OUT);
    end
    if (ICC_DATA_WR_MASK_OUT !== ICC_DATA_WR_MASK_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_DATA_WR_MASK_OUT exp=%h got=%h", $time, ICC_DATA_WR_MASK_OUT_EXP, ICC_DATA_WR_MASK_OUT);
    end
    if (ICC_TAG_VALID_SET_INDEX !== ICC_TAG_VALID_SET_INDEX_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_TAG_VALID_SET_INDEX exp=%h got=%h", $time, ICC_TAG_VALID_SET_INDEX_EXP, ICC_TAG_VALID_SET_INDEX);
    end
    if (ICC_TAG_WR_MASK_OUT !== ICC_TAG_WR_MASK_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_TAG_WR_MASK_OUT exp=%h got=%h", $time, ICC_TAG_WR_MASK_OUT_EXP, ICC_TAG_WR_MASK_OUT);
    end
    if (ICC_TAG_IN !== ICC_TAG_IN_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_TAG_IN exp=%h got=%h", $time, ICC_TAG_IN_EXP, ICC_TAG_IN);
    end
    if (ICC_VALID_SET_OR_CLR !== ICC_VALID_SET_OR_CLR_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_VALID_SET_OR_CLR exp=%h got=%h", $time, ICC_VALID_SET_OR_CLR_EXP, ICC_VALID_SET_OR_CLR);
    end
    if (ICC_VALID_WR_EN !== ICC_VALID_WR_EN_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_VALID_WR_EN exp=%h got=%h", $time, ICC_VALID_WR_EN_EXP, ICC_VALID_WR_EN);
    end
    if (ICC_FSM_VALID_WR_EN_GLOBAL !== ICC_FSM_VALID_WR_EN_GLOBAL_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICC_FSM_VALID_WR_EN_GLOBAL exp=%h got=%h", $time, ICC_FSM_VALID_WR_EN_GLOBAL_EXP, ICC_FSM_VALID_WR_EN_GLOBAL);
    end

    if (DUT.STATE === STATE_EXP &&
        ICC_STREAM_BUF_HIT === ICC_STREAM_BUF_HIT_EXP &&
        ICC_FSM_FILL_BUSY === ICC_FSM_FILL_BUSY_EXP &&
        ICC_HIT_DATA_OUT === ICC_HIT_DATA_OUT_EXP &&
        ICC_ADDR_OUT === ICC_ADDR_OUT_EXP &&
        ICC_DATA_WR_MASK_OUT === ICC_DATA_WR_MASK_OUT_EXP &&
        ICC_TAG_VALID_SET_INDEX === ICC_TAG_VALID_SET_INDEX_EXP &&
        ICC_TAG_WR_MASK_OUT === ICC_TAG_WR_MASK_OUT_EXP &&
        ICC_TAG_IN === ICC_TAG_IN_EXP &&
        ICC_VALID_SET_OR_CLR === ICC_VALID_SET_OR_CLR_EXP &&
        ICC_VALID_WR_EN === ICC_VALID_WR_EN_EXP &&
        ICC_FSM_VALID_WR_EN_GLOBAL === ICC_FSM_VALID_WR_EN_GLOBAL_EXP) begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

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
    if (DUT.SB_DATA_OUT !== SB_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: SB_DATA_OUT exp=%h got=%h", $time, SB_DATA_OUT_EXP, DUT.SB_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

reg   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  ICACHE_PHYS_ADDR_SAVED;
reg   [BUS_BIT_WIDTH-1:0]                 DATA_BUS_SAVED[0:7];

integer i, j;

initial begin
    rst                         <= 1'b0; 
    IC_MEM_RD_ACK               <= 1'b0;
    DATA_VALID_BAR              <= 1'b1;
    DATA_driver                 <= {BUS_BIT_WIDTH{1'bz}};
    DATA_driver_enable          <= 1'b0;
    ICACHE_MISS                 <= 1'b0;
    ICACHE_RD_DATA              <= {RANK_BIT_WIDTH{1'b0}};
    ICACHE_PHYS_ADDR            <= 0;
    ICACHE_PHYS_ADDR_SAVED      <= 0;
    ICACHE_VICT_WAY             <= {WAY_WIDTH{1'b1}};
    ICC_DATA_WR_MASK_DEFAULT    <= {MASK_WIDTH{1'b1}};

    #(1.5 * CYCLE_TIME);
    rst <= 1'b1;
    #(8 * CYCLE_TIME);

    for (i = 0; i < 2048; i = i + 2) begin
      for (j = 0; j < 4; j = j + 1) begin
        ICACHE_PHYS_ADDR            <= i[10:0];
        ICACHE_PHYS_ADDR_SAVED      <= i[10:0];
        ICACHE_VICT_WAY             <= j[1:0];

        ICACHE_MISS                 <= 1'b1;
        #(CYCLE_TIME);
        ICACHE_MISS                 <= 1'b1;
        check(3'b000, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b0, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICC_TAG_VALID_SET_INDEX, {NUM_WAYS{1'b1}},
              ICC_TAG_IN, 1'b1, {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(CYCLE_TIME);
        ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR + 2;
        IC_MEM_RD_ACK               <= 1'b1;
        #(CYCLE_TIME);
        IC_MEM_RD_ACK               <= 1'b0;
        check(3'b001, {MEM_ADDR_WIDTH{1'bz}}, 1'b1, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(CYCLE_TIME);
        check(3'b010, {ICACHE_PHYS_ADDR_SAVED,4'b0000}, 1'b0, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}))),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(7 * CYCLE_TIME);
        DATA_VALID_BAR              <= 1'b0;
        DATA_driver                 = $random;
        DATA_BUS_SAVED[0]           = DATA_driver;
        DATA_driver_enable          <= 1'b1;
        #(CYCLE_TIME);
        check(3'b010, {ICACHE_PHYS_ADDR_SAVED,4'b0000}, 1'b0, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}))),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data({{96{1'b0}}, DATA_driver});

        DATA_driver                 = $random;
        DATA_BUS_SAVED[1]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b011, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}) + 1)),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 32);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[2]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b011, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * (ICACHE_VICT_WAY + (RANK_BURST_SIZE)*ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]) + 2)),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 64);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[3]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b100, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b1, ICACHE_RD_DATA, ICACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * (ICACHE_VICT_WAY + (RANK_BURST_SIZE)*ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]) + 3)),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ~(4'd1 << (ICACHE_VICT_WAY)),
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}, 1'b1);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 96);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[4]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b0, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}));

        ICACHE_MISS                 <= 1'b0;
        DATA_driver                 = $random;
        DATA_BUS_SAVED[5]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b0, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 32);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[6]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b0, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 64);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[7]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b110, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b0, 1'b0, ICACHE_RD_DATA, ICACHE_PHYS_ADDR, ICC_DATA_WR_MASK_DEFAULT,
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 96);
        
        DATA_driver                 <= {BUS_BIT_WIDTH{1'bz}};
        DATA_driver_enable          <= 1'b0;
        DATA_VALID_BAR              <= 1'b1;

        #(CYCLE_TIME);
        check_stream_buffer({DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]});
        #(CYCLE_TIME);

        ICACHE_PHYS_ADDR            <= ICACHE_PHYS_ADDR_SAVED + 1;
        ICACHE_PHYS_ADDR_SAVED      <= ICACHE_PHYS_ADDR_SAVED + 1;
        ICACHE_MISS                 <= 1'b1;

        #(2 * CYCLE_TIME);
        check(3'b111, {MEM_ADDR_WIDTH{1'bz}}, 1'b0, 1'b1, 1'b0, {DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]},
              ICACHE_PHYS_ADDR, ~(128'd15 << ((NUM_WAYS) * ({ICACHE_PHYS_ADDR[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}))),
              ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ~(4'd1 << (ICACHE_VICT_WAY)),
              ICACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {ICACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ICACHE_VICT_WAY}, 1'b1);
        check_wr_data({DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]});
      end
    end



  
    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
    
    $finish;
end

endmodule