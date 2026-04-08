module  mcu_tb;

initial begin
  // $vcdplusfile("mcu_tb.dump.vpd");
  // $vcdpluson(0, mcu_tb); 
  // $vcdpluson(0, mcu_tb.DUT); 
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
localparam CYCLE_TIME_X10            = 97;
localparam RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1);
localparam ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1);
localparam V_CT_WRITE_DONE           = WR_AND_DATA_EN_CYCLES - 1;
localparam V_CT_RD_EN_DONE           = RD_EN_CYCLES - 1;
localparam V_CT_SHORT_BRST_DONE      = (RANK_BURST_SIZE - 1) - 1;

localparam DELAY_ADJ = 5.5;

reg     rst, clk, DC_MEM_WR_ACK, DMA_MEM_WR_ACK, DC_MEM_RD_ACK, IC_MEM_RD_ACK;

reg   [15:0]  WR_mask_driver;
reg           WR_mask_driver_enable;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

reg   [127:0] RAND_DATA0;
reg   [127:0] RAND_DATA1;
reg   [127:0] RAND_DATA2;
reg   [127:0] RAND_DATA3;

wire  [15:0]  WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {16{1'bz}};
wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};
wire   [14:0]  ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {15{1'bz}};

wire          MEM_BUSY, DATA_VALID_BAR;


mcu #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst          (rst          )    , .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK)    , .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK)    , .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .MEM_BUSY     (MEM_BUSY     )    , .DATA_VALID_BAR(DATA_VALID_BAR)
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
    #(DELAY_ADJ);
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
  input [RANK_BIT_WIDTH-1:0] EXPECTED_DATA0, EXPECTED_DATA1;
  begin
    #(2 * CYCLE_TIME);
    while (DATA_VALID_BAR === 1'b1) begin
      #(CYCLE_TIME);
    end
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


initial begin
  rst               <= 1'b0;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);
  rst               <= 1'b1;
  #(CYCLE_TIME);

  // for (i = 0; i < 4; i = i + 1) begin
  for (i = 0; i < 2047; i = i + 1) begin
    assertOneCycle(0);
    RAND_DATA0 = {$random, $random, $random, $random};
    RAND_DATA1 = {$random, $random, $random, $random};
    fork
      driveWRmaskWRaddr(16'h0000, (i << 4));
      driveWRdata(RAND_DATA0);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(0);
    fork
      driveWRmaskWRaddr(16'h0000, ((i+1) << 4));
      driveWRdata(RAND_DATA1);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(2);
    fork
      driveRDaddr(i << 4);
      checkRDaddr(RAND_DATA0, RAND_DATA1);
      #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
    join
  end

  rst = 1'b0;
  #(2 * CYCLE_TIME);
  rst = 1'b1;
  #(CYCLE_TIME);

  // for (i = 0; i < 4; i = i + 4) begin
  for (i = 0; i < 2048; i = i + 4) begin
    assertOneCycle(0);
    RAND_DATA0 = {$random, $random, $random, $random};
    RAND_DATA1 = {$random, $random, $random, $random};
    RAND_DATA2 = {$random, $random, $random, $random};
    RAND_DATA3 = {$random, $random, $random, $random};
    fork
      driveWRmaskWRaddr(16'h0000, (i << 4));
      driveWRdata(RAND_DATA0);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(0);
    fork
      driveWRmaskWRaddr(16'h0000, ((i+1) << 4));
      driveWRdata(RAND_DATA1);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(0);
    fork
      driveWRmaskWRaddr(16'h0000, ((i+2) << 4));
      driveWRdata(RAND_DATA2);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(0);
    fork
      driveWRmaskWRaddr(16'h0000, ((i+3) << 4));
      driveWRdata(RAND_DATA3);
    join
    #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

    assertOneCycle(2);
    fork
      driveRDaddr(i << 4);
      checkRDaddr(RAND_DATA0, RAND_DATA1);
      #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
    join

    assertOneCycle(2);
    fork
      driveRDaddr((i+2) << 4);
      checkRDaddr(RAND_DATA2, RAND_DATA3);
      #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
    join
  end

  #(10 * CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule