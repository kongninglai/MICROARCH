module main_memory_behav #(
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
  parameter RANK_GROUP_WIDTH=$clog2(RANK_GROUP_COUNT)

) (
  input                       mem_clk, rst,
  input [MEM_ADDR_WIDTH-1:0]  A,
	input                       WR, OE, CE,

  inout [RANK_BIT_WIDTH-1:0]  DIO
);

  wire [0:(BURST_SIZE-1)] OE_P, CE_P;

  assign OE_P[0] = OE;

  genvar delay_idx;
  generate
    for (delay_idx = 1; delay_idx < BURST_SIZE; delay_idx = delay_idx + 1) begin : DELAY_GEN
      dff$    OE_P_delays(mem_clk, OE_P[delay_idx-1], OE_P[delay_idx], , rst, 1'b1);
    end
  endgenerate

  reg [CHIP_BIT_WIDTH-1:0] memory [0:MEM_BYTE_CAPACITY-1];

  always @(*) begin
    if ((WR == 1'b0)) begin
      memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b00}] <= DIO[7:0];
      memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b01}] <= DIO[15:8];
      memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b10}] <= DIO[23:16];
      memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b11}] <= DIO[31:24];
    end
  end

  assign DIO =
  ((~&OE_P))
    ? {
        memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b11}], 
        memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b10}], 
        memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b01}], 
        memory[{A[MEM_ADDR_WIDTH-1:$clog2(CHIPS_PER_RANK)], 2'b00}] 
      }
    : {RANK_BIT_WIDTH{1'bz}};

endmodule