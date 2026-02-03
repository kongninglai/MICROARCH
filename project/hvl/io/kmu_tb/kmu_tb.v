module  kmu_tb;

initial begin
  $vcdplusfile("kmu_tb.dump.vpd");
  $vcdpluson(0, kmu_tb); 
end

reg           rst, clk, RD_KBDR, RD_KBSR, WE;
reg   [31:0]  new_data;
wire  [31:0]  DATA_BUS;

localparam MEM_BYTE_CAPACITY = 32768;
localparam BURST_SIZE=4;
/* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
// Next few parameters are in units of ns
localparam DELAY_ADJ         = 7;
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
localparam WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1) + WR_DIS_TO_DATA_EN; // again to protect DIO -> posedge WR for ALL ranks
localparam V_CT_HIZ_PROT     = ADDR_HIZ_PROT - 1;
localparam V_CT_RD_EN        = RD_EN_DURATION - 1;
localparam V_CT_RD_BRST      = (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1;
localparam V_CT_BUS_FREE     = RD_TO_BUS_FREE - 1;

localparam V_CT_DRIVE_STAT   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) + RD_TO_BUS_FREE - 1;
localparam V_CT_DRIVE_DATA   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1;
localparam V_CT_CLR_RDY      = RD_TO_BUS_FREE - 1;

kmu DUT(
  .rst(rst), .clk(clk), .RD_KBDR(RD_KBDR), .RD_KBSR(RD_KBSR),
  .WE(WE), .new_data(new_data), .DATA_BUS(DATA_BUS)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task toggle_RD_KBSR;
  begin
    RD_KBSR   <= 0;
    #(CYCLE_TIME);
    RD_KBSR   <= 1;
    #(CYCLE_TIME);
  end
endtask

task toggle_RD_KBDR;
  begin
    RD_KBDR   <= 0;
    #(CYCLE_TIME);
    RD_KBDR   <= 1;
    #(CYCLE_TIME);
  end
endtask

task toggle_both_RD;
  begin
    RD_KBDR   <= 0;
    RD_KBSR   <= 0;
    #(CYCLE_TIME);
    RD_KBDR   <= 1;
    RD_KBSR   <= 1;
    #(CYCLE_TIME);
  end
endtask

task toggle_WE;
  begin
    WE        <= 0;
    #(CYCLE_TIME);
    WE        <= 1;
    #(CYCLE_TIME);
  end
endtask

task check;
  input [31:0]  DATA_BUS_EXP;
  begin
    if (DATA_BUS !== DATA_BUS_EXP) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DATA_BUS_EXP = %h, DATA_BUS = %h\n", 
                $time, DATA_BUS_EXP, DATA_BUS);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. DATA_BUS_EXP = %h, DATA_BUS = %h\n", 
      //           $time, DATA_BUS_EXP, DATA_BUS);
    end
  end
endtask

integer i;

initial begin
  new_data  <= 32'h0001FFFF;
  WE        <= 1;
  rst       <= 1;
  RD_KBDR   <= 1;
  RD_KBSR   <= 1;
  #(CYCLE_TIME);
  rst       <= 0;
  #(CYCLE_TIME);
  rst       <= 1;
  #(0.5*CYCLE_TIME);
  toggle_WE();

  #(DELAY_ADJ);
  toggle_RD_KBSR();
  #(CYCLE_TIME*(V_CT_DRIVE_STAT-1) - DELAY_ADJ);
  check(new_data);
  #(CYCLE_TIME);

  #(DELAY_ADJ);
  toggle_RD_KBDR();
  #(CYCLE_TIME*(V_CT_DRIVE_DATA-1) - DELAY_ADJ);
  check(new_data);
  #(CYCLE_TIME);

  #(DELAY_ADJ);
  #(CYCLE_TIME*(V_CT_CLR_RDY + 1));
  toggle_RD_KBSR();
  #(CYCLE_TIME*(V_CT_DRIVE_STAT-1) - DELAY_ADJ);
  check(new_data & 32'h0000FFFF);
  #(CYCLE_TIME);

  
  new_data  <= 32'h0001BEEF;
  toggle_WE();

  #(DELAY_ADJ);
  toggle_RD_KBSR();
  #(CYCLE_TIME*(V_CT_DRIVE_STAT-1) - DELAY_ADJ);
  check(new_data);
  #(CYCLE_TIME);


  #(DELAY_ADJ);
  toggle_both_RD();
  #(CYCLE_TIME*(V_CT_DRIVE_DATA-1) - DELAY_ADJ);
  check(new_data);
  #(CYCLE_TIME);

  #(DELAY_ADJ);
  #(CYCLE_TIME*(V_CT_CLR_RDY + 1));
  toggle_RD_KBSR();
  #(CYCLE_TIME*(V_CT_DRIVE_STAT-1) - DELAY_ADJ);
  check(new_data & 32'h0000FFFF);
  #(CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule
