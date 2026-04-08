module  main_memory_tb;

initial begin
  // $vcdplusfile("main_memory_tb.dump.vpd");
  // $vcdpluson(0, main_memory_tb); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  // // $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
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
localparam ADDR_SETUP_X10               = 280;
localparam CE_SETUP_X10                 = 370;
localparam DOE_TIME_X10                 = 620;
localparam HZ_TIME_X10                  = 175;
localparam CYCLE_TIME_X10               = 2000;
localparam RD_EN_CYCLES                 = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES      = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES        = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);

reg   [RANK_ADDR_WIDTH-1:0]             A_RANK0, A_RANK1, A_RANK2;
reg   [RANK_COUNT*CHIPS_PER_RANK-1:0]   WR, OE, CE;
reg                                     clk, rst;
reg   [RANK_BIT_WIDTH-1:0]              DIO_driver;
reg                                     DIO_driver_enable;
reg   [RANK_IDX_WIDTH-1:0]              active_rank;

wire  [RANK_ADDR_WIDTH-1:0]             A_OTHERS = A_RANK0;

wire  [RANK_COUNT*RANK_BIT_WIDTH-1:0]   DIO;
wire  [RANK_COUNT*RANK_BIT_WIDTH-1:0]   DIO_exp;

genvar r;
generate
  for (r = 0; r < RANK_COUNT; r = r + 1) begin : DIO_DRIVE_GEN
    assign DIO    [RANK_BIT_WIDTH*(r+1)-1:RANK_BIT_WIDTH*r] =
      (DIO_driver_enable && (active_rank == r)) ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
    assign DIO_exp[RANK_BIT_WIDTH*(r+1)-1:RANK_BIT_WIDTH*r] =
      (DIO_driver_enable && (active_rank == r)) ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
  end
endgenerate

integer i, j;

main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) DUT 
(
  .clk(clk), .rst(rst),
  .A_RANK0(A_RANK0), .A_RANK1(A_RANK1), .A_RANK2(A_RANK2), .A_OTHERS(A_OTHERS),
  .WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO)
);

main_memory_behav #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) REF 
(
  .clk(clk), .rst(rst),
  .A_RANK0(A_RANK0), .A_RANK1(A_RANK1), .A_RANK2(A_RANK2), .A_OTHERS(A_OTHERS),
  .WR(WR), .OE(OE), .CE(CE),
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
  if (DIO[RANK_BIT_WIDTH*active_rank+:RANK_BIT_WIDTH] !==
      DIO_exp[RANK_BIT_WIDTH*active_rank+:RANK_BIT_WIDTH]) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
              $time,
              DIO_exp[RANK_BIT_WIDTH*active_rank+:RANK_BIT_WIDTH],
              DIO    [RANK_BIT_WIDTH*active_rank+:RANK_BIT_WIDTH]);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // Apply test vectors (active low WR, OE, CE)
  // Do a write phase (sequential) and then a read back phase to check
  A_RANK0             <= 0;
  A_RANK1             <= 0;
  A_RANK2             <= 0;
  active_rank         <= 0;
  WR                  <= {CHIP_COUNT{1'b1}};
  OE                  <= {CHIP_COUNT{1'b1}};
  CE                  <= {CHIP_COUNT{1'b1}};
  DIO_driver_enable   <= 1'b0;
  DIO_driver          <= {RANK_BIT_WIDTH{1'bz}};

  #(1.5*CYCLE_TIME);

  // Write phase
  for (j = 0; j < 16; j = j + 1) begin
    for (i = 0; i < CHIP_ROW_COUNT; i = i + 1) begin
      
      #(CYCLE_TIME);
      A_RANK0             <= i[RANK_ADDR_WIDTH-1:0];
      A_RANK1             <= i[RANK_ADDR_WIDTH-1:0];
      A_RANK2             <= i[RANK_ADDR_WIDTH-1:0];
      active_rank         <= j[RANK_IDX_WIDTH-1:0];
      DIO_driver_enable <= 1'b1;
      DIO_driver        <= {4{$random}};

      #(CYCLE_TIME);
      CE      = ~(256'd65535 << (16*j));
      WR      = CE | {8{$random}};
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
      A_RANK0             <= i[RANK_ADDR_WIDTH-1:0];
      A_RANK1             <= i[RANK_ADDR_WIDTH-1:0];
      A_RANK2             <= i[RANK_ADDR_WIDTH-1:0];
      active_rank         <= j[RANK_IDX_WIDTH-1:0];
      CE       = ~(256'd65535 << (16*j));
      OE       = CE;
      WR      <= {CHIP_COUNT{1'b1}};

      #(CYCLE_TIME/2);
      check();
      #(CYCLE_TIME/2);
    end

    #(CYCLE_TIME);
    CE  <= {CHIP_COUNT{1'b1}};
    OE  <= {CHIP_COUNT{1'b1}};
    #(CYCLE_TIME);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule
