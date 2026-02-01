module rank_behav #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,

  parameter RANK_BIT_WIDTH=32,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK)

) (
  input [RANK_ADDR_WIDTH-1:0]   A,
  input [CHIPS_PER_RANK-1:0]    WR,
	input                         OE, CE,
	inout [RANK_BIT_WIDTH-1:0]    DIO 
);
  
  reg [RANK_BIT_WIDTH-1:0] rank_mem [0:CHIP_ROW_COUNT];

  always @(*) begin
    if ((CE == 1'b0) && (WR[3] == 1'b0)) begin
      rank_mem[A][31:24] <= DIO[31:24];
    end
    if ((CE == 1'b0) && (WR[2] == 1'b0)) begin
      rank_mem[A][23:16] <= DIO[23:16];
    end
    if ((CE == 1'b0) && (WR[1] == 1'b0)) begin
      rank_mem[A][15:8] <= DIO[15:8];
    end
    if ((CE == 1'b0) && (WR[0] == 1'b0)) begin
      rank_mem[A][7:0] <= DIO[7:0];
    end
  end

  assign DIO =
  ((CE == 1'b0) && (WR == 4'hF) && (OE == 1'b0))
    ? {
        rank_mem[A]
      }
    : {RANK_BIT_WIDTH{1'bz}};


endmodule