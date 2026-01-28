module  main_memory_tb;

initial begin
  $vcdplusfile("main_memory_tb.dump.vpd");
  $vcdpluson(0, main_memory_tb); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[0].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem); 
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);  
  $vcdpluson(0, main_memory_tb.DUT.rank_group_generation[1].rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
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

/* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
// Next few parameters are in units of ns
localparam DELAY_ADJ         = 7;
localparam ADDR_SETUP        = 25 + DELAY_ADJ;
localparam DATA_SETUP        = 25 + DELAY_ADJ;
localparam CE_SETUP          = 35;
localparam DOE_TIME          = 64;
localparam HZ_TIME           = 18;

localparam CYCLE_TIME        = 10;

// Next few parameters are in units of cycles
localparam ADDR_HIZ_PROT     = 1; // Don't enable RD when ADDR comparator can still be HiZ after clock edge
localparam RD_EN_DURATION    = ((DOE_TIME    / CYCLE_TIME)   + 1);
localparam RD_DIS_TO_DATA_V  = CYCLE_TIME <= 17 ? 1 : 1; // This will fail miserably if you have a bad cycle time (>= 18 ns)
localparam RD_TO_BUS_FREE    = CYCLE_TIME <= 8 ? 2 : 1; // Needed due to tHz

// Yes, the extra + 1 should be there below in RD_CLK_SPACING
// Need + 1 cycle for data to be valid, and then extra time to let DIO become HiZ
localparam RD_CLK_SPACING    = ((HZ_TIME     / CYCLE_TIME)   + 1) + 1;
localparam WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1);
localparam ADDR_EN_TO_WR_EN  = ((ADDR_SETUP  / CYCLE_TIME)   + 1);
localparam DATA_EN_TO_WR_DIS = ((DATA_SETUP  / CYCLE_TIME)   + 1);
localparam WR_DIS_TO_DATA_EN = 1; // Protect against DIO -> posedge WR violations

reg   [MEM_ADDR_WIDTH-1:0]  A;
reg                         WR, OE, clk, rst;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
integer i;


main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME(CYCLE_TIME), .DELAY_ADJ(DELAY_ADJ)) DUT 
(
  .clk(clk), .rst(rst),
  .A(A),
	.WR(WR), .OE(OE),
  .DIO(DIO)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2) clk = ~clk;
  end
end

task check_read;
  input [14:0] ADDR;
  begin
    if (DIO !== {{17{1'b0}}, ADDR}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
                $time, {{17{1'b0}}, ADDR}, DIO);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. DIO_exp = %h, DIO = %h\n", 
      //           $time, {{17{1'b0}}, ADDR}, DIO);
    end
  end
endtask

task read;
  input [14:0]  ADDR;
  begin
    DIO_driver_enable     <= 1'b0;
    A                     <= ADDR;
    #(ADDR_HIZ_PROT*CYCLE_TIME);
    OE <= 0;
    WR <= 1;
    #(RD_EN_DURATION*CYCLE_TIME);
    OE <= 1;
    #(RD_DIS_TO_DATA_V*CYCLE_TIME);
    check_read(ADDR); 
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(ADDR+4);
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(ADDR+8);
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(ADDR+12);
    A                     <= 15'dz;
    #(RD_TO_BUS_FREE*CYCLE_TIME);
  end
endtask

task write;
  input [14:0] ADDR;
  input [31:0] DATA;
  begin
    A                     <= ADDR;
    DIO_driver_enable     <= 1'b1;
    DIO_driver            <= DATA;
    #(ADDR_EN_TO_WR_EN*CYCLE_TIME);
    WR                    <= 1'b0;
    OE                    <= 1'b1;
    #(WR_CLK_SPACING*CYCLE_TIME);
    WR                    <= 1'b1;
    #(WR_DIS_TO_DATA_EN*CYCLE_TIME);    
    DIO_driver  <= DATA+4;  #(WR_CLK_SPACING*CYCLE_TIME);
    DIO_driver  <= DATA+8;  #(WR_CLK_SPACING*CYCLE_TIME);
    DIO_driver  <= DATA+12; #(WR_CLK_SPACING*CYCLE_TIME);
    A                     <= 15'dz;
    DIO_driver_enable     <= 1'b0;
  end
endtask

initial begin
  rst = 1'b1;
  WR                    = 1'b1;
  OE                  = 1'b1;
  DIO_driver_enable    = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b1;
  #(0.5*CYCLE_TIME);
  
  // Apply test vectors (active low WR, OE)
  // Do a write phase (sequential) and then a read back phase to check

  A                   = {MEM_ADDR_WIDTH{1'b0}};
  WR                  = 1'b1;
  OE                  = 1'b1;
  DIO_driver_enable   = 1'b0;
  DIO_driver          = {RANK_BIT_WIDTH{1'bz}};

  #(CYCLE_TIME);
  
  for (i = 0; i < 32768; i = i + 16) begin
    write(i, i);
    read(i);
  end
  
  #(10*CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule