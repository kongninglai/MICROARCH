module we_logic_block_behav #(
  parameter   RANK_BIT_WIDTH    = 128,
  parameter   BUS_BIT_WIDTH     = 32,
  parameter   RANK_BURST_SIZE   = 4,
  parameter   MEM_ADDR_WIDTH    = 15,
  parameter   NUM_SETS          = 8,
  parameter   INDEX_WIDTH       = $clog2(NUM_SETS),
  parameter   NUM_WAYS          = 4,
  parameter   WAY_WIDTH         = $clog2(NUM_WAYS)
) (           
  input      [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CACHE_PHYS_ADDR,
  input      [WAY_WIDTH-1:0]                         CACHE_VICT_WAY,

  output     [NUM_WAYS*RANK_BURST_SIZE-1:0]          DATA_WR_MASK_OUT,
  output     [NUM_WAYS*RANK_BURST_SIZE-1:0]          SB_DATA_WR_MASK_OUT,

  output     [NUM_WAYS-1:0]                          TAG_WR_MASK_OUT,

  output     [INDEX_WIDTH+WAY_WIDTH-1:0]             VALID_WR_EN
);

wire [NUM_WAYS*RANK_BURST_SIZE-1:0] data_uninverted;
wire [NUM_WAYS*RANK_BURST_SIZE-1:0] sb_data_uninverted;

assign data_uninverted =
  {{(NUM_WAYS*RANK_BURST_SIZE-1){1'b0}},1'b1}
  << (CACHE_VICT_WAY * RANK_BURST_SIZE);

assign sb_data_uninverted =
  {{(NUM_WAYS*RANK_BURST_SIZE-4){1'b0}},4'd15}
  << (CACHE_VICT_WAY * RANK_BURST_SIZE);

assign DATA_WR_MASK_OUT    = ~data_uninverted;
assign SB_DATA_WR_MASK_OUT = ~sb_data_uninverted;

assign TAG_WR_MASK_OUT     = ~(1 << CACHE_VICT_WAY);

assign VALID_WR_EN =
  {CACHE_PHYS_ADDR[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY};

endmodule