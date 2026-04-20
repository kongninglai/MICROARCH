module iq_de_to_rr_entry #(
  parameter ENTRY_BIT_WIDTH = 221
) (
  input                           clk,
  input                           rst_n,
  input                           wr,
  input   [ENTRY_BIT_WIDTH-1:0]   data_in,

  output  [ENTRY_BIT_WIDTH-1:0]   data_out
);

reg_n #(
  .WIDTH(ENTRY_BIT_WIDTH)
) reg_n_data_out (
  .clk(clk), .rst(rst_n),
  .en({ENTRY_BIT_WIDTH{wr}}), .d(data_in),
  .q(data_out)
);

endmodule
