module  disk_regs_tb;

initial begin
  $vcdplusfile("disk_regs_tb.dump.vpd");
  $vcdpluson(0, disk_regs_tb); 
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
localparam DELAY_ADJ         = 0;
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
localparam ADDR_EN_TO_WR_EN  = ((ADDR_SETUP  / CYCLE_TIME)   + 1);
localparam DATA_EN_TO_WR_DIS = ((DATA_SETUP  / CYCLE_TIME)   + 1);
localparam WR_DIS_TO_DATA_EN = 1; // Protect against DIO -> posedge WR violations
localparam WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1) + WR_DIS_TO_DATA_EN;

reg   [15:0]                WR_mask;
reg                         WR, OE, clk, rst;
reg   [RANK_BIT_WIDTH-1:0]  DIO_driver;
reg                         DIO_driver_enable;

wire  [RANK_BIT_WIDTH-1:0]  DIO     = DIO_driver_enable ? DIO_driver : {RANK_BIT_WIDTH{1'bz}};
integer i;

reg   [15:0]                WR_mask_val;

wire  [127:0]  DMA_config;


disk_regs #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME(CYCLE_TIME), .DELAY_ADJ(DELAY_ADJ)) DUT 
(
  .clk(clk), .rst(rst),
  .WR_mask(WR_mask),
	.WR(WR), .OE(OE),
  .DIO(DIO), .DMA_config(DMA_config)
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
  input   [31:0]  DIO_exp;
  begin
    if (DIO !== DIO_exp) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DIO_exp = %h, DIO = %h\n", 
                $time, DIO_exp, DIO);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. DIO_exp = %h, DIO = %h\n", 
      //           $time, {{17{1'b0}}, ADDR}, DIO);
    end
  end
endtask

task read;
  reg [31:0]  DATA;
  begin
    DATA                  <= 32'hFFFFFFF0;
    DIO_driver_enable     <= 1'b0;
    #(ADDR_HIZ_PROT*CYCLE_TIME);
    OE <= 0;
    WR <= 1;
    WR_mask <= 16'hFFFF;
    #(CYCLE_TIME);
    OE <= 1;
    #((RD_EN_DURATION-1)*CYCLE_TIME);
    #(RD_DIS_TO_DATA_V*CYCLE_TIME);
    check_read(DATA); 
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(DATA+4);
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(DATA+8);
    #(RD_CLK_SPACING*CYCLE_TIME);
    check_read(DATA+12);
    #(RD_TO_BUS_FREE*CYCLE_TIME);
  end
endtask

task write;
  input [31:0] DATA;
  begin
    DIO_driver_enable     <= 1'b1;
    DIO_driver            <= DATA;
    #(ADDR_EN_TO_WR_EN*CYCLE_TIME);
    WR                    <= 1'b0;
    WR_mask               <= WR_mask_val;
    OE                    <= 1'b1;
    #(WR_CLK_SPACING*CYCLE_TIME);
    WR                    <= 1'b1;
    WR_mask               <= 16'hFFFF;
    #(WR_DIS_TO_DATA_EN*CYCLE_TIME);    
    DIO_driver  <= DATA+4;  #(WR_CLK_SPACING*CYCLE_TIME);
    DIO_driver  <= DATA+8;  #(WR_CLK_SPACING*CYCLE_TIME);
    DIO_driver  <= DATA+12; #(WR_CLK_SPACING*CYCLE_TIME);
    DIO_driver_enable     <= 1'b0;
  end
endtask

initial begin
  WR_mask_val           = 16'h0000;
  rst = 1'b1;
  WR                    = 1'b1;
  WR_mask               = 16'hFFFF;
  OE                    = 1'b1;
  DIO_driver_enable     = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b1;
  #(0.5*CYCLE_TIME);
  
  // Apply test vectors (active low WR, OE)
  // Do a write phase (sequential) and then a read back phase to check

  WR                  = 1'b1;
  WR_mask             = 16'hFFFF;
  OE                  = 1'b1;
  DIO_driver_enable   = 1'b0;
  DIO_driver          = {RANK_BIT_WIDTH{1'bz}};

  #(CYCLE_TIME);
  
  write(32'hFFFFFFF0);
  read();
  
  #(10*CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule