module  kmu_tb;

initial begin
  $vcdplusfile("kmu_tb.dump.vpd");
  $vcdpluson(0, kmu_tb); 
end

reg           rst, clk, RD_KBDR, RD_KBSR, WE;
reg   [31:0]  new_data;
wire  [31:0]  DATA_BUS;

localparam CYCLE_TIME    = 10;
localparam CYCLES_LOW    = 1;
localparam CYCLES_VALID  = 1;

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
      $display("SUCCESS AT TIME %t. DATA_BUS_EXP = %h, DATA_BUS = %h\n", 
                $time, DATA_BUS_EXP, DATA_BUS);
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
  toggle_RD_KBSR();
  check(new_data);
  toggle_RD_KBDR();
  check(new_data & 32'h0000FFFF);
  toggle_RD_KBSR();
  check(new_data & 32'h0000FFFF);

  #(CYCLE_TIME);
  new_data  <= 32'h0001BEEF;
  toggle_WE();
  toggle_RD_KBSR();
  check(new_data);
  toggle_both_RD();
  check(new_data & 32'h0000BEEF);
  toggle_RD_KBSR();
  check(new_data & 32'h0000BEEF);
  
  #(10*CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule
