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
localparam CLK_SPACING=3;

reg   [MEM_ADDR_WIDTH-1:0]  A;
reg                         WR, OE, CE, mem_clk, rst;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
integer i;

wire A_valid = 1'b1;

main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)) DUT 
(
  .mem_clk(mem_clk), .rst(rst),
  .A(A),
	.WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO), .A_valid(A_valid)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME = 10.000;

initial begin
  mem_clk = 0;
  forever begin
    #(CYCLE_TIME / 2) mem_clk = ~mem_clk;
  end
end

task check_read;
  input [14:0] ADDR;
  begin
    if (DIO != {{17{1'b0}}, ADDR}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
                $time, {{17{1'b0}}, ADDR}, DIO);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task read;
  input [14:0]  ADDR;
  begin
    DIO_driver_enable    <= 1'b0;
    A                     <= ADDR;
    CE <= 0;
    OE <= 0;
    WR <= 1;
    #(7*CYCLE_TIME);
    CE <= 1;
    OE <= 1;
    #(CYCLE_TIME);
    check_read(ADDR);
    #(3*CYCLE_TIME);
    check_read(ADDR+4);
    #(3*CYCLE_TIME);
    check_read(ADDR+8);
    #(3*CYCLE_TIME);
    check_read(ADDR+12);
    #(CYCLE_TIME);
  end
endtask

task write;
  input [14:0] ADDR;
  input [31:0] DATA;
  begin
    A = ADDR;
    #(CYCLE_TIME);
    DIO_driver_enable <= 1'b1;
    DIO_driver <= DATA;
    #(2*CYCLE_TIME);
    WR <= 1'b0;
    CE <= 1'b0;
    OE <= 1'b1;
    #(CYCLE_TIME*4);
    A <= ADDR+4;
    #(CYCLE_TIME);
    DIO_driver <= DATA+4;
    #(CYCLE_TIME*4);
    A <= ADDR+8;
    #(CYCLE_TIME);
    DIO_driver <= DATA+8;
    #(CYCLE_TIME*4);
    WR <= 1'b1;
    CE <= 1'b1;
    A <= ADDR+12;
    #(CYCLE_TIME);
    DIO_driver <= DATA+12;
    #(CYCLE_TIME*4);
    A <= ADDR;
    #(CYCLE_TIME);
    DIO_driver_enable <= 1'b0;
  end
endtask

initial begin
  rst = 1'b1;
  WR                    = 1'b1;
  OE                  = 1'b1;
  CE                  = 1'b1;
  DIO_driver_enable    = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b1;
  #(0.5*CYCLE_TIME);
  
  // Apply test vectors (active low WR, OE, CE)
  // Do a write phase (sequential) and then a read back phase to check

  A                   = {MEM_ADDR_WIDTH{1'b0}};
  WR                  = 1'b1;
  OE                  = 1'b1;
  CE                  = 1'b1;
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