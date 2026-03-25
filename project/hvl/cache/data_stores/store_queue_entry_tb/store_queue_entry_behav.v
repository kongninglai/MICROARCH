module store_queue_entry_behav #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,

  parameter PHYS_LINE_BIT_WIDTH=MEM_ADDR_WIDTH-RANK_BURST_SIZE,

  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,
  parameter PHYS_ADDR_TOP_BIT=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH-1
) (
  input                               clk,
  input                               rst_n,
  input                               wr,
  input                               rd,
  input       [ENTRY_BIT_WIDTH-1:0]   data_in,

  output reg                          pending,
  output reg  [ENTRY_BIT_WIDTH-1:0]   data_out
);

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    data_out <= {ENTRY_BIT_WIDTH{1'b0}};
    pending  <= 1'b0;
  end else begin
    if (wr)
      data_out <= data_in;
    if (wr || rd)
      pending <= ~rd;
  end
end

endmodule