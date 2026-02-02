module dma_disk_buffer (
  input              clk, rst, start_xfer,
  input      [31:0]  disk_addr,
  input      [7:0]   buf_addr,

  output reg         buf_valid,
  output reg         busy,

  output     [127:0] buf_data
);

reg [7:0] buffer [0:4095];

function [7:0] disk_read_byte;
  input [31:0] disk_addr;
  input [11:0] offset;
  begin
    disk_read_byte = disk_addr[7:0] ^ offset[7:0];
  end
endfunction

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin : BUF_READ
    assign buf_data[((i+1)*8)-1:i*8] = buffer[{buf_addr, 4'b0000} + i];
  end
endgenerate

integer idx;
always @(posedge clk) begin
  if (~rst) begin
    busy      <= 1'b0;
    buf_valid <= 1'b0;
  end else if (start_xfer && !busy) begin
    busy      <= 1'b1;
    buf_valid <= 1'b0;
    #(750);
    for (idx = 0; idx < 4096; idx = idx + 1)
      buffer[idx] = disk_read_byte(disk_addr, idx[11:0]);
    buf_valid <= 1'b1;
    busy      <= 1'b0;
  end
end

endmodule