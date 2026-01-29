module main_memory #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter RANK_BIT_WIDTH=32,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),

  parameter BURST_SIZE=4,
  parameter RANK_GROUP_COUNT=RANK_COUNT/BURST_SIZE,
  parameter RANK_GROUP_WIDTH=$clog2(RANK_GROUP_COUNT),

  /* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
  // Next few parameters are in units of ns
  parameter DELAY_ADJ         = 7,
  parameter ADDR_SETUP        = 25 + DELAY_ADJ,
  parameter DATA_SETUP        = 25 + DELAY_ADJ,
  parameter CE_SETUP          = 35 + DELAY_ADJ,
  parameter DOE_TIME          = 64,
  parameter HZ_TIME           = 18,

  parameter CYCLE_TIME        = 10,

  // Next few parameters are in units of cycles
  parameter ADDR_HIZ_PROT     = 1, // Don't enable RD when ADDR comparator can still be HiZ after clock edge
  parameter RD_EN_DURATION    = ((DOE_TIME    / CYCLE_TIME)   + 1),
  parameter RD_DIS_TO_DATA_V  = CYCLE_TIME <= 17 ? 1 : 1, // This will fail miserably if you have a bad cycle time (>= 18 ns)
  parameter RD_TO_BUS_FREE    = CYCLE_TIME <= 8 ? 3 : 2, // Needed due to tHz = 17.5 ns

  // Yes, the extra + 1 should be there below in RD_CLK_SPACING
  // Need + 1 cycle for data to be valid, and then extra time to let DIO become HiZ
  parameter RD_CLK_SPACING    = ((HZ_TIME     / CYCLE_TIME)   + 1) + 1,

  parameter ADDR_EN_TO_WR_EN  = ((ADDR_SETUP  / CYCLE_TIME)   + 1),
  parameter DATA_EN_TO_WR_DIS = ((DATA_SETUP  / CYCLE_TIME)   + 1),
  parameter WR_DIS_TO_DATA_EN = 1, // Protect against DIO -> posedge WR violations   
  parameter WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1) + WR_DIS_TO_DATA_EN

) (
  input                       clk, rst,
  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE,
  inout [RANK_BIT_WIDTH-1:0]  DIO
);


  wire [0:(RD_CLK_SPACING*BURST_SIZE-1)] OE_P;
  wire [0:(WR_CLK_SPACING*BURST_SIZE-1)] WR_P;

  assign OE_P[0] = OE;
  assign WR_P[0] = WR;

  genvar delay_idx;
  generate
    for (delay_idx = 1; delay_idx < RD_CLK_SPACING*BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN_RD
      dff$    OE_P_delays(clk, OE_P[delay_idx-1], OE_P[delay_idx], , 1'b1, rst);
    end
    for (delay_idx = 1; delay_idx < WR_CLK_SPACING*BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN_WR
      dff$    WR_P_delays(clk, WR_P[delay_idx-1], WR_P[delay_idx], , 1'b1, rst);
    end
  endgenerate

  genvar rank_group, rank_idx;
  generate
    for (rank_group = 0; rank_group < RANK_GROUP_COUNT; rank_group = rank_group + 1) begin : rank_group_generation
      wire      [RANK_GROUP_WIDTH-1:0] RANK_GROUP_WIRE;
      assign                           RANK_GROUP_WIRE = rank_group;

      wire    inactive_rank_group;

      if (RANK_GROUP_WIDTH==1) begin
        assign inactive_rank_group = A[4] ^ RANK_GROUP_WIRE;
      end else begin
        neq_4b    neq_4b_inactive_rank_group
                  (
                    RANK_GROUP_WIRE,
                    A[$clog2(CHIPS_PER_RANK)+RANK_IDX_WIDTH-1:$clog2(CHIPS_PER_RANK)+$clog2(BURST_SIZE)],
                    inactive_rank_group
                  );
      end

      for (rank_idx = 0; rank_idx < BURST_SIZE; rank_idx = rank_idx + 1) begin : rank_generation
        wire   [$clog2(BURST_SIZE)-1:0] RANK_IDX_WIRE;
        assign                          RANK_IDX_WIRE = rank_idx;

        wire    WR_gated, OE_gated, CE_gated;
        or2$    or2$_WR_gated(  WR_gated,
                                WR_P[WR_CLK_SPACING*(RANK_IDX_WIRE[$clog2(BURST_SIZE)-1:0])],
                                inactive_rank_group);
        or2$    or2$_OE_gated(  OE_gated,
                                OE_P[RD_CLK_SPACING*(RANK_IDX_WIRE[$clog2(BURST_SIZE)-1:0])],
                                inactive_rank_group);
        xnor2$ xnor2$_CE_gated( CE_gated, 
                                OE_gated, 
                                WR_gated);

        rank #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) rank_inst
        ( 
          .A(A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)+$clog2(RANK_COUNT)]),
          .DIO(DIO),
          .OE(OE_gated),
          .WR(WR_gated),
          .CE(CE_gated)
        );
      end
    end
  endgenerate
  
endmodule