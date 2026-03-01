module  kb_tb;

initial begin
  $vcdplusfile("kb_tb.dump.vpd");
  $vcdpluson(0, kb_tb); 
  $vcdpluson(0, kb_tb.DUT); 
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

reg     rst, clk, DC_KB_WR_ACK, DC_KB_RD_ACK;

reg   [15:0]  WR_mask_driver;
reg           WR_mask_driver_enable;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

reg   [127:0] IN_DATA0, EXP_DATA0;
reg   [127:0] IN_DATA1, EXP_DATA1;

wire  [15:0]  WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {16{1'bz}};
wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};
wire  [14:0]  ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {15{1'bz}};

wire          KB_BUSY, DATA_VALID_BAR;

reg    [7:0]  TEST_CASE_NEW_CHAR      ;
reg    [7:0]  TEST_CASE_NEW_CHAR_WR   ;  
reg           TEST_CASE_NEW_READY     ;
reg           TEST_CASE_NEW_READY_WR  ;    


kb #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
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
    DC_KB_WR_ACK   <= 1'b0;
    DC_KB_RD_ACK   <= 1'b0;
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
    #(DELAY_ADJ);
    case(idx)
      0: begin 
        DC_KB_WR_ACK     <= 1'b1;
      end
      1: begin 
        DC_KB_RD_ACK     <= 1'b1;
      end
    endcase
    #(CYCLE_TIME - DELAY_ADJ);
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

task check;
  input [31:0] EXPECTED_DATA;
  begin
    if (DATA_BUS !== EXPECTED_DATA) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. EXP = %h, DATA = %h\n", 
                $time, EXPECTED_DATA, DATA_BUS);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask


task checkRDaddr;
  input [RANK_BIT_WIDTH-1:0] EXPECTED_DATA0;
  begin
    #((1 + RD_EN_CYCLES + 1) * CYCLE_TIME);
    check(EXPECTED_DATA0[31:0]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA0[63:32]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA0[95:64]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA0[127:96]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA1[31:0]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA1[63:32]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA1[95:64]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA1[127:96]);
    #(CYCLE_TIME);
  end
endtask


initial begin
  rst                     <= 1'b0;
  TEST_CASE_NEW_CHAR_WR   <= 1'b0;
  TEST_CASE_NEW_READY_WR  <= 1'b0;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);
  rst               <= 1'b1;
  #(CYCLE_TIME);

  // Ensure new char writes do not work when KBER = 0
  TEST_CASE_NEW_CHAR      <= 8'h55;
  TEST_CASE_NEW_CHAR_WR   <= {8{1'b1}};
  TEST_CASE_NEW_READY     <= 1'b1;
  TEST_CASE_NEW_READY_WR  <= 1'b1;
  EXP_DATA0                = 0;                    
  EXP_DATA1                = 0;                                
  #(CYCLE_TIME);
  TEST_CASE_NEW_CHAR_WR   <= {8{1'b0}};
  TEST_CASE_NEW_READY_WR  <= 1'b0;

  assertOneCycle(1);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertOneCycle(1);
  fork
    driveRDaddr((1 << 4));
    checkRDaddr(EXP_DATA1);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  

  // Set KBER
  assertOneCycle(0);
  IN_DATA0    = {{63{1'bX}},1'bX,{63{1'bX}},1'b1};
  EXP_DATA0   = {{63{1'b0}},1'b0,{63{1'b0}},1'b1};    // KBER, but NOT KBSR, affected by writes
  IN_DATA1    = {128{1'bX}};                          
  EXP_DATA1   = 0;                                    // KBDR unaffected by writes
  fork
    driveWRmaskWRaddr(16'h0000, 0);
    driveWRdata(IN_DATA0);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  // KBER should be unaffected by second write, so should not be cleared
  assertOneCycle(0);
  fork
    driveWRmaskWRaddr(16'h0000, (1 << 4));
    driveWRdata(IN_DATA1);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertOneCycle(1);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertOneCycle(1);
  fork
    driveRDaddr((1 << 4));
    checkRDaddr(EXP_DATA1);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  // New character ready, and now KB is enabled!
  TEST_CASE_NEW_CHAR      <= 8'h55;
  TEST_CASE_NEW_CHAR_WR   <= {8{1'b1}};
  TEST_CASE_NEW_READY     <= 1'b1;
  TEST_CASE_NEW_READY_WR  <= 1'b1;
  EXP_DATA0                = {{63{1'b0}},1'b1,{63{1'b0}},1'b1};         // Expect READY, and KB enabled           
  EXP_DATA1                = {{120{1'b0}},8'h55};                       // Expect new KBDR    
  #(CYCLE_TIME);
  TEST_CASE_NEW_CHAR_WR   <= {8{1'b0}};
  TEST_CASE_NEW_READY_WR  <= 1'b0;

  // Read ready bit, ensure it's 1, and then read data, ensure it's 0x55, then ensure ready was cleared!
  assertOneCycle(1);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertOneCycle(1);
  fork
    driveRDaddr((1 << 4));
    checkRDaddr(EXP_DATA1);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  EXP_DATA0                = {{63{1'b0}},1'b0,{63{1'b0}},1'b1};         // Expect READY to be CLEARED
  assertOneCycle(1);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule