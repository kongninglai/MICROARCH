module  off_core_top_tb;

initial begin
  $vcdplusfile("off_core_top_tb.dump.vpd");
  $vcdpluson(0, off_core_top_tb); 
  $vcdpluson(0, off_core_top_tb.DUT); 
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

reg rst, clk;
reg DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_KB_WR_RQ;
reg DC_MEM_RD_RQ, DC_DMA_RD_RQ, DC_KB_RD_RQ;
reg IC_MEM_RD_RQ;

reg [7:0] TEST_CASE_NEW_CHAR, TEST_CASE_NEW_CHAR_WR;
reg TEST_CASE_NEW_READY, TEST_CASE_NEW_READY_WR;

reg   [CHIPS_PER_RANK-1:0] WR_mask_driver, WR_mask_driver_val;
reg                        WR_mask_driver_enable;

reg   [BUS_BIT_WIDTH-1:0]  DATA_driver;
reg                        DATA_driver_enable;

reg   [MEM_ADDR_WIDTH-1:0] ADDR_driver;
reg                        ADDR_driver_enable;

wire  [CHIPS_PER_RANK-1:0] WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {CHIPS_PER_RANK{1'bz}};
wire  [BUS_BIT_WIDTH-1:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {BUS_BIT_WIDTH{1'bz}};
wire  [MEM_ADDR_WIDTH-1:0] ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {MEM_ADDR_WIDTH{1'bz}};

wire DC_MEM_WR_ACK, DC_DMA_WR_ACK, DC_KB_WR_ACK;
wire DC_MEM_RD_ACK, DC_DMA_RD_ACK, DC_KB_RD_ACK;
wire IC_MEM_RD_ACK, DMA_INT;

off_core_top #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst(rst),
  .clk(clk),
  .DC_MEM_WR_RQ(DC_MEM_WR_RQ),
  .DC_DMA_WR_RQ(DC_DMA_WR_RQ),
  .DC_KB_WR_RQ(DC_KB_WR_RQ),
  .DC_MEM_RD_RQ(DC_MEM_RD_RQ),
  .DC_DMA_RD_RQ(DC_DMA_RD_RQ),
  .DC_KB_RD_RQ(DC_KB_RD_RQ),
  .IC_MEM_RD_RQ(IC_MEM_RD_RQ),
  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),
  .WR_mask(WR_mask),
  .ADDR_BUS(ADDR_BUS),
  .DATA_BUS(DATA_BUS),
  .DATA_VALID_BAR(DATA_VALID_BAR),
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK),
  .DC_DMA_WR_ACK(DC_DMA_WR_ACK),
  .DC_KB_WR_ACK(DC_KB_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK),
  .DC_DMA_RD_ACK(DC_DMA_RD_ACK),
  .DC_KB_RD_ACK(DC_KB_RD_ACK),
  .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .DMA_INT(DMA_INT)
);

localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task deassertAll;
  begin
    DC_MEM_WR_RQ <= 1'b0;
    DC_DMA_WR_RQ <= 1'b0;
    DC_KB_WR_RQ  <= 1'b0;
    DC_MEM_RD_RQ <= 1'b0;
    DC_DMA_RD_RQ <= 1'b0;
    DC_KB_RD_RQ  <= 1'b0;
    IC_MEM_RD_RQ <= 1'b0;
    TEST_CASE_NEW_CHAR     <= 8'd0;
    TEST_CASE_NEW_CHAR_WR  <= 8'd0;
    TEST_CASE_NEW_READY    <= 1'b0;
    TEST_CASE_NEW_READY_WR <= 1'b0;
  end
endtask

task assertTwoCycles;
  input integer idx;
  begin
    #(DELAY_ADJ);
    case(idx)
      0: begin 
        DC_MEM_WR_RQ     <= 1'b1;
      end
      1: begin 
        IC_MEM_RD_RQ     <= 1'b1;
      end
      2: begin 
        DC_KB_WR_RQ      <= 1'b1;
      end
      3: begin 
        DC_KB_RD_RQ      <= 1'b1;
      end
      4: begin 
        DC_DMA_WR_RQ     <= 1'b1;
      end
      5: begin 
        DC_DMA_RD_RQ     <= 1'b1;
      end
    endcase
    #(2 * CYCLE_TIME - DELAY_ADJ);
    deassertAll();
  end
endtask

task stopAllDrivers;
  begin
    WR_mask_driver_enable        <= 1'b0;
    DATA_driver_enable           <= 1'b0;
    ADDR_driver_enable           <= 1'b0;
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

integer SUCCESSES = 0;
integer FAILURES = 0;

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

task checkRDaddr_prefetch;
  input [RANK_BIT_WIDTH-1:0] EXPECTED_DATA0, EXPECTED_DATA1;
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
    check(EXPECTED_DATA1[31:0]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA1[63:32]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA1[95:64]);
    #(CYCLE_TIME);
    check(EXPECTED_DATA1[127:96]);
    #(CYCLE_TIME);
  end
endtask

task checkRDaddr_prefetch_dummy;
  input [RANK_BIT_WIDTH-1:0] EXPECTED_DATA0, EXPECTED_DATA1;
  begin
    #((1 + RD_EN_CYCLES + 1) * CYCLE_TIME);
    // check(EXPECTED_DATA0[31:0]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA0[63:32]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA0[95:64]);
    #(CYCLE_TIME);
    // check(EXPECTED_DATA0[127:96]);
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

task check_full;
  input [31:0] EXPECTED_DATA;
  input [14:0] EXPECTED_ADDR;
  input [15:0] EXPECTED_WR_MASK;
  begin
    if (DATA_BUS !== EXPECTED_DATA || ADDR_BUS !== EXPECTED_ADDR || WR_mask !== EXPECTED_WR_MASK) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. EXP = %h, DATA = %h; EXP = %h, ADDR_BUS = %h; EXP = %h, WR_mask = %h\n", 
                $time, EXPECTED_DATA, DATA_BUS, EXPECTED_ADDR, ADDR_BUS, EXPECTED_WR_MASK, WR_mask);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. EXP = %h, DATA = %h; EXP = %h, ADDR_BUS = %h; EXP = %h, WR_mask = %h\n", 
      //           $time, EXPECTED_DATA, DATA_BUS, EXPECTED_ADDR, ADDR_BUS, EXPECTED_WR_MASK, WR_mask);
    end
  end
endtask

task checkRDaddr_dma;
  input [RANK_BIT_WIDTH-1:0] EXPECTED_DATA0;
  input [CHIPS_PER_RANK-1:0] MASK;
  reg   [RANK_BIT_WIDTH-1:0] REAL_EXPECTED_DATA0;
  reg   [RANK_BIT_WIDTH-1:0] FULL_MASK;
  begin
    FULL_MASK = ~({
      {8{MASK[15]}},
      {8{MASK[14]}},
      {8{MASK[13]}},
      {8{MASK[12]}},
      {8{MASK[11]}},
      {8{MASK[10]}},
      {8{MASK[9]}},
      {8{MASK[8]}},
      {8{MASK[7]}},
      {8{MASK[6]}},
      {8{MASK[5]}},
      {8{MASK[4]}},
      {8{MASK[3]}},
      {8{MASK[2]}},
      {8{MASK[1]}},
      {8{MASK[0]}}
    });
    REAL_EXPECTED_DATA0 = EXPECTED_DATA0 & FULL_MASK;
    #((1 + RD_EN_CYCLES + 1) * CYCLE_TIME);
    check(REAL_EXPECTED_DATA0[31:0]);
    #(CYCLE_TIME);
    check(REAL_EXPECTED_DATA0[63:32]);
    #(CYCLE_TIME);
    check(REAL_EXPECTED_DATA0[95:64]);
    #(CYCLE_TIME);
    check(REAL_EXPECTED_DATA0[127:96]);
    #(CYCLE_TIME);
    // check(REAL_EXPECTED_DATA0[31:0]);
    #(CYCLE_TIME);
    // check(REAL_EXPECTED_DATA0[63:32]);
    #(CYCLE_TIME);
    // check(REAL_EXPECTED_DATA0[95:64]);
    #(CYCLE_TIME);
    // check(REAL_EXPECTED_DATA0[127:96]);
    #(CYCLE_TIME);
  end
endtask

reg   [RANK_BIT_WIDTH-1:0] RAND_DATA0, RAND_DATA0_SAVED_START, RAND_DATA0_SAVED_END;
reg   [RANK_BIT_WIDTH-1:0] RAND_DATA1;
reg   [RANK_BIT_WIDTH-1:0] IN_DATA0, EXP_DATA0;
reg   [RANK_BIT_WIDTH-1:0] IN_DATA1, EXP_DATA1;
reg   [7:0] ctr;
reg   [10:0] addr_ctr;

integer i;

initial begin
  rst <= 1'b0;
  DC_MEM_RD_RQ <= 1'b1;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);
  rst <= 1'b1;
  #(CYCLE_TIME);

  /*** MEMORY CONTROLLER TESTING ***/
  for (i = 0; i < 2047; i = i + 1) begin
    assertTwoCycles(0);
    RAND_DATA0 = {$random, $random, $random, $random};
    if (i == 0) begin
      RAND_DATA0_SAVED_START = RAND_DATA0;
    end
    if (i == 255) begin
      RAND_DATA0_SAVED_END = RAND_DATA0;
    end
    RAND_DATA1 = {$random, $random, $random, $random};
    fork
      driveWRmaskWRaddr(16'h0000, (i << 4));
      driveWRdata(RAND_DATA0);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertTwoCycles(0);
    fork
      driveWRmaskWRaddr(16'h0000, ((i+1) << 4));
      driveWRdata(RAND_DATA1);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertTwoCycles(1);
    fork
      driveRDaddr(i << 4);
      checkRDaddr_prefetch(RAND_DATA0, RAND_DATA1);
      #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
    join
  end

  /*** KEYBOARD TESTING ***/
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

  assertTwoCycles(3);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertTwoCycles(3);
  fork
    driveRDaddr((1 << 4));
    checkRDaddr(EXP_DATA1);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  // Set KBER
  assertTwoCycles(2);
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
  assertTwoCycles(2);
  fork
    driveWRmaskWRaddr(16'h0000, (1 << 4));
    driveWRdata(IN_DATA1);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertTwoCycles(3);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertTwoCycles(3);
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
  assertTwoCycles(3);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertTwoCycles(3);
  fork
    driveRDaddr((1 << 4));
    checkRDaddr(EXP_DATA1);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  EXP_DATA0                = {{63{1'b0}},1'b0,{63{1'b0}},1'b1};         // Expect READY to be CLEARED
  assertTwoCycles(3);
  fork
    driveRDaddr(0);
    checkRDaddr(EXP_DATA0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join


  /*** DMAC TEST ***/

  assertTwoCycles(4);
  WR_mask_driver_val = 0;
  // Write 3 bytes from ADDR 3 on disk to ADDR 2 in memory
  RAND_DATA0 = {32'd1, 32'd3, 32'h00000002, 32'h00000003};
  fork
    driveWRmaskWRaddr(WR_mask_driver_val, {15{1'bX}});
    driveWRdata(RAND_DATA0);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertTwoCycles(5);
  fork
    checkRDaddr_dma(RAND_DATA0, WR_mask_driver_val);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  @(posedge DUT.dmac_inst.DMA_MEM_WR_ACK);
  @(posedge clk);

  #(CYCLE_TIME);
  check_full(32'h04030000, 15'h0000, 16'hFFE3);
  ctr = 5;
  repeat (3) begin
    #(CYCLE_TIME);
    check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, 15'h0000, 16'hFFE3);
    ctr = ctr + 8'd4;
  end
  DC_DMA_WR_RQ <= 1'b1;
  @(posedge DUT.DC_DMA_WR_ACK);
  @(posedge clk);
  deassertAll();

  WR_mask_driver_val = 0;
  // Write 4083 bytes from ADDR 7 on disk to ADDR C in memory, but first need to clear initiate transfer bit
  RAND_DATA0 = {32'd0, 32'd4083, 32'h0000000C, 32'h00000007};
  fork
    driveWRmaskWRaddr(WR_mask_driver_val, {15{1'bX}});
    driveWRdata(RAND_DATA0);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertTwoCycles(5);
  fork
    checkRDaddr_dma(RAND_DATA0, WR_mask_driver_val);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  assertTwoCycles(4);
  WR_mask_driver_val = 0;
  // Write 4083 bytes from ADDR 7 on disk to ADDR C in memory.
  // Should only write the 4 MSBytes at the start
  // Will have 15 Bytes left over at the end
  RAND_DATA0 = {32'd1, 32'd4083, 32'h0000000C, 32'h00000007};
  fork
    driveWRmaskWRaddr(WR_mask_driver_val, {15{1'bX}});
    driveWRdata(RAND_DATA0);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertTwoCycles(5);
  fork
    checkRDaddr_dma(RAND_DATA0, WR_mask_driver_val);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  @(posedge DUT.dmac_inst.DMA_MEM_WR_ACK);
  @(posedge clk);

  addr_ctr = 1;
  ctr = 8'h0B;

  #(CYCLE_TIME);
  check_full(32'd0, 15'h0000, 16'h0FFF);
  #(CYCLE_TIME);
  check_full(32'd0, 15'h0000, 16'h0FFF);
  #(CYCLE_TIME);
  check_full(32'd0, 15'h0000, 16'h0FFF);
  #(CYCLE_TIME);
  check_full(32'h0a090807, 15'h0000, 16'h0FFF);

  repeat (254) begin
    #(CYCLE_TIME);
    @(posedge DUT.dmac_inst.DMA_MEM_WR_ACK);
    @(posedge clk);


    repeat (4) begin
      #(CYCLE_TIME);
      check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, {addr_ctr, 4'b0000}, 0);
      ctr = ctr + 8'd4;
    end

    addr_ctr = addr_ctr + 11'd1;
  end

  #(CYCLE_TIME);
  @(posedge DUT.dmac_inst.DMA_MEM_WR_ACK);
  @(posedge clk);

  #(CYCLE_TIME);
  check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd7,ctr+8'd6,ctr+8'd5,ctr+8'd4}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd11,ctr+8'd10,ctr+8'd9,ctr+8'd8}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd15,ctr+8'd14,ctr+8'd13,ctr+8'd12}, 15'h0FF0, 16'h8000);

  @(posedge DUT.arbiter_inst.NOBODY_BUSY);
  @(posedge clk);

  /*** REPEAT MEMORY CONTROLLER TESTING (TEST DMA TRANFSER BY INSPECTION) ***/
  assertTwoCycles(1);
  fork
    driveRDaddr(0 << 4);
    checkRDaddr_dma({8'h0A,8'h09,8'h08,8'h07,RAND_DATA0_SAVED_START[95:40],8'h05,8'h04,8'h03,RAND_DATA0_SAVED_START[15:0]}, 0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  ctr = 8'h0B;

  for (i = 1; i < 255; i = i + 1) begin
    assertTwoCycles(1);
    fork
      driveRDaddr(i << 4);
      checkRDaddr_dma({ctr+8'd15,ctr+8'd14,ctr+8'd13,ctr+8'd12,
                       ctr+8'd11,ctr+8'd10,ctr+8'd9,ctr+8'd8,
                       ctr+8'd7,ctr+8'd6,ctr+8'd5,ctr+8'd4,
                       ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr+8'd0}, 0);
      #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
    join
    ctr = ctr + 8'd16;
  end

  assertTwoCycles(1);
  fork
    driveRDaddr(i << 4);
    checkRDaddr_dma({RAND_DATA0_SAVED_END[127:120], {ctr+8'd14,ctr+8'd13,ctr+8'd12,
                       ctr+8'd11,ctr+8'd10,ctr+8'd9,ctr+8'd8,
                       ctr+8'd7,ctr+8'd6,ctr+8'd5,ctr+8'd4,
                       ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr+8'd0}}, 0);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule