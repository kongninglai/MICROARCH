module  dma_disk_buffer_tb;

initial begin
  $vcdplusfile("dma_disk_buffer_tb.dump.vpd");
  $vcdpluson(0, dma_disk_buffer_tb); 
  $vcdpluson(0, dma_disk_buffer_tb.DUT.buffer); 
end

reg           clk, rst, start_xfer;
reg   [31:0]  disk_addr, start_mem_addr;
reg   [7:0]   buf_addr;
wire          buf_valid;
wire          busy;
wire  [127:0] buf_data;

dma_disk_buffer  DUT(
  .clk(clk), .rst(rst), .start_xfer(start_xfer), .disk_addr(disk_addr), .start_mem_addr(start_mem_addr),
  .buf_addr(buf_addr), .buf_valid(buf_valid), .busy(busy), .buf_data(buf_data)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME        = 10;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task check;
  input [7:0] buf_addr_in;
  input [31:0] disk_addr_in;
  reg [127:0] buf_data_exp;
  integer j;
  reg [7:0] tmp [0:15];
  begin
    for (j = 0; j < 16; j = j + 1)
      tmp[j] = ((buf_addr_in << 4) + j[7:0]) ^ disk_addr_in[7:0];
    buf_data_exp = {tmp[15], tmp[14], tmp[13], tmp[12], tmp[11], tmp[10], tmp[9], tmp[8],
                    tmp[7], tmp[6], tmp[5], tmp[4], tmp[3], tmp[2], tmp[1], tmp[0]};
    if (buf_data !== buf_data_exp) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. buf_data_exp = %h, buf_data = %h\n", 
                $time, buf_data_exp, buf_data);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask


integer i;

initial begin
  rst = 1'b1;
  #(CYCLE_TIME);
  rst <= 1'b0;
  #(CYCLE_TIME);
  rst <= 1'b1;
  #(0.5*CYCLE_TIME);

  #(CYCLE_TIME);
  start_mem_addr <= 0;
  start_xfer <= 1'b1;
  buf_addr <= 0;
  disk_addr <= 0;
  #(CYCLE_TIME);
  start_xfer <= 1'b0;

  #(100*CYCLE_TIME);

  for (i = 0; i < 256; i = i + 1)
  begin
    buf_addr <= i[7:0];
    #(CYCLE_TIME);
    check(buf_addr, disk_addr);
  end

  #(10*CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule
