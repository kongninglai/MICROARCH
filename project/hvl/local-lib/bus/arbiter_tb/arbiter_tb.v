module  arbiter_tb;

initial begin
  $vcdplusfile("arbiter_tb.dump.vpd");
  $vcdpluson(0, arbiter_tb); 
end

reg   rst, clk, 
      MEM_BUSY,
      DMAC_BUSY,
      KB_BUSY,
      DC_MEM_RD_RQ,
      DC_DMA_RD_RQ,
      DC_KB_RD_RQ,
      DC_MEM_WR_RQ,
      DC_DMA_WR_RQ,
      DC_KB_WR_RQ,
      IC_MEM_RD_RQ,
      DMA_MEM_WR_RQ;

wire  DC_MEM_RD_ACK,
      DC_DMA_RD_ACK,
      DC_KB_RD_ACK,
      DC_MEM_WR_ACK,
      DC_DMA_WR_ACK,
      DC_KB_WR_ACK,
      IC_MEM_RD_ACK,
      DMA_MEM_WR_ACK;

arbiter (
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
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK),
  .DC_DMA_RD_ACK(DC_DMA_RD_ACK),
  .DC_KB_RD_ACK(DC_KB_RD_ACK),
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK),
  .DC_DMA_WR_ACK(DC_DMA_WR_ACK),
  .DC_KB_WR_ACK(DC_KB_WR_ACK),
  .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME = 10;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task deassertAll;
  integer j;
  begin
    for (j = 0; j < 8; j = j + 1) begin
      deassertSig(j);
    end
  end
endtask

task assertSig;
  input integer idx;
  begin
    case(idx)
      0: DC_MEM_RD_RQ     = 1'b1;
      1: DC_DMA_RD_RQ     = 1'b1;
      2: DC_KB_RD_RQ      = 1'b1;
      3: DC_MEM_WR_RQ     = 1'b1;
      4: DC_DMA_WR_RQ     = 1'b1;
      5: DC_KB_WR_RQ      = 1'b1;
      6: IC_MEM_RD_RQ     = 1'b1;
      7: DMA_MEM_WR_RQ    = 1'b1;
    endcase
  end
endtask

task deassertSig;
  input integer idx;
  begin
    case(idx)
      0: DC_MEM_RD_RQ     = 1'b0;
      1: DC_DMA_RD_RQ     = 1'b0;
      2: DC_KB_RD_RQ      = 1'b0;
      3: DC_MEM_WR_RQ     = 1'b0;
      4: DC_DMA_WR_RQ     = 1'b0;
      5: DC_KB_WR_RQ      = 1'b0;
      6: IC_MEM_RD_RQ     = 1'b0;
      7: DMA_MEM_WR_RQ    = 1'b0;
    endcase
  end
endtask

task checkOutputs;
  input integer idx;
  reg   [7:0]   ACK_EXP;
  begin
    ACK_EXP     = 1 << (7 - idx);

    if (({DC_MEM_RD_ACK,
          DC_DMA_RD_ACK,
          DC_KB_RD_ACK,
          DC_MEM_WR_ACK,
          DC_DMA_WR_ACK,
          DC_KB_WR_ACK,
          IC_MEM_RD_ACK,
          DMA_MEM_WR_ACK} !== ACK_EXP)) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. ACK_EXP = %b, ACK = %b\n", 
                $time, ACK_EXP, { DC_MEM_RD_ACK,
                                  DC_DMA_RD_ACK,
                                  DC_KB_RD_ACK,
                                  DC_MEM_WR_ACK,
                                  DC_DMA_WR_ACK,
                                  DC_KB_WR_ACK,
                                  IC_MEM_RD_ACK,
                                  DMA_MEM_WR_ACK});
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. ACK_EXP = %b, ACK = %b\n", 
      //           $time, ACK_EXP, { DC_MEM_RD_ACK,
      //                             DC_DMA_RD_ACK,
      //                             DC_KB_RD_ACK,
      //                             DC_MEM_WR_ACK,
      //                             DC_DMA_WR_ACK,
      //                             DC_KB_WR_ACK,
      //                             IC_MEM_RD_ACK,
      //                             DMA_MEM_WR_ACK});
    end
  end
endtask

task test;
  input integer idx;
  begin
    assertSig(idx);
    #(2 * CYCLE_TIME);
    deassertAll();
    checkOutputs(idx);
    #(CYCLE_TIME);
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

integer i;

initial begin
  
  rst = 1'b1;
  MEM_BUSY      <= 1'b0;
  DMAC_BUSY     <= 1'b0;
  KB_BUSY       <= 1'b0;
  deassertAll();
  #(CYCLE_TIME);
  rst <= 1'b0;
  #(CYCLE_TIME);
  rst <= 1'b1;
  #(0.5*CYCLE_TIME);

  #(CYCLE_TIME);

  for (i = 0; i < 8; i = i + 1) begin
    test(i);
  end

  
  assertAll();
  deassertSig(1);
  deassertSig(2);
  deassertSig(4);
  deassertSig(5);
  #(2 * CYCLE_TIME);
  checkOutputs(0);
  deassertAll();

  assertAll();
  deassertSig(0);
  deassertSig(2);
  deassertSig(3);
  deassertSig(5);
  #(2 * CYCLE_TIME);
  checkOutputs(1);
  deassertAll();

  assertAll();
  deassertSig(0);
  deassertSig(1);
  deassertSig(3);
  deassertSig(4);
  #(2 * CYCLE_TIME);
  checkOutputs(2);
  deassertAll();

  for (i = 3; i < 6; i = i + 1) begin
    assertSig(i);
    assertSig(6);
    assertSig(7);
    #(2 * CYCLE_TIME);
    checkOutputs(i);
    deassertAll();
  end

  assertSig(6);
  assertSig(7);
  #(2 * CYCLE_TIME);
  checkOutputs(6);
  deassertAll();

  assertSig(7);
  #(2 * CYCLE_TIME);
  checkOutputs(7);
  deassertAll();

  #(8*CYCLE_TIME);
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule