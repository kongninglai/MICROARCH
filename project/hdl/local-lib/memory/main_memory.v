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

  parameter CLK_SPACING=3

) (
  input                       mem_clk, rst,
  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE, CE,
  inout [RANK_BIT_WIDTH-1:0]  DIO
);


  wire [0:(CLK_SPACING*BURST_SIZE-1)] OE_P;

  assign OE_P[0] = OE;

  genvar delay_idx;
  generate
    for (delay_idx = 1; delay_idx < CLK_SPACING*BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN
      dff$    OE_P_delays(mem_clk, OE_P[delay_idx-1], OE_P[delay_idx], , 1'b1, rst);
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
        neq_4b   neq_4b_0(RANK_GROUP_WIRE,
                          A[$clog2(CHIPS_PER_RANK)+RANK_IDX_WIDTH-1:$clog2(CHIPS_PER_RANK)+$clog2(BURST_SIZE)],
                          inactive_rank_group);
      end


      for (rank_idx = 0; rank_idx < BURST_SIZE; rank_idx = rank_idx + 1) begin : rank_generation
        wire   [$clog2(BURST_SIZE)-1:0] RANK_IDX_WIRE;
        assign                          RANK_IDX_WIRE = rank_idx;

        
        wire    WR_gated, CE_gated, inactive_rank, inactive_rank_pos;

        neq_2b  neq_2b_0(RANK_IDX_WIRE, A[$clog2(CHIPS_PER_RANK)+$clog2(BURST_SIZE)-1:$clog2(CHIPS_PER_RANK)], inactive_rank_pos);

        or2$ or2$(inactive_rank, inactive_rank_pos, inactive_rank_group);

        or2$  or2$_rank(  WR_gated,
                          WR,
                          inactive_rank);

        wire OE_group_gated;
        or2$  or2$_0(     OE_group_gated,
                          OE_P[CLK_SPACING*(RANK_IDX_WIRE[$clog2(BURST_SIZE)-1:0])],
                          inactive_rank_group);

        wire CE_final;
        xnor2$ xnor2$_CE_final(CE_final, OE_group_gated, WR_gated);

        rank #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) 
            rank_inst   ( 
                          .A(A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)+$clog2(RANK_COUNT)]),
                          .DIO(DIO),
                          .OE(OE_group_gated),
                          .WR(WR_gated),
                          .CE(CE_final)
                        );
      end
    end
  endgenerate
  
endmodule