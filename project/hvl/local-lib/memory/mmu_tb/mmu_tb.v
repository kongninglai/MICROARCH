module  mmu_tb;

initial begin
  $vcdplusfile("mmu_tb.dump.vpd");
  $vcdpluson(0, mmu_tb); 
  // $vcdpluson(0, mmu_tb.DUT); 
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
localparam ADDR_SETUP_X10            = 270;
localparam CE_SETUP_X10              = 370;
localparam DOE_TIME_X10              = 620;
localparam HZ_TIME_X10               = 175;
localparam CYCLE_TIME_X10            = 100;
localparam RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam V_CT_ADDR_DATA    = ADDR_EN_TO_WR_EN_CYCLES - 1;
localparam V_CT_WR_EN        = WR_AND_DATA_EN_CYCLES - 1;
localparam V_CT_RD_EN        = RD_EN_CYCLES - 1;
localparam V_CT_SHORT_RD_EN  = (RD_EN_CYCLES - RANK_BURST_SIZE) - 1;
localparam V_CT_SHORT_BRST   = (RANK_BURST_SIZE - 1) - 1;

reg     rst, clk, DC_MEM_WR_ACK, DMA_MEM_WR_ACK, DC_MEM_RD_ACK, IC_MEM_RD_ACK;

reg   [15:0]  WR_mask, WR_mask_val;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

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

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME_X10 / 20.0) clk = ~clk;
  end
end

initial begin
  #(CYCLE_TIME_X10 / 10.0);
  

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule