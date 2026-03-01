module  dmac_tb;

initial begin
  $vcdplusfile("dmac_tb.dump.vpd");
  $vcdpluson(0, dmac_tb); 
  $vcdpluson(0, dmac_tb.DUT); 
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

reg     rst, clk, DC_DMA_WR_ACK, DC_DMA_RD_ACK, DMA_MEM_WR_ACK;

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

wire  DMA_MEM_WR_RQ, DMA_INT;

wire          DMAC_BUSY, DATA_VALID_BAR;


dmac #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DUT (
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
    DMA_MEM_WR_ACK  <= 1'b0;
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
      2: begin
        DMA_MEM_WR_ACK    <= 1'b1;
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

reg [7:0] ctr;
reg [10:0] addr_ctr;

initial begin
  rst                     <= 1'b0;
  DMA_MEM_WR_ACK          <= 1'b0;
  deassertAll();
  stopAllDrivers();
  #(1.5 * CYCLE_TIME);
  rst               <= 1'b1;
  #(CYCLE_TIME);

  assertOneCycle(0);
  WR_mask_driver_val = 0;
  // Write 3 bytes from ADDR 3 on disk to ADDR 12 in memory
  RAND_DATA0 = {32'd1, 32'd3, 32'h00000012, 32'h00000003};
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

  #(80 * CYCLE_TIME);
  
  assertOneCycle(2);

  #(CYCLE_TIME);
  check_full(32'h04030000, 15'h0010, 16'hFFE3);
  ctr = 5;
  repeat (3) begin
    #(CYCLE_TIME);
    check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, 15'h0010, 16'hFFE3);
    ctr = ctr + 8'd4;
  end

  assertOneCycle(0);
  WR_mask_driver_val = 0;
  // Write 4083 bytes from ADDR 7 on disk to ADDR C in memory, but first need to clear initiate transfer bit
  RAND_DATA0 = {32'd0, 32'd4083, 32'h0000000C, 32'h00000007};
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

  assertOneCycle(0);
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

  assertOneCycle(1);
  fork
    checkRDaddr(RAND_DATA0, WR_mask_driver_val);
    #((RD_EN_CYCLES + 2*RANK_BURST_SIZE) * CYCLE_TIME);
  join

  #(80 * CYCLE_TIME);
  
  assertOneCycle(2);

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
    assertOneCycle(2);

    repeat (4) begin
      #(CYCLE_TIME);
      check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, {addr_ctr, 4'b0000}, 0);
      ctr = ctr + 8'd4;
    end

    addr_ctr = addr_ctr + 11'd1;
  end

  #(CYCLE_TIME);
  assertOneCycle(2);

  #(CYCLE_TIME);
  check_full({ctr+8'd3,ctr+8'd2,ctr+8'd1,ctr}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd7,ctr+8'd6,ctr+8'd5,ctr+8'd4}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd11,ctr+8'd10,ctr+8'd9,ctr+8'd8}, 15'h0FF0, 16'h8000);
  #(CYCLE_TIME);
  check_full({ctr+8'd15,ctr+8'd14,ctr+8'd13,ctr+8'd12}, 15'h0FF0, 16'h8000);

  #(CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule