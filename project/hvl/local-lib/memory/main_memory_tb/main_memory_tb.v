module  main_memory_tb;

initial begin
  $vcdplusfile("main_memory_tb.dump.vpd");
  $vcdpluson(0, main_memory_tb); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
end

localparam MEM_BYTE_CAPACITY=32768;
localparam MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH=8;
localparam CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT=128;
localparam CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam BUS_BIT_WIDTH=32;
localparam RANK_BIT_WIDTH=128;
localparam RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH=$clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam ADDR_SETUP_X10               = 251;
localparam DATA_SETUP_X10               = 251;
localparam CE_SETUP_X10                 = 351;
localparam DOE_TIME_X10                 = 60;
localparam MUX16_TIME_X10               = 12;
localparam HZ_TIME_X10                  = 175;
localparam CYCLE_TIME_X10               = 2000;
localparam RD_EN_CYCLES                 = (((DOE_TIME_X10 + MUX16_TIME_X10) / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES      = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES        = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);

reg   [RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH-1:0]   A;
reg   [RANK_COUNT*CHIPS_PER_RANK-1:0]                   WR, OE, CE;
reg                                                     clk, rst;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
wire  [RANK_BIT_WIDTH-1:0]  DIO_exp = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};

integer i, j;

main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) DUT 
(
  .clk(clk), .rst(rst),
  .A(A), .WR(WR),
	.OE(OE), .CE(CE),
  .DIO(DIO)
);

main_memory_behav #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) REF 
(
  .clk(clk), .rst(rst),
  .A(A), .WR(WR),
	.OE(OE), .CE(CE),
  .DIO(DIO_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task check;
  if (DIO !== DIO_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
              $time, DIO_exp, DIO);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // Apply test vectors (active low WR, OE, CE)
  // Do a write phase (sequential) and then a read back phase to check

  A                   <= 0;
  WR                  <= {CHIP_COUNT{1'b1}};
  OE                  <= {CHIP_COUNT{1'b1}};
  CE                  <= {CHIP_COUNT{1'b1}};
  DIO_driver_enable   <= 1'b0;
  DIO_driver          <= {RANK_BIT_WIDTH{1'bz}};

  #(1.5*CYCLE_TIME);

  // Write phase
  for (i = 0; i < CHIP_ROW_COUNT; i = i + 1) begin
    
    #(CYCLE_TIME);
    for (j = 0; j < CHIP_COUNT; j = j + 1) begin
      A[j*RANK_ADDR_WIDTH +: RANK_ADDR_WIDTH] 
          <= i[RANK_ADDR_WIDTH-1:0];
    end
    DIO_driver_enable <= 1'b1;
    DIO_driver        <= {4{$random}};

    #(CYCLE_TIME);
    CE      <= 0;
    WR      <= {8{$random}};
    OE      <= {CHIP_COUNT{1'b1}};

    #(CYCLE_TIME);
    WR      <= {CHIP_COUNT{1'b1}};
    CE      <= {CHIP_COUNT{1'b1}};

  end

  // Stop write
  #(CYCLE_TIME);
  WR                <= {CHIP_COUNT{1'b1}};
  CE                <= {CHIP_COUNT{1'b1}};
  DIO_driver_enable <= 1'b0;
  DIO_driver        <= {RANK_BIT_WIDTH{1'bz}};

  // Read back
  for (i = 0; i < MEM_BYTE_CAPACITY; i = i + 16) begin
    #(CYCLE_TIME);

    for (j = 0; j < CHIP_COUNT; j = j + 1) begin
      A[j*RANK_ADDR_WIDTH +: RANK_ADDR_WIDTH] 
          <= i[RANK_ADDR_WIDTH-1:0];
    end
    CE      <= 0;
    WR      <= {CHIP_COUNT{1'b1}};
    OE      <= 0;

    #(CYCLE_TIME/2);
    check();
    #(CYCLE_TIME/2);
  end

  #(CYCLE_TIME);
  CE  <= {CHIP_COUNT{1'b1}};
  OE  <= {CHIP_COUNT{1'b1}};

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule