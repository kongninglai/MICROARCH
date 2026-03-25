module store_queue_entry #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,

  parameter PHYS_LINE_BIT_WIDTH=MEM_ADDR_WIDTH-RANK_BURST_SIZE,

  /**
    * ORDER (MSB to LSB):
    * 
    * PENDING      - alone
    *
    * DATA         - [154:27]
    * PHYS_ADDR    - [26:16]
    * DATA_WR_MASK - [15:0]
    *
    **/
  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,
  parameter PHYS_ADDR_TOP_BIT=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH-1
) (
  input                           clk,
  input                           rst_n,
  input                           wr,
  input                           rd,
  input   [ENTRY_BIT_WIDTH-1:0]   data_in,

  output                          pending,
  output  [ENTRY_BIT_WIDTH-1:0]   data_out
);

wire    wr_buf256;
bufferH256$   bufferH256$_wr_buf256(wr_buf256, wr);

reg_n #(
  .WIDTH(ENTRY_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_data_out (
  .clk(clk), .rst(rst_n),
  .en({ENTRY_BIT_WIDTH{wr_buf256}}), .d(data_in),
  .q(data_out)
);

wire    pending_en;
or2$    or2$_pending_en(pending_en, rd, wr);

wire    next_pending;
inv1$   inv1$_next_pending(next_pending, rd);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_pending (
  .clk(clk), .rst(rst_n),
  .en(pending_en), .d(next_pending),
  .q(pending)
);

endmodule