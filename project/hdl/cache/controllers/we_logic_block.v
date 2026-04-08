module we_logic_block #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15,
  parameter   NUM_SETS=8,
  parameter   INDEX_WIDTH=$clog2(NUM_SETS),
  parameter   NUM_WAYS=4,
  parameter   WAY_WIDTH=$clog2(NUM_WAYS)
) (           
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         CACHE_VICT_WAY,

  output    [NUM_WAYS*RANK_BURST_SIZE-1:0]          DATA_WR_MASK_OUT,
  output    [NUM_WAYS*RANK_BURST_SIZE-1:0]          SB_DATA_WR_MASK_OUT,

  output    [NUM_WAYS-1:0]                          TAG_WR_MASK_OUT,

  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             VALID_WR_EN
);

wire [NUM_WAYS*RANK_BURST_SIZE-1:0] DATA_WR_MASK_OUT_UNINVERTED, SB_DATA_WR_MASK_OUT_UNINVERTED;

wire [WAY_WIDTH-1:0] CACHE_VICT_WAY_buf16;
bufferH16$    bufferH16$_CACHE_VICT_WAY_buf16[WAY_WIDTH-1:0](CACHE_VICT_WAY_buf16, CACHE_VICT_WAY);

lshf_chunks_var_16b #(.SHF_ZEROS(1))
lshf_chunks_var_16b_DATA_WR_MASK_OUT_UNINVERTED(
  .in(16'd1),
  .shf_amt(CACHE_VICT_WAY_buf16),
  .out(DATA_WR_MASK_OUT_UNINVERTED)
);

lshf_chunks_var_16b #(.SHF_ZEROS(1))
lshf_chunks_var_16b_SB_DATA_WR_MASK_OUT_UNINVERTED(
  .in(16'd15),
  .shf_amt(CACHE_VICT_WAY_buf16),
  .out(SB_DATA_WR_MASK_OUT_UNINVERTED)
);

inv1$   inv1$_DATA_WR_MASK_OUT[NUM_WAYS*RANK_BURST_SIZE-1:0](DATA_WR_MASK_OUT, DATA_WR_MASK_OUT_UNINVERTED);
inv1$   inv1$_SB_DATA_WR_MASK_OUT[NUM_WAYS*RANK_BURST_SIZE-1:0](SB_DATA_WR_MASK_OUT, SB_DATA_WR_MASK_OUT_UNINVERTED);

decoder2_4$   decoder2_4$_TAG_WR_MASK_OUT(.SEL(CACHE_VICT_WAY_buf16), .Y(), .YBAR(TAG_WR_MASK_OUT));

assign VALID_WR_EN          = {CACHE_PHYS_ADDR[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE], CACHE_VICT_WAY_buf16};

endmodule