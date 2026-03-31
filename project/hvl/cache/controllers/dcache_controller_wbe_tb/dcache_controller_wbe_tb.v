module dcache_controller_wbe_tb;

initial begin
    // $vcdplusfile("dcache_controller_wbe_tb.dump.vpd");
    // $vcdpluson(0, dcache_controller_wbe_tb);
    // $vcdpluson(0, dcache_controller_wbe_tb.DUT);
end

localparam RANK_BIT_WIDTH               = 128;
localparam BUS_BIT_WIDTH                = 32;
localparam RANK_BURST_SIZE              = 4;
localparam MEM_ADDR_WIDTH               = 15;
localparam CHIPS_PER_RANK               = 16;
localparam CYCLE_TIME                   = 10.0;

reg                                     clk;
reg                                     rst;

reg                                     DC_MEM_WR_ACK;
reg                                     DC_DMA_WR_ACK;
reg                                     DC_KB_WR_ACK;
reg                                     DCACHE_NEED_WR_BUS;
reg  [RANK_BIT_WIDTH-1:0]               DCACHE_WBE_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] DCACHE_PHYS_ADDR;
reg  [CHIPS_PER_RANK-1:0]               DCACHE_WR_MASK;
reg  [2:0]                              KB_PFN;
reg  [2:0]                              DMA_PFN;

wire [CHIPS_PER_RANK-1:0]               WR_mask;
wire [MEM_ADDR_WIDTH-1:0]               ADDR_BUS;
wire [BUS_BIT_WIDTH-1:0]                DATA_BUS;

wire                                    DC_MEM_WR_RQ;
wire                                    DC_DMA_WR_RQ;
wire                                    DC_KB_WR_RQ;
wire                                    WBE_BUSY;

wire ANY_RQ = DC_MEM_WR_RQ | DC_DMA_WR_RQ | DC_KB_WR_RQ;

integer FAILURES = 0;
integer SUCCESSES = 0;

initial begin
    clk = 0;
    forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

dcache_controller_wbe #(
    .RANK_BIT_WIDTH                 (RANK_BIT_WIDTH),
    .BUS_BIT_WIDTH                  (BUS_BIT_WIDTH),
    .RANK_BURST_SIZE                (RANK_BURST_SIZE),
    .MEM_ADDR_WIDTH                 (MEM_ADDR_WIDTH),
    .CHIPS_PER_RANK                 (CHIPS_PER_RANK)
) DUT (
    .clk                            (clk),
    .rst                            (rst),
    .DC_MEM_WR_ACK                  (DC_MEM_WR_ACK),
    .DC_DMA_WR_ACK                  (DC_DMA_WR_ACK),
    .DC_KB_WR_ACK                   (DC_KB_WR_ACK),
    .DCACHE_NEED_WR_BUS             (DCACHE_NEED_WR_BUS),
    .DCACHE_WBE_DATA                (DCACHE_WBE_DATA),
    .DCACHE_PHYS_ADDR               (DCACHE_PHYS_ADDR),
    .DCACHE_WR_MASK                 (DCACHE_WR_MASK),
    .KB_PFN                         (KB_PFN),
    .DMA_PFN                        (DMA_PFN),
    .WR_mask                        (WR_mask),
    .ADDR_BUS                       (ADDR_BUS),
    .DATA_BUS                       (DATA_BUS),
    .DC_MEM_WR_RQ                   (DC_MEM_WR_RQ),
    .DC_DMA_WR_RQ                   (DC_DMA_WR_RQ),
    .DC_KB_WR_RQ                    (DC_KB_WR_RQ),
    .WBE_BUSY                       (WBE_BUSY)
);

task check_buses;
  input [MEM_ADDR_WIDTH-1:0] ADDR_EXP;
  input [CHIPS_PER_RANK-1:0] WR_MASK_EXP;
  input [BUS_BIT_WIDTH-1:0]  DATA_EXP;
  begin
    if (ADDR_BUS !== ADDR_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ADDR_BUS exp=%h got=%h", $time, ADDR_EXP, ADDR_BUS);
    end

    if (WR_mask !== WR_MASK_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: WR_mask exp=%h got=%h", $time, WR_MASK_EXP, WR_mask);
    end

    if (DATA_BUS !== DATA_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: DATA_BUS exp=%h got=%h", $time, DATA_EXP, DATA_BUS);
    end

    if (ADDR_BUS === ADDR_EXP &&
        WR_mask  === WR_MASK_EXP &&
        DATA_BUS === DATA_EXP) begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_rq;
  input [2:0] RQ_EXP;
  begin
    if ({DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_KB_WR_RQ} !== RQ_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: REQs exp=%b got=%b", $time, RQ_EXP, {DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_KB_WR_RQ});
    end
    else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end

endtask

integer i, j;

initial begin
  rst                         <= 1'b0; 

  DC_MEM_WR_ACK               <= 1'b0;
  DC_DMA_WR_ACK               <= 1'b0;
  DC_KB_WR_ACK                <= 1'b0;

  DCACHE_WBE_DATA             <= {$random, $random, $random, $random};
  DCACHE_PHYS_ADDR            <= {$random};
  DCACHE_NEED_WR_BUS          <= 1'b0;

  DCACHE_WR_MASK              <= {CHIPS_PER_RANK{1'b0}};
  DMA_PFN                     <= 3'd1;
  KB_PFN                      <= 3'd3;

  #(1.5 * CYCLE_TIME);
  rst <= 1'b1;
  #(8 * CYCLE_TIME);

  for (i = 0; i < 2048; i = i + 1) begin
    DCACHE_WBE_DATA             <= {$random, $random, $random, $random};
    DCACHE_PHYS_ADDR            <= i[10:0];
    DCACHE_WR_MASK              <= $random;
    DCACHE_NEED_WR_BUS          <= 1'b1;
    @(posedge ANY_RQ);
    @(posedge clk);
    DCACHE_NEED_WR_BUS          <= 1'b0;
    case ({DC_MEM_WR_RQ,DC_DMA_WR_RQ,DC_KB_WR_RQ})
      3'b100: DC_MEM_WR_ACK <= 1'b1;
      3'b010: DC_DMA_WR_ACK <= 1'b1;
      3'b001: DC_KB_WR_ACK  <= 1'b1;
    endcase
    check_rq({DCACHE_PHYS_ADDR[14:12] != DMA_PFN && DCACHE_PHYS_ADDR[14:12] != KB_PFN,
              DCACHE_PHYS_ADDR[14:12] == DMA_PFN,   DCACHE_PHYS_ADDR[14:12] == KB_PFN});
    #(CYCLE_TIME);
    
    DC_MEM_WR_ACK               <= 1'b0;
    DC_DMA_WR_ACK               <= 1'b0;
    DC_KB_WR_ACK                <= 1'b0;

    for (j = 0; j < 4; j = j + 1) begin
      #(CYCLE_TIME);
      check_buses({DCACHE_PHYS_ADDR, 4'b0000}, DCACHE_WR_MASK, DCACHE_WBE_DATA[j*BUS_BIT_WIDTH +: BUS_BIT_WIDTH]);
    end

  end

  #(8 * CYCLE_TIME);
  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule