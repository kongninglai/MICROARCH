module  rank_tb;

initial begin
  $vcdplusfile("rank_tb.dump.vpd");
  $vcdpluson(0, rank_tb); 
  $vcdpluson(0, rank_tb.REF.rank_mem); 
  $vcdpluson(0, rank_tb.DUT.chip_generation[0].sram128x8$_inst.mem); 
  $vcdpluson(0, rank_tb.DUT.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, rank_tb.DUT.chip_generation[2].sram128x8$_inst.mem); 
  $vcdpluson(0, rank_tb.DUT.chip_generation[3].sram128x8$_inst.mem); 
end

localparam MEM_BYTE_CAPACITY=32768;
localparam MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH=8;
localparam CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT=128;
localparam CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam RANK_BIT_WIDTH=32;
localparam CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH=$clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);

reg   [MEM_ADDR_WIDTH-1:0]  A;
reg                         WR, OE, CE;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;
reg   [7:0]                 byte_val;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
wire  [RANK_BIT_WIDTH-1:0]  DIO_exp = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};

integer i;

rank #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) DUT(
  .A(A),
	.WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO)
);

rank_behav #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) REF(
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

localparam CYCLE_TIME = 500;

reg clk;
initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2) clk = ~clk;
  end
end

initial begin
  
  // Apply test vectors (active low WR, OE, CE)
  // Do a write phase (sequential) and then a read back phase to check

  A                   = {MEM_ADDR_WIDTH{1'b0}};
  WR                  = 1'b1;
  OE                  = 1'b1;
  CE                  = 1'b1;
  DIO_driver_enable   = 1'b0;
  DIO_driver          = {RANK_BIT_WIDTH{1'bz}};

  byte_val = 8'h00;

  #(1.5*CYCLE_TIME);

  // Write phase
  for (i = 0; i < MEM_BYTE_CAPACITY; i = i + 4) begin
    
    #(CYCLE_TIME);
    A = i[MEM_ADDR_WIDTH-1:0];
    DIO_driver_enable = 1'b1;
    DIO_driver[31:24] = byte_val + 3;
    DIO_driver[23:16] = byte_val + 2;
    DIO_driver[15:8] = byte_val + 1;
    DIO_driver[7:0] = byte_val + 0;
    byte_val = byte_val + 4;

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

  // Read back
  for (i = 0; i < MEM_BYTE_CAPACITY; i = i + 4) begin
    #(CYCLE_TIME);

    A  <= i[MEM_ADDR_WIDTH-1:0];
    CE <= 1'b0;
    WR <= 1'b1;
    OE <= 1'b0;

    #(CYCLE_TIME/2);
    check(DIO, DIO_exp);
    #(CYCLE_TIME/2);
  end

  #(CYCLE_TIME);
  CE <= 1'b1;
  OE <= 1'b1;

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule