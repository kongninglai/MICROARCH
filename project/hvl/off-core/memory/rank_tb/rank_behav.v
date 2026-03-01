module rank_behav #(
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
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK)

) (
  input [CHIPS_PER_RANK*RANK_ADDR_WIDTH-1:0]    A,
  input [CHIPS_PER_RANK-1:0]                    WR,
	input [CHIPS_PER_RANK-1:0]                    OE, CE,
	inout [RANK_BIT_WIDTH-1:0]                    DIO 
);
  
reg [RANK_BIT_WIDTH-1:0] rank_mem [0:CHIP_ROW_COUNT];

integer k;
always @(CE, WR) begin
  for (k = 0; k < CHIPS_PER_RANK; k = k + 1) begin
    if (!CE[k] && !WR[k]) begin
      rank_mem[A[RANK_ADDR_WIDTH-1:0]]
        [k*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH]
        <= DIO[k*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH];
    end
  end
end

genvar i;
generate
  for (i = 0; i < CHIPS_PER_RANK; i = i + 1) begin : GEN_DIO
    assign DIO[i*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH] =
      (!CE[i] && WR[i] && !OE[i])
      ? rank_mem[A[RANK_ADDR_WIDTH-1:0]]
          [i*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH]
      : {CHIP_BIT_WIDTH{1'bz}};
  end
endgenerate

endmodule