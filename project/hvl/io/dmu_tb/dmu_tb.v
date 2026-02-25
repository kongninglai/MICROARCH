module  dmu_tb;

initial begin
  $vcdplusfile("dmu_tb.dump.vpd");
  $vcdpluson(0, dmu_tb); 
  $vcdpluson(0, dmu_tb.DUT); 
end

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

localparam CYCLE_TIME        = 9;

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
localparam V_CT_WR_ADDR      = ADDR_EN_TO_WR_EN - 1;
localparam V_CT_WR_EN        = WR_CLK_SPACING - 1;
localparam V_CT_WR_BRST      = (WR_DIS_TO_DATA_EN + ((BURST_SIZE-1) * WR_CLK_SPACING)) - 1;

reg     rst, clk, RD, WR;

reg   [15:0]  WR_mask, WR_mask_val;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;

wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};

wire  [2:0]   STATE = {dmu_tb.DUT.Q2, dmu_tb.DUT.Q1, dmu_tb.DUT.Q0};
wire  [2:0]   NEXT_STATE = {dmu_tb.DUT.D2, dmu_tb.DUT.D1, dmu_tb.DUT.D0};

wire  [127:0] DMA_config;


dmu #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME(CYCLE_TIME), .DELAY_ADJ(DELAY_ADJ)) DUT (
  .rst(rst), .clk(clk), .RD(RD), .WR(WR), .WR_mask(WR_mask),
  .DATA_BUS(DATA_BUS), .DMA_config(DMA_config)
);

integer SUCCESSES = 0;
integer FAILURES = 0;

integer i;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task check_read;
  input [14:0]  ADDR;
  input integer mask_low;
  reg   [31:0]  DIO_exp;
  begin
    DIO_exp[7:0]    = WR_mask_val[mask_low]   ? 8'h00 : ADDR[7:0];
    DIO_exp[15:8]   = WR_mask_val[mask_low+1] ? 8'h00 : {1'b0, ADDR[14:8]};
    DIO_exp[23:16]  = WR_mask_val[mask_low+2] ? 8'h00 : 8'h00;
    DIO_exp[31:24]  = WR_mask_val[mask_low+3] ? 8'h00 : 8'h00;
    if (DATA_BUS !== DIO_exp) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DIO_exp = %h, DATA_BUS = %h\n", 
                $time, DIO_exp, DATA_BUS);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. DIO_exp = %h, DATA_BUS = %h\n", 
      //           $time, DIO_exp, DATA_BUS);
    end
  end
endtask

task read;
  begin
    // Currently in IDLE [000]
    // Force transition to [001]
    RD <= 0;
    WR <= 1;
    // WR_mask               <= 16'hFFFF;
    #(CYCLE_TIME);

    // Currently in [001]
    RD <= 1;
    #((V_CT_HIZ_PROT + 1) * CYCLE_TIME);

    // Currently in [010]
    #((V_CT_RD_EN + 1) * CYCLE_TIME);

    // Currently in [011]
    #((V_CT_RD_BRST + 1) * CYCLE_TIME);

    // Currently in [100]
    #(((V_CT_BUS_FREE + 1) * CYCLE_TIME) - DELAY_ADJ);
  end
endtask

task read_addr_data;
  input [14:0] ADDR;
  begin
    #(CYCLE_TIME);                                    // Wait for transition to [001]
    DATA_driver_enable    <= 1'b0;                    // Release data bus
    #((V_CT_HIZ_PROT + 1) * CYCLE_TIME);              // Wait for transition to [010]
    #((V_CT_RD_EN + 1) * CYCLE_TIME);                 // Wait for transition to [011]
    #(((RD_DIS_TO_DATA_V) * CYCLE_TIME) - DELAY_ADJ); // Wait for data to become valid
    check_read(ADDR,0);                               // Check D0
    #((RD_CLK_SPACING) * CYCLE_TIME);                 // Wait for data to become valid
    check_read(ADDR+4,4);                             // Check D1
    #((RD_CLK_SPACING) * CYCLE_TIME);                 // Wait for data to become valid
    check_read(ADDR+8,8);                             // Check D2
    #((RD_CLK_SPACING-1) * CYCLE_TIME);               // Wait for deasserting address
    #(DELAY_ADJ);           
    #((CYCLE_TIME)-DELAY_ADJ);                        // Wait for data to become valid
    check_read(ADDR+12,12);                           // Check D3
    #(((RD_TO_BUS_FREE) * CYCLE_TIME));     // Wait for data bus to release
  end
endtask

task write;
  begin
    // Currently in IDLE [000]
    #(DELAY_ADJ);                                     // Simulate tristate bus driver delay

    // Force transition to [101]
    RD                    <= 1'b1;
    WR                    <= 1'b0;
    WR_mask               <= WR_mask_val;
    #(CYCLE_TIME);
    // Currently in [101]
    WR                    <= 1'b1;
    // WR_mask               <= 16'hFFFF;
    #((V_CT_WR_ADDR + 1) * CYCLE_TIME);

    // Currently in [110]
    #((V_CT_WR_EN + 1) * CYCLE_TIME);

    // Currently in [111]
    #(((V_CT_WR_BRST + 1) * CYCLE_TIME));
  end
endtask


task write_addr_data;
  input [14:0] ADDR;
  input [31:0] DATA;
  begin
    #(CYCLE_TIME);                        // Wait for transition to [101]
    #(DELAY_ADJ);                         // Simulate tristate bus driver delay
    DATA_driver_enable    <= 1'b1;        // Take data bus
    DATA_driver           <= DATA;        // Drive D0 value
    #((V_CT_WR_ADDR + 1) * CYCLE_TIME);   // Wait for transition to [110]
    #((V_CT_WR_EN + 1) * CYCLE_TIME);     // Wait for transition to [111]

    #((WR_DIS_TO_DATA_EN) * CYCLE_TIME);  // Wait for chance to change data
    DATA_driver           <= DATA+4;      // Drive D1 value
    #((WR_CLK_SPACING) * CYCLE_TIME);     // Wait for chance to change data
    DATA_driver           <= DATA+8;      // Drive D2 value
    #((WR_CLK_SPACING) * CYCLE_TIME);     // Wait for chance to change data
    DATA_driver           <= DATA+12;     // Drive D3 value
    #((WR_CLK_SPACING) * CYCLE_TIME);     // Wait for chance to change data
    DATA_driver_enable    <= 1'b0;        // Release data bus
    DATA_driver           <= 'bz;         // Release data bus
  end
endtask

initial begin
  WR_mask_val           = 16'h0000;
  WR_mask               <= WR_mask_val;
  rst = 1'b1;
  WR                    <= 1'b1;
  // WR_mask               <= 16'hFFFF;
  RD                    <= 1'b1;
  DATA_driver_enable    <= 1'b0;
  DATA_driver           <= {32{1'bz}};
  #(CYCLE_TIME);
  rst <= 1'b0;
  #(CYCLE_TIME);
  rst <= 1'b1;
  #(0.5*CYCLE_TIME);


  for (i = 0; i < 32768; i = i + 16) begin
    
    fork
      write();
      write_addr_data(i, i);
    join
    fork
      read();
      read_addr_data(i);
    join
  end
  #(10*CYCLE_TIME);



  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule