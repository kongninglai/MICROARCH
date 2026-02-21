module  mmu_tb;

initial begin
  $vcdplusfile("mmu_tb.dump.vpd");
  $vcdpluson(0, mmu_tb); 
  $vcdpluson(0, mmu_tb.DUT); 
  // $vcdpluson(0, mmu_tb.DUT.mem_module.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem); 
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
localparam ADDR_SETUP_X10            = 280;
localparam CE_SETUP_X10              = 370;
localparam DOE_TIME_X10              = 620;
localparam HZ_TIME_X10               = 175;
localparam CYCLE_TIME_X10            = 100;
localparam RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam V_CT_WRITE_DONE           = WR_AND_DATA_EN_CYCLES - 1;
localparam V_CT_RD_EN_DONE           = RD_EN_CYCLES - 1;
localparam V_CT_SHORT_BRST_DONE      = (RANK_BURST_SIZE - 1) - 1;

localparam DELAY_ADJ = 7;

reg     rst, clk, DC_MEM_WR_ACK, DMA_MEM_WR_ACK, DC_MEM_RD_ACK, IC_MEM_RD_ACK;

reg   [15:0]  WR_mask_driver;
reg           WR_mask_driver_enable;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

wire  [15:0]  WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {16{1'bz}};
wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};
wire   [14:0]  ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {15{1'bz}};


mmu #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst          (rst          )    , .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK)    , .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK)    , .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .MEM_BUSY     (MEM_BUSY     )
);

integer SUCCESSES = 0;
integer FAILURES = 0;

integer i;

localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task deassertAll;
  begin
    DC_MEM_WR_ACK   <= 1'b0;
    DMA_MEM_WR_ACK  <= 1'b0;
    DC_MEM_RD_ACK   <= 1'b0;
    IC_MEM_RD_ACK   <= 1'b0;
  end
endtask

task stopAllDrivers;
  begin
    DATA_driver             <= {BUS_BIT_WIDTH{1'bz}};
    DATA_driver_enable      <= 1'b0;
    WR_mask_driver          <= {CHIPS_PER_RANK{1'bz}};
    WR_mask_driver_enable   <= 1'b0;
    ADDR_driver             <= {MEM_ADDR_WIDTH{1'bz}};
    ADDR_driver_enable      <= 1'b0;
  end
endtask

task assertOneCycle;
  input integer idx;
  begin
    case(idx)
      0: begin 
        DC_MEM_WR_ACK     <= 1'b1;
      end
      1: begin 
        DMA_MEM_WR_ACK    <= 1'b1;
      end
      2: begin 
        DC_MEM_RD_ACK     <= 1'b1;
      end
      3: begin 
        IC_MEM_RD_ACK     <= 1'b1;
      end
    endcase
    #(CYCLE_TIME);
    deassertAll();
  end
endtask

task driveWRmaskWRaddr;
  input [15:0]  WR_mask_val;
  input [14:0]  MEM_ADDR;
  begin
    #(DELAY_ADJ);
    WR_mask_driver          <= WR_mask_val;
    WR_mask_driver_enable   <= 1'b1;
    ADDR_driver             <= MEM_ADDR;
    ADDR_driver_enable      <= 1'b1;
    #(RANK_BURST_SIZE * CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task driveWRdata;
  input [RANK_BIT_WIDTH-1:0] WR_DATA;
  begin
    #(DELAY_ADJ);
    DATA_driver             <= WR_DATA[BUS_BIT_WIDTH-1:0];
    DATA_driver_enable      <= 1'b1;    
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    DATA_driver             <= WR_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH];
    #(CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task driveRDaddr;
  input [MEM_ADDR_WIDTH-1:0]  MEM_ADDR;
  begin
    #(DELAY_ADJ);
    ADDR_driver             <= MEM_ADDR;
    ADDR_driver_enable      <= 1'b1;
    #(1 * CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

task driveRDaddrICACHE;
  input [MEM_ADDR_WIDTH-1:0]  MEM_ADDR;
  begin
    #(DELAY_ADJ);
    ADDR_driver             <= MEM_ADDR;
    ADDR_driver_enable      <= 1'b1;
    #(1 * CYCLE_TIME);
    stopAllDrivers();
    #(CYCLE_TIME - DELAY_ADJ);
  end
endtask

initial begin
  rst               <= 1'b0;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);

  // for (i = 0; i < 2048; i = i + 2)
  // {

  // }


  rst               <= 1'b1;
  assertOneCycle(0);

  fork
    driveWRmaskWRaddr(16'h0000, 15'h43F0);
    driveWRdata(128'hFEDCBA98765432100123456789ABCDEF);
  join

  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertOneCycle(2);
  driveRDaddr(15'h43F0);

  #((RD_EN_CYCLES + RANK_BURST_SIZE) * CYCLE_TIME);
  assertOneCycle(1);
  fork
    driveWRmaskWRaddr(16'h0000, 15'h4400);
    driveWRdata(128'hbeefbeeffeedfeedbeefbeeffeedfeed);
  join

  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertOneCycle(3);
  driveRDaddrICACHE(15'h43F0);
  #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule