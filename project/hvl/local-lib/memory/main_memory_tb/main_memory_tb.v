module  main_memory_tb;

initial begin
  $vcdplusfile("main_memory_tb.dump.vpd");
  $vcdpluson(0, main_memory_tb); 
  $vcdpluson(0, main_memory_tb.REF.memory);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
end

localparam MEM_BYTE_CAPACITY=32768;
localparam MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH=8;
localparam CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT=128;
localparam CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam RANK_BIT_WIDTH=32;
localparam CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH=$clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam BURST_SIZE=4;
localparam RANK_GROUP_COUNT=RANK_COUNT/BURST_SIZE;
localparam RANK_GROUP_WIDTH=$clog2(RANK_GROUP_COUNT);
localparam CLK_SPACING=3;

reg   [MEM_ADDR_WIDTH-1:0]  A;
reg                         WR, OE, CE, mem_clk, rst;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
wire  [RANK_BIT_WIDTH-1:0]  DIO_exp = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};


integer i;

main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) DUT 
(
  .mem_clk(mem_clk), .rst(rst),
  .A(A),
	.WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO)
);

main_memory_behav #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) REF 
(
  .mem_clk(mem_clk), .rst(rst),
  .A(A),
	.WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [RANK_BIT_WIDTH-1:0]  DIO, DIO_exp;
  if (DIO !== DIO_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
              $time, DIO_exp, DIO);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

localparam CLK_TIME = 10.000;
localparam CYCLE_TIME = 70.000;
localparam CYCLE_TIME_DIV = 1000;

initial begin
  mem_clk = 0;
  forever begin
    #(CLK_TIME / 2) mem_clk = ~mem_clk;
  end
end

initial begin
  rst = 1'b1;
  
  // Apply test vectors (active low WR, OE, CE)
  // Do a write phase (sequential) and then a read back phase to check

  A                   = {MEM_ADDR_WIDTH{1'b0}};
  WR                  = 1'b1;
  OE                  = 1'b1;
  CE                  = 1'b1;
  DIO_driver_enable   = 1'b0;
  DIO_driver          = {RANK_BIT_WIDTH{1'bz}};

  #(1.5*CLK_TIME);

  // Write phase
  for (i = 0; i < MEM_BYTE_CAPACITY; i = i + 1) begin
    
    #(CYCLE_TIME);
    A = i;

    DIO_driver_enable = 1'b1;
    DIO_driver = i;

    #(CYCLE_TIME);
    CE <= 1'b0;
    WR <= 1'b0;
    OE <= 1'b1;

    #(CYCLE_TIME);
    WR <= 1'b1;
    CE <= 1'b1;

  end


  // Stop write
  #(CYCLE_TIME);
  WR          <= 1'b1;
  CE          <= 1'b1;
  DIO_driver_enable <= 1'b0;
  DIO_driver  <= {RANK_BIT_WIDTH{1'bz}};
  #(CYCLE_TIME);

  // Read back
  for (i = 0; i < MEM_BYTE_CAPACITY; i = i + 1) begin

    // A  <= i[MEM_ADDR_WIDTH-1:0];
    A  <= i;
    CE <= 1'b0;
    WR <= 1'b1;
    OE <= 1'b0;
    #(CYCLE_TIME);
    CE <= 1'b1;
    WR <= 1'b1;
    OE <= 1'b1;

    if ((i >> $clog2(CHIPS_PER_RANK)) % (RANK_GROUP_WIDTH) == 0) begin
      check(DIO, DIO_exp);
      #((BURST_SIZE*CLK_SPACING)*CLK_TIME);
    end else begin
      #(CLK_SPACING*CLK_TIME*(((i >> $clog2(CHIPS_PER_RANK)) % (RANK_GROUP_WIDTH))));
      check(DIO, DIO_exp);
      #(((BURST_SIZE*CLK_SPACING)-(CLK_SPACING*(((i >> $clog2(CHIPS_PER_RANK)) % (RANK_GROUP_WIDTH)))))*CLK_TIME);
    end
  end

  #(CYCLE_TIME);
  CE <= 1'b1;
  OE <= 1'b1;

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule