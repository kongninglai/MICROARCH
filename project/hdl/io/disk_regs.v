module disk_regs #(
  parameter MEM_BYTE_CAPACITY = 32768,
  parameter BURST_SIZE=4,
  /* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
  // Next few parameters are in units of ns
  parameter DELAY_ADJ         = 7,
  parameter ADDR_SETUP        = 25 + DELAY_ADJ,
  parameter DATA_SETUP        = 25 + DELAY_ADJ,
  parameter CE_SETUP          = 35,
  parameter DOE_TIME          = 64,
  parameter HZ_TIME           = 18,

  parameter CYCLE_TIME        = 10,

  // Next few parameters are in units of cycles
  parameter ADDR_HIZ_PROT     = 1, // Don't enable RD when ADDR comparator can still be HiZ after clock edge
  parameter RD_EN_DURATION    = ((DOE_TIME    / CYCLE_TIME)   + 1),
  parameter RD_DIS_TO_DATA_V  = CYCLE_TIME <= 17 ? 1 : 1, // This will fail miserably if you have a bad cycle time (>= 18 ns)
  parameter RD_TO_BUS_FREE    = CYCLE_TIME <= 8 ? 2 : 1, // Needed due to tHz

  // Yes, the extra + 1 should be there below in RD_CLK_SPACING
  // Need + 1 cycle for data to be valid, and then extra time to let DIO become HiZ
  parameter RD_CLK_SPACING    = ((HZ_TIME     / CYCLE_TIME)   + 1) + 1,

  parameter ADDR_EN_TO_WR_EN  = ((ADDR_SETUP  / CYCLE_TIME)   + 1),
  parameter DATA_EN_TO_WR_DIS = ((DATA_SETUP  / CYCLE_TIME)   + 1),
  parameter WR_DIS_TO_DATA_EN = 1, // Protect against DIO -> posedge WR violations   
  parameter WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1) + WR_DIS_TO_DATA_EN,


  parameter V_CT_HIZ_PROT     = ADDR_HIZ_PROT - 1,
  parameter V_CT_RD_EN        = RD_EN_DURATION - 1,
  parameter V_CT_RD_BRST      = (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1,
  parameter V_CT_BUS_FREE     = RD_TO_BUS_FREE - 1,

  parameter V_CT_DRIVE_STAT   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) + RD_TO_BUS_FREE - 1,
  parameter V_CT_DRIVE_DATA   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1,
  parameter V_CT_CLR_RDY      = RD_TO_BUS_FREE - 1
) (
  input               rst, clk,
  input     [15:0]    WR_mask,
	input               WR, OE,
  inout     [31:0]    DIO,
  output    [127:0]   DMA_config
);

wire [0:((RD_EN_DURATION)+RD_CLK_SPACING*BURST_SIZE-1)] OE_P;
wire [0:(WR_CLK_SPACING*BURST_SIZE-1)] WR_P;
wire [15:0] WR_mask_P [0:(WR_CLK_SPACING*BURST_SIZE-1)] ;

assign OE_P[0]      = OE;
assign WR_P[0]      = WR;
assign WR_mask_P[0] = WR_mask;

genvar delay_idx;
generate
  for (delay_idx = 1; delay_idx < (RD_EN_DURATION)+RD_CLK_SPACING*BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN_RD
    dff$    OE_P_delays(clk, OE_P[delay_idx-1], OE_P[delay_idx], , 1'b1, rst);
  end
  for (delay_idx = 1; delay_idx < WR_CLK_SPACING*BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN_WR
    dff$    WR_mask_P_delays[15:0](clk, WR_mask_P[delay_idx-1], WR_mask_P[delay_idx], , 1'b1, rst);
    dff$    WR_P_delays(clk, WR_P[delay_idx-1], WR_P[delay_idx], , 1'b1, rst);
  end
endgenerate

genvar rank_idx;


for (rank_idx = 0; rank_idx < BURST_SIZE; rank_idx = rank_idx + 1) begin : rank_generation
  wire   [$clog2(BURST_SIZE)-1:0] RANK_IDX_WIRE;
  assign                          RANK_IDX_WIRE = rank_idx;

  wire    [15:0] WR_mask_gated;
  wire    OE_gated;

  assign WR_mask_gated  = WR_mask_P[WR_CLK_SPACING*(RANK_IDX_WIRE[$clog2(BURST_SIZE)-1:0])];
  assign OE_gated       = OE_P[(RD_EN_DURATION)+RD_CLK_SPACING*(RANK_IDX_WIRE[$clog2(BURST_SIZE)-1:0])];

  disk_rank one_disk_reg(.WR(WR_mask_gated[(4*(rank_idx) + 3):(4*rank_idx)]), .rst(rst), .OE(OE_gated), .DIO(DIO),
                         .DMA_config(DMA_config[(32*(rank_idx) + 31):(32*rank_idx)]));
end
  
endmodule