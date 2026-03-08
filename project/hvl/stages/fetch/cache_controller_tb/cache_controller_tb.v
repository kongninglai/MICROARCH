module cache_controller_tb;

initial begin
    $vcdplusfile("cache_controller_tb.dump.vpd");
    $vcdpluson(0, cache_controller_tb); 
    $vcdpluson(0, cache_controller_tb.DUT); 
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
reg  [2:0]                              KB_PFN, DMA_PFN;

reg  [BUS_BIT_WIDTH-1:0]                DATA_driver;
reg                                     DATA_driver_enable;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};

reg  [2:0]                              ACKS;
reg                                     DATA_VALID_BAR;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS;
wire [2:0]                              REQS;

reg                                     CACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]               CACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                    CACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]                   CC_DATA_WR_MASK_DEFAULT;

wire                                    CC_STREAM_BUF_HIT, CC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]               CC_WR_DATA_OUT, CC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CC_ADDR_OUT;
wire [MASK_WIDTH-1:0]                   CC_DATA_WR_MASK_OUT;

wire [INDEX_WIDTH-1:0]                  CC_TAG_VALID_SET_INDEX;
wire [NUM_WAYS-1:0]                     CC_TAG_WR_MASK_OUT;
wire [TAG_WIDTH-1:0]                    CC_TAG_IN;
wire                                    CC_VALID_SET_OR_CLR;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]        CC_VALID_WR_EN;
wire                                    CC_FSM_VALID_WR_EN_GLOBAL;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

integer FAILURES  = 0;
integer SUCCESSES = 0;

cache_controller #(
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
    .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN),
    .DATA_BUS(DATA_BUS),
    .ACKS(ACKS),
    .DATA_VALID_BAR(DATA_VALID_BAR),
    .ADDR_BUS(ADDR_BUS),
    .REQS(REQS),
    .CACHE_MISS(CACHE_MISS),
    .CACHE_RD_DATA(CACHE_RD_DATA),
    .CACHE_PHYS_ADDR(CACHE_PHYS_ADDR),
    .CACHE_VICT_WAY(CACHE_VICT_WAY),
    .CC_DATA_WR_MASK_DEFAULT(CC_DATA_WR_MASK_DEFAULT),
    .CC_STREAM_BUF_HIT(CC_STREAM_BUF_HIT),
    .CC_FSM_FILL_BUSY(CC_FSM_FILL_BUSY),
    .CC_WR_DATA_OUT(CC_WR_DATA_OUT),
    .CC_HIT_DATA_OUT(CC_HIT_DATA_OUT),
    .CC_ADDR_OUT(CC_ADDR_OUT),
    .CC_DATA_WR_MASK_OUT(CC_DATA_WR_MASK_OUT),
    .CC_TAG_VALID_SET_INDEX(CC_TAG_VALID_SET_INDEX),
    .CC_TAG_WR_MASK_OUT(CC_TAG_WR_MASK_OUT),
    .CC_TAG_IN(CC_TAG_IN),
    .CC_VALID_SET_OR_CLR(CC_VALID_SET_OR_CLR),
    .CC_VALID_WR_EN(CC_VALID_WR_EN),
    .CC_FSM_VALID_WR_EN_GLOBAL(CC_FSM_VALID_WR_EN_GLOBAL)
);

task check;
  input [2:0]                                   STATE_EXP;
  input [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS_EXP;
  input [2:0]                                   REQS_EXP;
  input                                         CC_STREAM_BUF_HIT_EXP, CC_FSM_FILL_BUSY_EXP;
  input [RANK_BIT_WIDTH-1:0]                    CC_HIT_DATA_OUT_EXP;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT_EXP;
  input [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] CC_DATA_WR_MASK_OUT_EXP;
  input [INDEX_WIDTH-1:0]                       CC_TAG_VALID_SET_INDEX_EXP;
  input [NUM_WAYS-1:0]                          CC_TAG_WR_MASK_OUT_EXP;
  input [TAG_WIDTH-1:0]                         CC_TAG_IN_EXP;
  input                                         CC_VALID_SET_OR_CLR_EXP;
  input [INDEX_WIDTH+WAY_WIDTH-1:0]             CC_VALID_WR_EN_EXP;
  input                                         CC_FSM_VALID_WR_EN_GLOBAL_EXP;
  begin
    if (DUT.STATE !== STATE_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: STATE exp=%h got=%h", $time, STATE_EXP, DUT.STATE);
    end
    if (ADDR_BUS !== ADDR_BUS_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ADDR_BUS exp=%h got=%h", $time, ADDR_BUS_EXP, ADDR_BUS);
    end
    if (REQS !== REQS_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: REQS exp=%b got=%b", $time, REQS_EXP, REQS);
    end
    if (CC_STREAM_BUF_HIT !== CC_STREAM_BUF_HIT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_STREAM_BUF_HIT exp=%h got=%h", $time, CC_STREAM_BUF_HIT_EXP, CC_STREAM_BUF_HIT);
    end
    if (CC_FSM_FILL_BUSY !== CC_FSM_FILL_BUSY_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_FSM_FILL_BUSY exp=%h got=%h", $time, CC_FSM_FILL_BUSY_EXP, CC_FSM_FILL_BUSY);
    end
    if (CC_HIT_DATA_OUT !== CC_HIT_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_HIT_DATA_OUT exp=%h got=%h", $time, CC_HIT_DATA_OUT_EXP, CC_HIT_DATA_OUT);
    end
    if (CC_ADDR_OUT !== CC_ADDR_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_ADDR_OUT exp=%h got=%h", $time, CC_ADDR_OUT_EXP, CC_ADDR_OUT);
    end
    if (CC_DATA_WR_MASK_OUT !== CC_DATA_WR_MASK_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_DATA_WR_MASK_OUT exp=%h got=%h", $time, CC_DATA_WR_MASK_OUT_EXP, CC_DATA_WR_MASK_OUT);
    end
    if (CC_TAG_VALID_SET_INDEX !== CC_TAG_VALID_SET_INDEX_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_TAG_VALID_SET_INDEX exp=%h got=%h", $time, CC_TAG_VALID_SET_INDEX_EXP, CC_TAG_VALID_SET_INDEX);
    end
    if (CC_TAG_WR_MASK_OUT !== CC_TAG_WR_MASK_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_TAG_WR_MASK_OUT exp=%h got=%h", $time, CC_TAG_WR_MASK_OUT_EXP, CC_TAG_WR_MASK_OUT);
    end
    if (CC_TAG_IN !== CC_TAG_IN_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_TAG_IN exp=%h got=%h", $time, CC_TAG_IN_EXP, CC_TAG_IN);
    end
    if (CC_VALID_SET_OR_CLR !== CC_VALID_SET_OR_CLR_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_VALID_SET_OR_CLR exp=%h got=%h", $time, CC_VALID_SET_OR_CLR_EXP, CC_VALID_SET_OR_CLR);
    end
    if (CC_VALID_WR_EN !== CC_VALID_WR_EN_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_VALID_WR_EN exp=%h got=%h", $time, CC_VALID_WR_EN_EXP, CC_VALID_WR_EN);
    end
    if (CC_FSM_VALID_WR_EN_GLOBAL !== CC_FSM_VALID_WR_EN_GLOBAL_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: CC_FSM_VALID_WR_EN_GLOBAL exp=%h got=%h", $time, CC_FSM_VALID_WR_EN_GLOBAL_EXP, CC_FSM_VALID_WR_EN_GLOBAL);
    end

    if (DUT.STATE === STATE_EXP &&
        CC_STREAM_BUF_HIT === CC_STREAM_BUF_HIT_EXP &&
        CC_FSM_FILL_BUSY === CC_FSM_FILL_BUSY_EXP &&
        CC_HIT_DATA_OUT === CC_HIT_DATA_OUT_EXP &&
        CC_ADDR_OUT === CC_ADDR_OUT_EXP &&
        CC_DATA_WR_MASK_OUT === CC_DATA_WR_MASK_OUT_EXP &&
        CC_TAG_VALID_SET_INDEX === CC_TAG_VALID_SET_INDEX_EXP &&
        CC_TAG_WR_MASK_OUT === CC_TAG_WR_MASK_OUT_EXP &&
        CC_TAG_IN === CC_TAG_IN_EXP &&
        CC_VALID_SET_OR_CLR === CC_VALID_SET_OR_CLR_EXP &&
        CC_VALID_WR_EN === CC_VALID_WR_EN_EXP &&
        CC_FSM_VALID_WR_EN_GLOBAL === CC_FSM_VALID_WR_EN_GLOBAL_EXP) begin
      SUCCESSES = SUCCESSES + 1;
    end
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
    if (DUT.SB_DATA_OUT !== SB_DATA_OUT_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: SB_DATA_OUT exp=%h got=%h", $time, SB_DATA_OUT_EXP, DUT.SB_DATA_OUT);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

reg   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  CACHE_PHYS_ADDR_SAVED;
reg   [BUS_BIT_WIDTH-1:0]                 DATA_BUS_SAVED[0:7];

integer i, j;

initial begin
    rst                         <= 1'b0; 
    ACKS                        <= 3'd0;
    DATA_VALID_BAR              <= 1'b1;
    DATA_driver                 <= {BUS_BIT_WIDTH{1'bz}};
    DATA_driver_enable          <= 1'b0;
    CACHE_MISS                  <= 1'b0;
    CACHE_RD_DATA               <= {RANK_BIT_WIDTH{1'b0}};
    CACHE_PHYS_ADDR             <= 0;
    CACHE_PHYS_ADDR_SAVED       <= 0;
    CACHE_VICT_WAY              <= {WAY_WIDTH{1'b1}};
    CC_DATA_WR_MASK_DEFAULT     <= {MASK_WIDTH{1'b1}};
    DMA_PFN                     <= 3'd1;
    KB_PFN                      <= 3'd3;

    #(1.5 * CYCLE_TIME);
    rst <= 1'b1;
    #(8 * CYCLE_TIME);

    for (i = 0; i < 2048; i = i + 2) begin
      for (j = 0; j < 4; j = j + 1) begin
        CACHE_PHYS_ADDR            <= i[10:0];
        CACHE_PHYS_ADDR_SAVED      <= i[10:0];
        CACHE_VICT_WAY             <= j[1:0];

        CACHE_MISS                 <= 1'b1;
        #(CYCLE_TIME);
        CACHE_MISS                 <= 1'b1;
        check(3'b000, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b0, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CC_TAG_VALID_SET_INDEX, {NUM_WAYS{1'b1}},
              CC_TAG_IN, 1'b1, {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(CYCLE_TIME);
        CACHE_PHYS_ADDR            <= CACHE_PHYS_ADDR + 2;
        ACKS <= REQS;
        #(CYCLE_TIME);
        ACKS <= 3'd0;
        check(3'b001, {MEM_ADDR_WIDTH{1'bz}}, REQS, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(CYCLE_TIME);
        check(3'b010, {CACHE_PHYS_ADDR_SAVED,4'b0000}, 3'd0, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}))),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        #(7 * CYCLE_TIME);
        DATA_VALID_BAR              <= 1'b0;
        DATA_driver                 = $random;
        DATA_BUS_SAVED[0]           = DATA_driver;
        DATA_driver_enable          <= 1'b1;
        #(CYCLE_TIME);
        check(3'b010, {CACHE_PHYS_ADDR_SAVED,4'b0000}, 3'd0, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}))),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data({{96{1'b0}}, DATA_driver});

        DATA_driver                 = $random;
        DATA_BUS_SAVED[1]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b011, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * ({CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}) + 1)),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 32);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[2]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b011, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * (CACHE_VICT_WAY + (RANK_BURST_SIZE)*CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]) + 2)),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 64);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[3]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b100, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b1, CACHE_RD_DATA, CACHE_PHYS_ADDR_SAVED, ~(128'd1 << ((NUM_WAYS) * (CACHE_VICT_WAY + (RANK_BURST_SIZE)*CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE]) + 3)),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ~(4'd1 << (CACHE_VICT_WAY)),
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}, 1'b1);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 96);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[4]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b0, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}));

        CACHE_MISS                 <= 1'b0;
        DATA_driver                 = $random;
        DATA_BUS_SAVED[5]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b0, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 32);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[6]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b101, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b0, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 64);

        DATA_driver                 = $random;
        DATA_BUS_SAVED[7]           = DATA_driver;
        #(CYCLE_TIME);
        check(3'b110, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b0, 1'b0, CACHE_RD_DATA, CACHE_PHYS_ADDR, CC_DATA_WR_MASK_DEFAULT,
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], {NUM_WAYS{1'b1}},
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {INDEX_WIDTH+WAY_WIDTH{1'b0}}, 1'b0);
        check_wr_data(({{96{1'b0}}, DATA_driver}) << 96);
        
        DATA_driver                 <= {BUS_BIT_WIDTH{1'bz}};
        DATA_driver_enable          <= 1'b0;
        DATA_VALID_BAR              <= 1'b1;

        #(CYCLE_TIME);
        check_stream_buffer({DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]});
        #(CYCLE_TIME);

        CACHE_PHYS_ADDR            <= CACHE_PHYS_ADDR_SAVED + 1;
        CACHE_PHYS_ADDR_SAVED      <= CACHE_PHYS_ADDR_SAVED + 1;
        CACHE_MISS                 <= 1'b1;

        #(2 * CYCLE_TIME);
        check(3'b111, {MEM_ADDR_WIDTH{1'bz}}, 3'd0, 1'b1, 1'b0, {DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]},
              CACHE_PHYS_ADDR, ~(128'd15 << ((NUM_WAYS) * ({CACHE_PHYS_ADDR[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}))),
              CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], ~(4'd1 << (CACHE_VICT_WAY)),
              CACHE_PHYS_ADDR_SAVED[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7], 1'b1, 
              {CACHE_PHYS_ADDR_SAVED[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY}, 1'b1);
        check_wr_data({DATA_BUS_SAVED[7], DATA_BUS_SAVED[6], DATA_BUS_SAVED[5], DATA_BUS_SAVED[4]});
      end
    end



  
    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
    
    $finish;
end

endmodule