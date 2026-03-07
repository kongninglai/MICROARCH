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
  input      [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      ICACHE_PHYS_ADDR,
  input      [WAY_WIDTH-1:0]                         ICACHE_VICT_WAY,

  output     [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] DATA_WR_MASK_OUT,
  output     [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0] SB_DATA_WR_MASK_OUT,

  output     [NUM_WAYS-1:0]                          TAG_WR_MASK_OUT,

  output     [INDEX_WIDTH+WAY_WIDTH-1:0]             VALID_WR_EN
);

wire [INDEX_WIDTH-1:0]             set_index;
wire [INDEX_WIDTH+WAY_WIDTH-1:0]   combined_index;
wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0]          data_uninverted;
wire [NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-1:0]          sb_data_uninverted;

assign set_index      = ICACHE_PHYS_ADDR[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE];
assign combined_index = {set_index, ICACHE_VICT_WAY};

assign data_uninverted    = {{(NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-4){1'b0}}, 4'd1 } << (combined_index * RANK_BURST_SIZE);
assign sb_data_uninverted = {{(NUM_SETS*NUM_WAYS*RANK_BURST_SIZE-4){1'b0}}, 4'd15} << (combined_index * RANK_BURST_SIZE);

assign DATA_WR_MASK_OUT    = ~data_uninverted;
assign SB_DATA_WR_MASK_OUT = ~sb_data_uninverted;

assign TAG_WR_MASK_OUT     = ~(1 << ICACHE_VICT_WAY);

assign VALID_WR_EN         = combined_index;

endmodule