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
  input [RANK_ADDR_WIDTH-1:0]   A,
	input                         WR, OE, CE,
	inout [RANK_BIT_WIDTH-1:0]    DIO 
);

  
  genvar chip_idx;
  generate
    for (chip_idx = 0; chip_idx < CHIPS_PER_RANK; chip_idx = chip_idx + 1) begin : chip_generation
      sram128x8$ sram128x8$_inst( 
                                  .A(A),
                                  .DIO(DIO[CHIP_BIT_WIDTH*(chip_idx+1)-1:CHIP_BIT_WIDTH*chip_idx]),
                                  .OE(OE),
                                  .WR(WR),
                                  .CE(CE)
                                );
    end
  endgenerate


endmodule