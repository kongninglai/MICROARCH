module tlb_tb;

initial begin
  $vcdplusfile("tlb_tb.dump.vpd");
  $vcdpluson(0, tlb_tb);
  $vcdpluson(0, tlb_tb.DUT.TLB_ENTRIES_BEHAV);
  $vcdpluson(0, tlb_tb.REF.TLB_ENTRIES_BEHAV);
end

localparam VA_BIT_WIDTH=32;
localparam PA_BIT_WIDTH=15;
localparam PAGE_SIZE_BYTES=4096;
localparam PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES);
localparam VPN_BIT_WIDTH=VA_BIT_WIDTH-PAGE_BIT_WIDTH;
localparam PFN_BIT_WIDTH=PA_BIT_WIDTH-PAGE_BIT_WIDTH;

reg  [VPN_BIT_WIDTH-1:0]  TLB_VPN;

wire [PFN_BIT_WIDTH-1:0]  TLB_PFN_OUT, TLB_PFN_OUT_BEHAV;
wire                       TLB_WRITE_DISABLE_OUT, TLB_CACHE_ENABLE_OUT, TLB_PAGE_FAULT_OUT;
wire                       TLB_WRITE_DISABLE_OUT_BEHAV, TLB_CACHE_ENABLE_OUT_BEHAV, TLB_PAGE_FAULT_OUT_BEHAV;

tlb DUT (
  .TLB_VPN(TLB_VPN),
  .TLB_PFN_OUT(TLB_PFN_OUT),
  .TLB_WRITE_DISABLE_OUT(TLB_WRITE_DISABLE_OUT),
  .TLB_CACHE_ENABLE_OUT(TLB_CACHE_ENABLE_OUT),
  .TLB_PAGE_FAULT_OUT(TLB_PAGE_FAULT_OUT)
);

tlb_behav REF (
  .TLB_VPN(TLB_VPN),
  .TLB_PFN_OUT(TLB_PFN_OUT_BEHAV),
  .TLB_WRITE_DISABLE_OUT(TLB_WRITE_DISABLE_OUT_BEHAV),
  .TLB_CACHE_ENABLE_OUT(TLB_CACHE_ENABLE_OUT_BEHAV),
  .TLB_PAGE_FAULT_OUT(TLB_PAGE_FAULT_OUT_BEHAV)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  begin
    if (TLB_PFN_OUT           !== TLB_PFN_OUT_BEHAV           ||
        TLB_WRITE_DISABLE_OUT !== TLB_WRITE_DISABLE_OUT_BEHAV ||
        TLB_CACHE_ENABLE_OUT  !== TLB_CACHE_ENABLE_OUT_BEHAV  ||
        TLB_PAGE_FAULT_OUT    !== TLB_PAGE_FAULT_OUT_BEHAV) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t VPN=%h", $time, TLB_VPN);
      $display("PFN %h vs %h", TLB_PFN_OUT, TLB_PFN_OUT_BEHAV);
      $display("WR_DIS %b vs %b", TLB_WRITE_DISABLE_OUT, TLB_WRITE_DISABLE_OUT_BEHAV);
      $display("CACHE_EN %b vs %b", TLB_CACHE_ENABLE_OUT, TLB_CACHE_ENABLE_OUT_BEHAV);
      $display("PAGE_FAULT %b vs %b\n", TLB_PAGE_FAULT_OUT, TLB_PAGE_FAULT_OUT_BEHAV);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

initial begin
  TLB_VPN = ~(20'h02000);
  #5;
  check();
  TLB_VPN = 20'h02000;
  #5;
  check();
  repeat (1 << (VPN_BIT_WIDTH - 4)) begin
    #5;
    check();
    TLB_VPN = TLB_VPN + 1;
  end
  #5;
  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule