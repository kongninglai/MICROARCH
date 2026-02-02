module  arbiter_tb;

initial begin
  $vcdplusfile("arbiter_tb.dump.vpd");
  $vcdpluson(0, arbiter_tb); 
end

localparam MEM_BYTE_CAPACITY = 32768;
localparam BURST_SIZE=4;
/* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
// Next few parameters are in units of ns
localparam DELAY_ADJ         = 0;
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
localparam V_CT_WR_ADDR      = ADDR_EN_TO_WR_EN - 1;
localparam V_CT_WR_EN        = WR_CLK_SPACING - 1;
localparam V_CT_WR_BRST      = (WR_DIS_TO_DATA_EN + ((BURST_SIZE-1) * WR_CLK_SPACING)) - 1;

localparam V_CT_WR_DIS       = (V_CT_WR_ADDR + 1) + (V_CT_WR_EN + 1) + (V_CT_WR_BRST + 1) - 1;
localparam V_CT_RD_DIS       = (V_CT_HIZ_PROT + 1) + (V_CT_RD_EN + 1) + (V_CT_RD_BRST + 1) + (V_CT_BUS_FREE + 1) - 1;

reg   rst, clk, DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_MEM_RD_RQ, DC_DMA_RD_RQ, DC_KB_RD_KBDR_RQ, DC_KB_RD_KBSR_RQ, IC_MEM_RD_RQ, DMA_MEM_WR_RQ;
wire  DC_WR_ACK, DC_RD_ACK, IC_RD_ACK, DMA_WR_ACK, 
                      MEM_WR, MEM_RD, DMA_WR, DMA_RD, KB_RD_KBDR, KB_RD_KBSR;

arbiter #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME(CYCLE_TIME), .DELAY_ADJ(DELAY_ADJ)) DUT (
  .rst(rst), .clk(clk),
  .DC_MEM_WR_RQ(DC_MEM_WR_RQ), .DC_DMA_WR_RQ(DC_DMA_WR_RQ), 
  .DC_MEM_RD_RQ(DC_MEM_RD_RQ), .DC_DMA_RD_RQ(DC_DMA_RD_RQ), 
  .DC_KB_RD_KBDR_RQ(DC_KB_RD_KBDR_RQ)  , .DC_KB_RD_KBSR_RQ(DC_KB_RD_KBSR_RQ), .IC_MEM_RD_RQ(IC_MEM_RD_RQ), .DMA_MEM_WR_RQ(DMA_MEM_WR_RQ),
  .DC_WR_ACK(DC_WR_ACK), .DC_RD_ACK(DC_RD_ACK), .IC_RD_ACK(IC_RD_ACK), .DMA_WR_ACK(DMA_WR_ACK), 
  .MEM_WR(MEM_WR), .MEM_RD(MEM_RD), .DMA_WR(DMA_WR), .DMA_RD(DMA_RD), .KB_RD_KBDR(KB_RD_KBDR), .KB_RD_KBSR(KB_RD_KBSR)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task assertSig;
  input integer idx;
  begin
    case(idx)
      0: DC_MEM_WR_RQ         = 1'b1;
      1: DC_DMA_WR_RQ         = 1'b1;
      2: DC_MEM_RD_RQ         = 1'b1;
      3: DC_DMA_RD_RQ         = 1'b1;
      4: DC_KB_RD_KBDR_RQ     = 1'b1;
      5: DC_KB_RD_KBSR_RQ     = 1'b1;
      6: IC_MEM_RD_RQ         = 1'b1;
      7: DMA_MEM_WR_RQ        = 1'b1;
      8: begin
        DC_KB_RD_KBDR_RQ      = 1'b1;
        DC_KB_RD_KBSR_RQ      = 1'b1;
      end
    endcase
  end
endtask

task deassertSig;
  input integer idx;
  begin
    case(idx)
      0: DC_MEM_WR_RQ         = 1'b0;
      1: DC_DMA_WR_RQ         = 1'b0;
      2: DC_MEM_RD_RQ         = 1'b0;
      3: DC_DMA_RD_RQ         = 1'b0;
      4: DC_KB_RD_KBDR_RQ     = 1'b0;
      5: DC_KB_RD_KBSR_RQ     = 1'b0;
      6: IC_MEM_RD_RQ         = 1'b0;
      7: DMA_MEM_WR_RQ        = 1'b0;
      8: begin
        DC_KB_RD_KBDR_RQ      = 1'b0;
        DC_KB_RD_KBSR_RQ      = 1'b0;
      end
    endcase
  end
endtask

task checkOutputs;
  input integer idx;
  reg   [3:0]   ACK_EXP;
  reg   [5:0]   RD_WR_EXP;
  begin
    case(idx)
      0: begin 
        ACK_EXP     = 1 << 3;
        RD_WR_EXP   = ~(1 << 5);
      end
      1: begin 
        ACK_EXP     = 1 << 3;
        RD_WR_EXP   = ~(1 << 3);
      end
      2: begin 
        ACK_EXP     = 1 << 2;
        RD_WR_EXP   = ~(1 << 4);
      end
      3: begin 
        ACK_EXP     = 1 << 2;
        RD_WR_EXP   = ~(1 << 2);
      end
      4: begin 
        ACK_EXP     = 1 << 2;
        RD_WR_EXP   = ~(1 << 1);
      end
      5: begin 
        ACK_EXP     = 1 << 2;
        RD_WR_EXP   = ~(1 << 0);
      end
      6: begin 
        ACK_EXP     = 1 << 1;
        RD_WR_EXP   = ~(1 << 4);
      end
      7: begin 
        ACK_EXP     = 1 << 0;
        RD_WR_EXP   = ~(1 << 5);
      end
      8: begin 
        ACK_EXP     = 1 << 2;
        RD_WR_EXP   = ~((1 << 0) | (1 << 1));
      end
    endcase

    if (({DC_WR_ACK,DC_RD_ACK,IC_RD_ACK,DMA_WR_ACK} !== ACK_EXP) ||
        ({MEM_WR, MEM_RD, DMA_WR, DMA_RD, KB_RD_KBDR, KB_RD_KBSR} !== RD_WR_EXP)) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. ACK_EXP = %b, ACK = %b, RD_WR_EXP = %b, RD_WR = %b\n", 
                $time, ACK_EXP, {DC_WR_ACK,DC_RD_ACK,IC_RD_ACK,DMA_WR_ACK}, RD_WR_EXP, {MEM_WR, MEM_RD, DMA_WR, DMA_RD, KB_RD_KBDR, KB_RD_KBSR});
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. ACK_EXP = %b, ACK = %b, RD_WR_EXP = %b, RD_WR = %b\n", 
      //           $time, ACK_EXP, {DC_WR_ACK,DC_RD_ACK,IC_RD_ACK,DMA_WR_ACK}, RD_WR_EXP, {MEM_WR, MEM_RD, DMA_WR, DMA_RD, KB_RD_KBDR, KB_RD_KBSR});
    end
  end
endtask

task testWrite;
  input integer idx;
  begin
    assertSig(idx);
    // Currently in [000]
    #(CYCLE_TIME);
    // Currently in [001] or [110]. DC_WR_ACK or DMA_WR_ACK is asserted here.
    #(CYCLE_TIME);
    checkOutputs(idx);
    // Currently in [110]... wait for 1 cycle to deassertSig to simulate the requesting entity receiving ACK
    #(CYCLE_TIME);
    deassertSig(idx);
    // Wait for transition back to [000]
    #(((V_CT_WR_DIS + 1) - 1) * CYCLE_TIME);
  end
endtask

task testRead;
  input integer idx;
  begin
    assertSig(idx);
    // Currently in [000]
    #(CYCLE_TIME);
    // Currently in [001] or [110]. DC_WR_ACK or DMA_WR_ACK is asserted here.
    #(CYCLE_TIME);
    checkOutputs(idx);
    // Currently in [010]... wait for 1 cycle to deassertSig to simulate the requesting entity receiving ACK
    #(CYCLE_TIME);
    deassertSig(idx);
    // // Wait for transition back to [000]
    #(((V_CT_RD_DIS + 1) - 1) * CYCLE_TIME);
  end
endtask

task assertAll;
  integer i;
  begin
    for (i = 0; i < 8; i = i + 1) begin
      assertSig(i);
    end
  end
endtask

task deassertAll;
  integer i;
  begin
    for (i = 0; i < 8; i = i + 1) begin
      deassertSig(i);
    end
  end
endtask

integer i;

initial begin
  
  rst = 1'b1;
  deassertAll();
  #(CYCLE_TIME);
  rst <= 1'b0;
  #(CYCLE_TIME);
  rst <= 1'b1;
  #(0.5*CYCLE_TIME);

  #(CYCLE_TIME);


  testWrite(0);
  testWrite(1);
  testWrite(7);

  testRead(2);
  testRead(3);
  testRead(4);
  testRead(5);
  testRead(6);
  testRead(8);


  // Now test multiple requests

  assertAll();
  deassertSig(1); // 0 and 1 are never simultaneously requested (D$ writes)
  deassertSig(3); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(4); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(5); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  testWrite(0);
  testRead(2);
  testRead(6);
  testWrite(7);

  assertAll();
  deassertSig(0); // 0 and 1 are never simultaneously requested (D$ writes)
  deassertSig(2); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(4); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(5); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  testWrite(1);
  testRead(3);
  testRead(6);
  testWrite(7);

  assertAll();
  deassertSig(0); // 0 and 1 are never simultaneously requested (D$ writes)
  deassertSig(2); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(3); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(5); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  testWrite(1);
  testRead(4);
  testRead(6);
  testWrite(7);

  assertAll();
  deassertSig(0); // 0 and 1 are never simultaneously requested (D$ writes)
  deassertSig(2); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  deassertSig(3); // 2, 3, and 4/5 are never simultaneously requested (D$ reads)
  testWrite(1);
  testRead(8);
  testRead(6);
  testWrite(7);

  #(8*CYCLE_TIME);
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule