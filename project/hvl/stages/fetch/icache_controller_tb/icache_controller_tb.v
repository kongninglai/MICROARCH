module icache_controller_tb;

initial begin
    $vcdplusfile("icache_controller_tb.dump.vpd");
    $vcdpluson(0, icache_controller_tb); 
    $vcdpluson(0, icache_controller_tb.DUT); 
end

localparam RANK_BIT_WIDTH           = 128;
localparam BUS_BIT_WIDTH            = 32;
localparam RANK_BURST_SIZE          = 4;
localparam MEM_ADDR_WIDTH           = 15;
localparam NUM_SETS                 = 8;
localparam INDEX_WIDTH              = $clog2(NUM_SETS);
localparam NUM_WAYS                 = 4;
localparam WAY_WIDTH                = $clog2(NUM_WAYS);
localparam TAG_WIDTH                = 8;
localparam V_CT_CACHE_FILL_DONE     = 2;
localparam V_CT_SB_FILL_DONE        = 6;

localparam CYCLE_TIME               = 10.0;
localparam MASK_WIDTH               = NUM_SETS * NUM_WAYS * RANK_BURST_SIZE;

reg  clk, rst;

reg  [BUS_BIT_WIDTH-1:0]    DATA_driver;
reg                         DATA_driver_enable;
wire [BUS_BIT_WIDTH-1:0]    DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};

reg                         IC_MEM_RD_ACK;
reg                         DATA_VALID_BAR;
wire [MEM_ADDR_WIDTH-1:0]   ADDR_BUS;
wire                        IC_MEM_RD_RQ;

reg                         ICACHE_MISS;
reg  [RANK_BIT_WIDTH-1:0]   ICACHE_RD_DATA;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICACHE_PHYS_ADDR;
reg  [WAY_WIDTH-1:0]        ICACHE_VICT_WAY;
reg  [MASK_WIDTH-1:0]       ICC_DATA_WR_MASK_DEFAULT;

wire                        ICC_STREAM_BUF_HIT, ICC_FSM_FILL_BUSY;
wire [RANK_BIT_WIDTH-1:0]   ICC_WR_DATA_OUT, ICC_HIT_DATA_OUT;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] ICC_ADDR_OUT;
wire [MASK_WIDTH-1:0]       ICC_DATA_WR_MASK_OUT;

wire [INDEX_WIDTH-1:0]      ICC_TAG_VALID_SET_INDEX;
wire [NUM_WAYS-1:0]         ICC_TAG_WR_MASK_OUT;
wire [TAG_WIDTH-1:0]        ICC_TAG_IN;
wire                        ICC_VALID_SET_OR_CLR;
wire [INDEX_WIDTH+WAY_WIDTH-1:0] ICC_VALID_WR_EN;
wire                        ICC_FSM_VALID_WR_EN_GLOBAL;

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

initial begin
    rst                         <= 1'b0; 
    IC_MEM_RD_ACK               <= 1'b0;
    DATA_VALID_BAR              <= 1'b1;
    DATA_driver                 <= {BUS_BIT_WIDTH{1'bz}};
    DATA_driver_enable          <= 1'b0;
    ICACHE_MISS                 <= 1'b0;
    ICACHE_RD_DATA              <= {RANK_BIT_WIDTH{1'b0}};
    ICACHE_PHYS_ADDR            <= {11{1'b1}};
    ICACHE_VICT_WAY             <= {WAY_WIDTH{1'b0}};
    ICC_DATA_WR_MASK_DEFAULT    <= {MASK_WIDTH{1'b0}};

    #(2 * CYCLE_TIME);
    rst <= 1'b1;
    #(CYCLE_TIME);

    IC_MEM_RD_ACK               <= 1'b1;
    DATA_VALID_BAR              <= 1'b1;
    DATA_driver                 <= 32'h12345678;
    DATA_driver_enable          <= 1'b1;
    
    ICACHE_PHYS_ADDR            <= {11{1'b1}};
    ICACHE_VICT_WAY             <= 2'b01;
    ICC_DATA_WR_MASK_DEFAULT    <= {128{1'b1}};
    ICACHE_MISS                 <= 1'b1;

    @(posedge IC_MEM_RD_RQ);
    @(posedge clk);
    #(4 * CYCLE_TIME);
    DATA_VALID_BAR              <= 1'b0;

    #(30 * CYCLE_TIME);

  
    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
    
    $finish;
end

endmodule