module main_memory_behav #(
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

  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK)
) (

  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE, CE,

  inout [RANK_BIT_WIDTH-1:0]  DIO
);

  reg [CHIP_BIT_WIDTH-1:0] memory [0:MEM_BYTE_CAPACITY-1];

  always @(*) begin
    if ((CE == 1'b0) & (WR == 1'b0)) begin
      memory[{A[9:2], 2'b00}] <= DIO[7:0];
      memory[{A[9:2], 2'b01}] <= DIO[15:8];
      memory[{A[9:2], 2'b10}] <= DIO[23:16];
      memory[{A[9:2], 2'b11}] <= DIO[31:24];
    end
  end

  assign DIO =
  ((CE == 1'b0) && (WR == 1'b1) && (OE == 1'b0))
    ? {
        memory[{A[9:2], 2'b11}], 
        memory[{A[9:2], 2'b10}], 
        memory[{A[9:2], 2'b01}], 
        memory[{A[9:2], 2'b00}] 
      }
    : {RANK_BIT_WIDTH{1'bz}};

endmodule