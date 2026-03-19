module sticky_bit_fsm_behav (
  input rst, clk,
  input IO_READ_AND_NOT_FLUSH,
  input FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ,
  input FILL_BUSY,
  output STICKY
);

reg Q0;
wire D0;

assign D0 =
      (~Q0 & IO_READ_AND_NOT_FLUSH) |
      ( Q0 & ~FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ);

assign STICKY = Q0 & ~FILL_BUSY;

always @(posedge clk or negedge rst) begin
  if (!rst)
    Q0 <= 1'b0;
  else
    Q0 <= D0;
end

endmodule