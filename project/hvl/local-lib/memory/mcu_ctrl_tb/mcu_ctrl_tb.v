module  mcu_ctrl_tb;

initial begin
  $vcdplusfile("mcu_ctrl_tb.dump.vpd");
  $vcdpluson(0, mcu_ctrl_tb); 
  // $vcdpluson(0, mcu_ctrl_tb.DUT); 
  // $vcdpluson(0, mcu_ctrl_tb.DUT.mem_module.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem); 
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
localparam V_CT_1000   = RANK_BURST_SIZE - 1;
localparam V_CT_0100   = WR_AND_DATA_EN_CYCLES - 1;
localparam V_CT_0101   = RD_EN_CYCLES  - 1;
localparam V_CT_1101   = RANK_BURST_SIZE  - 1;
localparam V_CT_1110   = (RD_EN_CYCLES - RANK_BURST_SIZE) - 1;
localparam V_CT_1111   = (RANK_BURST_SIZE) - 1;

reg     rst, clk, DC_MEM_WR_ACK, DMA_MEM_WR_ACK, DC_MEM_RD_ACK, IC_MEM_RD_ACK;
wire    [2:0] MEM_CTRL_Q_MUX;


mcu_ctrl #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst          (rst          )    , .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK)    , .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK)    , .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .MEM_CTRL_Q_MUX     (MEM_CTRL_Q_MUX     )
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

initial begin
  rst <= 0;
  DC_MEM_WR_ACK   <= 1'b0;
  DMA_MEM_WR_ACK  <= 1'b0;
  DC_MEM_RD_ACK   <= 1'b0;
  IC_MEM_RD_ACK   <= 1'b0;
  #(1.5 * CYCLE_TIME);
  rst <= 1;
  DC_MEM_WR_ACK   <= 1'b0;
  DMA_MEM_WR_ACK  <= 1'b0;
  DC_MEM_RD_ACK   <= 1'b0;
  IC_MEM_RD_ACK   <= 1'b1;
  #(30 * CYCLE_TIME);
  

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule