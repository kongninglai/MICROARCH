module off_core_top #(
  parameter ROW_BUFFER_EN=1'b1,
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),

  /*  
      Next few parameters are in units of 1e-10 seconds (X10 turns ns (1e-9) into 1e-10).
      The point of multiplying by 10 is to allow cycle time to have increments of 0.1 ns 
      while still using integer math.
  */
  parameter ADDR_SETUP_X10            = 280,  /* Add 3 ns for state transition comb logic delay + buf256 */
  parameter CE_SETUP_X10              = 370,  /* Add 2 ns for state transition comb logic delay */
  parameter DOE_TIME_X10              = 620,  /* Add 2 ns for state transition comb logic delay */
  parameter HZ_TIME_X10               = 175,
  parameter CYCLE_TIME_X10            = 100,

  /* Next few parameters are in units of cycles */
  parameter RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1),
  parameter ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1),
  parameter WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1),

  parameter V_CT_WRITE_DONE       = WR_AND_DATA_EN_CYCLES - 1,
  parameter V_CT_RD_EN_DONE       = RD_EN_CYCLES - 1,
  parameter V_CT_SHORT_BRST_DONE  = (RANK_BURST_SIZE - 1) - 1
) (
  input                             rst                     ,
                                    clk                     ,
                                    DC_MEM_WR_RQ            ,          
                                    DC_DMA_WR_RQ            ,          
                                    DC_KB_WR_RQ             ,        
                                    DC_MEM_RD_RQ            ,          
                                    DC_DMA_RD_RQ            ,          
                                    DC_KB_RD_RQ             ,
                                    IC_MEM_RD_RQ            ,

  input     [7:0]                   TEST_CASE_NEW_CHAR      ,
                                    TEST_CASE_NEW_CHAR_WR   ,
  input                             TEST_CASE_NEW_READY     ,
                                    TEST_CASE_NEW_READY_WR  ,      

  inout     [CHIPS_PER_RANK-1:0]    WR_mask                 ,   
  inout     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS                ,      
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS                ,      
  inout                             DATA_VALID_BAR          ,
  output                            DC_MEM_WR_ACK           ,
                                    DC_DMA_WR_ACK           ,
                                    DC_KB_WR_ACK            ,
                                    DC_MEM_RD_ACK           ,
                                    DC_DMA_RD_ACK           ,
                                    DC_KB_RD_ACK            ,
                                    IC_MEM_RD_ACK           , 
                                    DMA_INT     
);

wire MEM_BUSY, DMAC_BUSY, KB_BUSY, DMA_MEM_WR_RQ, DMA_MEM_WR_ACK;

kb #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) kb_inst (
  .rst          (rst          )    , .clk(clk), 
  .TEST_CASE_NEW_CHAR     (TEST_CASE_NEW_CHAR),      
  .TEST_CASE_NEW_CHAR_WR      (TEST_CASE_NEW_CHAR_WR),   
  .TEST_CASE_NEW_READY      (TEST_CASE_NEW_READY),     
  .TEST_CASE_NEW_READY_WR     (TEST_CASE_NEW_READY_WR),  
  .DC_KB_WR_ACK(DC_KB_WR_ACK)      ,
  .DC_KB_RD_ACK(DC_KB_RD_ACK)      , 
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .KB_BUSY      (KB_BUSY     )     , .DATA_VALID_BAR(DATA_VALID_BAR)
);

dmac #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) dmac_inst (
  .rst          (rst          )    , .clk(clk), 
  .DC_DMA_WR_ACK(DC_DMA_WR_ACK)      ,
  .DC_DMA_RD_ACK(DC_DMA_RD_ACK)      , 
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK)  ,
  .DMA_MEM_WR_RQ(DMA_MEM_WR_RQ)    ,
  .DMAC_BUSY      (DMAC_BUSY     )     , .DATA_VALID_BAR(DATA_VALID_BAR), .DMA_INT(DMA_INT)
);

mcu #(.CYCLE_TIME_X10(CYCLE_TIME_X10), .ROW_BUFFER_EN(ROW_BUFFER_EN)) mcu_inst (
  .rst          (rst          )    , .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK)    , .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK)    , .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .MEM_BUSY     (MEM_BUSY     )    , .DATA_VALID_BAR(DATA_VALID_BAR)
);

arbiter arbiter_inst (
  .rst(rst), .clk(clk),
  .MEM_BUSY(MEM_BUSY),
  .DMAC_BUSY(DMAC_BUSY),
  .KB_BUSY(KB_BUSY),
  .DC_MEM_RD_RQ(DC_MEM_RD_RQ),
  .DC_DMA_RD_RQ(DC_DMA_RD_RQ),
  .DC_KB_RD_RQ(DC_KB_RD_RQ),
  .DC_MEM_WR_RQ(DC_MEM_WR_RQ),
  .DC_DMA_WR_RQ(DC_DMA_WR_RQ),
  .DC_KB_WR_RQ(DC_KB_WR_RQ),
  .IC_MEM_RD_RQ(IC_MEM_RD_RQ),
  .DMA_MEM_WR_RQ(DMA_MEM_WR_RQ),
  .DC_MEM_RD_ACK_BUS(DC_MEM_RD_ACK),
  .DC_DMA_RD_ACK_BUS(DC_DMA_RD_ACK),
  .DC_KB_RD_ACK_BUS(DC_KB_RD_ACK),
  .DC_MEM_WR_ACK_BUS(DC_MEM_WR_ACK),
  .DC_DMA_WR_ACK_BUS(DC_DMA_WR_ACK),
  .DC_KB_WR_ACK_BUS(DC_KB_WR_ACK),
  .IC_MEM_RD_ACK_BUS(IC_MEM_RD_ACK),
  .DMA_MEM_WR_ACK_BUS(DMA_MEM_WR_ACK)
);

endmodule