module rank #(
  parameter MEM_BYTE_CAPACITY=1024,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,

  parameter RANK_BIT_WIDTH=32,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,

  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),

  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK)
) (
  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE, CE,
  input [RANK_IDX_WIDTH-1:0]  RANK_IDX,
	inout [RANK_BIT_WIDTH-1:0]  DIO 
);

  wire    WR_gated, OE_gated, CE_gated, inactive_rank;

  generate
    if (RANK_IDX_WIDTH==1) begin
      xor2$   xor2$_0(inactive_rank, RANK_IDX, A[$clog2(CHIPS_PER_RANK)+$clog2(RANK_COUNT)-1:$clog2(CHIPS_PER_RANK)]);
    end else begin
      // Assume 6-bit rank index width otherwise (need 64 ranks for project)
      neq_6b  neq_6b_0(RANK_IDX, A[$clog2(CHIPS_PER_RANK)+$clog2(RANK_COUNT)-1:$clog2(CHIPS_PER_RANK)], inactive_rank);
    end
  endgenerate

  or2$  or2$[2:0]({WR_gated, OE_gated, CE_gated},
                  {WR,       OE,       CE      },
                  {3{inactive_rank}});
  
  genvar chip_idx;
  generate
    for (chip_idx = 0; chip_idx < CHIPS_PER_RANK; chip_idx = chip_idx + 1) begin : chip_generation
      sram128x8$ sram128x8$_inst( 
                                  .A(A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)+$clog2(RANK_COUNT)]),
                                  .DIO(DIO[CHIP_BIT_WIDTH*(chip_idx+1)-1:CHIP_BIT_WIDTH*chip_idx]),
                                  .OE(OE_gated),
                                  .WR(WR_gated),
                                  .CE(CE_gated)
                                );
    end
  endgenerate


endmodule