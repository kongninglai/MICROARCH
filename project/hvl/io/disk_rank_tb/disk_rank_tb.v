module  disk_rank_tb;

initial begin
  $vcdplusfile("disk_rank_tb.dump.vpd");
  $vcdpluson(0, disk_rank_tb);
end

localparam CHIP_BIT_WIDTH=8;

reg          rst;
reg   [3:0]  WR;
reg                         OE;
reg   [31:0]  DIO_driver;
reg                         DIO_driver_enable;
reg   [7:0]                 byte_val;

wire  [31:0]  DIO     = DIO_driver_enable ? DIO_driver : {32{1'bz}};
wire  [31:0]  DIO_exp = DIO_driver_enable ? DIO_driver : {32{1'bz}};

wire  [31:0]  DMA_config, DMA_config_exp;

integer i;

disk_rank DUT(
	.WR(WR), .rst(rst), .OE(OE),
  .DIO(DIO), .DMA_config(DMA_config)
);

disk_rank_behav REF(
	.WR(WR), .rst(rst), .OE(OE),
  .DIO(DIO_exp), .DMA_config(DMA_config_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [31:0]  DIO, DIO_exp;
  if (DIO !== DIO_exp || DMA_config !== DMA_config_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h, DMA_config_exp = %h, DMA_config = %h\n", 
              $time, DIO_exp, DIO, DMA_config_exp, DMA_config);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

localparam CYCLE_TIME = 500;

reg clk;
initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2) clk = ~clk;
  end
end

initial begin
  rst                 = 1;
  WR                  = 4'hF;
  OE                  = 1'b1;
  DIO_driver_enable   = 1'b0;
  DIO_driver          = {32{1'bz}};

  byte_val = 8'h00;

  #(1.5*CYCLE_TIME);
    
  #(CYCLE_TIME);
  DIO_driver_enable = 1'b1;
  DIO_driver[31:24] = byte_val + 3;
  DIO_driver[23:16] = byte_val + 2;
  DIO_driver[15:8] = byte_val + 1;
  DIO_driver[7:0] = byte_val + 0;
  byte_val = byte_val + 4;

  #(CYCLE_TIME);
  WR <= 4'h5;
  OE <= 1'b1;

  #(CYCLE_TIME);
  WR <= 4'hF;


  // Stop write
  #(CYCLE_TIME);
  WR          <= 4'hF;
  DIO_driver_enable <= 1'b0;
  DIO_driver  <= {32{1'bz}};

  #(CYCLE_TIME);

  WR <= 4'hF;
  OE <= 1'b0;

  #(CYCLE_TIME/2);
  check(DIO, DIO_exp);
  #(CYCLE_TIME/2);

  #(CYCLE_TIME);
  OE <= 1'b1;

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule