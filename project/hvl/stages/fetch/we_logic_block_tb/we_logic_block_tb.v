module we_logic_block_tb;

initial begin
  $vcdplusfile("we_logic_block_tb.dump.vpd");
  $vcdpluson(0, we_logic_block_tb);
end

localparam RANK_BIT_WIDTH  = 128;
localparam BUS_BIT_WIDTH   = 32;
localparam RANK_BURST_SIZE = 4;
localparam MEM_ADDR_WIDTH  = 15;
localparam NUM_SETS        = 8;
localparam INDEX_WIDTH     = $clog2(NUM_SETS);
localparam NUM_WAYS        = 4;
localparam WAY_WIDTH       = $clog2(NUM_WAYS);
localparam CYCLE_TIME      = 10.0;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]                         ICACHE_VICT_WAY;

wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] DATA_WR_MASK_OUT;
wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] SB_DATA_WR_MASK_OUT;
wire [INDEX_WIDTH-1:0]                       TAG_VALID_SET_INDEX;
wire [NUM_WAYS-1:0]                          TAG_WR_MASK_OUT;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]             VALID_WR_EN;

wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] DATA_WR_MASK_OUT_EXP;
wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] SB_DATA_WR_MASK_OUT_EXP;
wire [INDEX_WIDTH-1:0]                       TAG_VALID_SET_INDEX_EXP;
wire [NUM_WAYS-1:0]                          TAG_WR_MASK_OUT_EXP;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]             VALID_WR_EN_EXP;

we_logic_block #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .NUM_SETS(NUM_SETS),
  .NUM_WAYS(NUM_WAYS)
) DUT (
  .ICACHE_PHYS_ADDR(ICACHE_PHYS_ADDR),
  .ICACHE_VICT_WAY(ICACHE_VICT_WAY),
  .DATA_WR_MASK_OUT(DATA_WR_MASK_OUT),
  .SB_DATA_WR_MASK_OUT(SB_DATA_WR_MASK_OUT),
  .TAG_VALID_SET_INDEX(TAG_VALID_SET_INDEX),
  .TAG_WR_MASK_OUT(TAG_WR_MASK_OUT),
  .VALID_WR_EN(VALID_WR_EN)
);

we_logic_block_behav #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .NUM_SETS(NUM_SETS),
  .NUM_WAYS(NUM_WAYS)
) REF (
  .ICACHE_PHYS_ADDR(ICACHE_PHYS_ADDR),
  .ICACHE_VICT_WAY(ICACHE_VICT_WAY),
  .DATA_WR_MASK_OUT(DATA_WR_MASK_OUT_EXP),
  .SB_DATA_WR_MASK_OUT(SB_DATA_WR_MASK_OUT_EXP),
  .TAG_VALID_SET_INDEX(TAG_VALID_SET_INDEX_EXP),
  .TAG_WR_MASK_OUT(TAG_WR_MASK_OUT_EXP),
  .VALID_WR_EN(VALID_WR_EN_EXP)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if ((DATA_WR_MASK_OUT !== DATA_WR_MASK_OUT_EXP) || 
      (SB_DATA_WR_MASK_OUT !== SB_DATA_WR_MASK_OUT_EXP) ||
      (TAG_VALID_SET_INDEX !== TAG_VALID_SET_INDEX_EXP) ||
      (TAG_WR_MASK_OUT !== TAG_WR_MASK_OUT_EXP) ||
      (VALID_WR_EN !== VALID_WR_EN_EXP)) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  ICACHE_PHYS_ADDR = %h", ICACHE_PHYS_ADDR);
    $display("  ICACHE_VICT_WAY  = %h", ICACHE_VICT_WAY);
    $display("  DATA_WR GOT = %h, EXP = %h", DATA_WR_MASK_OUT, DATA_WR_MASK_OUT_EXP);
    $display("  TAG_WR  GOT = %h, EXP = %h\n", TAG_WR_MASK_OUT, TAG_WR_MASK_OUT_EXP);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;

initial begin
  ICACHE_PHYS_ADDR = 0;
  ICACHE_VICT_WAY  = 0;

  #(CYCLE_TIME);

  for (i = 0; i < NUM_SETS; i = i + 1) begin
    for (j = 0; j < NUM_WAYS; j = j + 1) begin
      ICACHE_PHYS_ADDR = (i << RANK_BURST_SIZE);
      ICACHE_VICT_WAY  = j[WAY_WIDTH-1:0];
      #(CYCLE_TIME);
      check();
    end
  end

  for (i = 0; i < 100; i = i + 1) begin
    ICACHE_PHYS_ADDR = $random;
    ICACHE_VICT_WAY  = $random % NUM_WAYS;
    #(CYCLE_TIME);
    check();
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule