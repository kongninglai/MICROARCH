module  dmu_tb;

initial begin
  $vcdplusfile("dmu_tb.dump.vpd");
  $vcdpluson(0, dmu_tb); 
  $vcdpluson(0, dmu_tb.DUT); 
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

reg     rst, clk, DC_DMA_WR_ACK, DC_DMA_RD_ACK;

reg   [15:0]  WR_mask_driver, WR_mask_driver_val;
reg           WR_mask_driver_enable;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

reg   [127:0] RAND_DATA0;

wire  [15:0]  WR_mask  = WR_mask_driver_enable ? WR_mask_driver : {16{1'bz}};
wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};
wire  [14:0]  ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {15{1'bz}};

wire  [RANK_BIT_WIDTH-1:0]    DMA_config;

wire          DMAC_BUSY, DATA_VALID_BAR;  


dmu #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
  .rst          (rst          )    , .clk(clk), 
  .DC_DMA_WR_ACK(DC_DMA_WR_ACK)      ,
  .DC_DMA_RD_ACK(DC_DMA_RD_ACK)      , 
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .DMAC_BUSY      (DMAC_BUSY     )     , .DATA_VALID_BAR(DATA_VALID_BAR), .DMA_config(DMA_config)
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
    DC_DMA_WR_ACK   <= 1'b0;
    DC_DMA_RD_ACK   <= 1'b0;
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
        DC_DMA_WR_ACK     <= 1'b1;
      end
      1: begin 
        DC_DMA_RD_ACK     <= 1'b1;
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
      // $display("SUCCESS AT TIME %t. EXP = %h, DATA = %h\n", 
      //           $time, EXPECTED_DATA, DATA_BUS);
    end
  end
endtask


task checkRDaddr;
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


initial begin
  rst                     <= 1'b0;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);
  rst               <= 1'b1;
  #(CYCLE_TIME);

  assertOneCycle(0);
  WR_mask_driver_val = $random;
  RAND_DATA0 = {$random, $random, $random, $random};
  fork
    driveWRmaskWRaddr(WR_mask_driver_val, {15{1'bX}});
    driveWRdata(RAND_DATA0);
  join
  #(WR_AND_DATA_EN_CYCLES * CYCLE_TIME);

  assertOneCycle(1);
  fork
    checkRDaddr(RAND_DATA0, WR_mask_driver_val);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule