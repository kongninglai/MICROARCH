module main_memory #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),

  /*  
      Next few parameters are in units of 1e-10 seconds (X10 turns ns (1e-9) into 1e-10).
      The point of multiplying by 10 is to allow cycle time to have increments of 0.1 ns 
      while still using integer math.
  */
  parameter ADDR_SETUP_X10            = 280,  /* Add 3 ns for state transition comb logic delay + buf256 */
  parameter CE_SETUP_X10              = 370,  /* Add 2 ns for state transition comb logic delay */
  parameter DOE_TIME_X10              = 620,  /* Add 2 ns for state transition comb logic delay */
  parameter HZ_TIME_X10               = 175,
  parameter CYCLE_TIME_X10            = 100,

  /* Next few parameters are in units of cycles */
  parameter RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1),
  parameter ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1),
  parameter WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1)

) (
  input                                                     clk, rst,
  input   [RANK_ADDR_WIDTH-1:0]                             A_RANK0, A_OTHERS,
  input   [RANK_COUNT*CHIPS_PER_RANK-1:0]                   WR, OE, CE,
  inout   [RANK_BIT_WIDTH-1:0]                              DIO
);

wire   [RANK_ADDR_WIDTH-1:0] A_RANK0_buf256, A_OTHERS_buf256;
bufferH256$   bufferH256$_A_RANK0_buf256 [RANK_ADDR_WIDTH-1:0](A_RANK0_buf256, A_RANK0);
bufferH256$   bufferH256$_A_OTHERS_buf256[RANK_ADDR_WIDTH-1:0](A_OTHERS_buf256, A_OTHERS);

wire   [RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH-1:0]  A;

assign A = {{CHIPS_PER_RANK*(RANK_COUNT-1){A_OTHERS_buf256}}, {CHIPS_PER_RANK{A_RANK0_buf256}}};

genvar rank_idx;
generate
  for (rank_idx = 1; rank_idx < RANK_COUNT; rank_idx = rank_idx + 1) begin : rank_generation
    rank #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) rank_inst
    ( 
      .A  
      (
        A 
        [
          CHIPS_PER_RANK*RANK_ADDR_WIDTH*(rank_idx+1)-1:
          CHIPS_PER_RANK*RANK_ADDR_WIDTH*(rank_idx)
        ]
      ),
      .DIO(DIO),
      .OE
      (
        OE
        [
          CHIPS_PER_RANK*(rank_idx+1)-1:
          CHIPS_PER_RANK*(rank_idx)
        ]
      ),
      .WR
      (
        WR
        [
          CHIPS_PER_RANK*(rank_idx+1)-1:
          CHIPS_PER_RANK*(rank_idx)
        ]
      ),
      .CE
      (
        CE
        [
          CHIPS_PER_RANK*(rank_idx+1)-1:
          CHIPS_PER_RANK*(rank_idx)
        ]
      )
    );
  end
endgenerate

endmodule