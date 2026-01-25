module main_memory #(
  parameter MEM_BYTE_CAPACITY=1024,
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

  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK)
) (

  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE, CE,
  inout [RANK_BIT_WIDTH-1:0]  DIO
);


  genvar rank_idx;

  generate
    for (rank_idx = 0; rank_idx < RANK_COUNT; rank_idx = rank_idx + 1) begin : rank_generation
      wire   [RANK_IDX_WIDTH-1:0] RANK_IDX_WIRE;
      assign                      RANK_IDX_WIRE = rank_idx;
      rank #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) 
          rank_inst   ( 
                        .A(A),
                        .DIO(DIO),
                        .OE(OE),
                        .WR(WR),
                        .CE(CE),
                        .RANK_IDX(RANK_IDX_WIRE)
                      );
    end
  endgenerate
  
endmodule