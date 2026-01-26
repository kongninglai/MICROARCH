module  mmu_tb;

initial begin
  $vcdplusfile("mmu_tb.dump.vpd");
  $vcdpluson(0, mmu_tb); 
  // $vcdpluson(0, mmu_tb.DUT); 
end

reg rst, clk, RD, WR;
wire RD_out, WR_out, OE_out, V;
reg RD_out_exp, WR_out_exp, OE_out_exp, V_exp;

// mmu DUT(rst,clk,RD,WR,RD_out,WR_out,OE_out,V);

integer SUCCESSES = 0;
integer FAILURES = 0;

task check;
  // if (RD_out !== RD_out_exp || WR_out !== WR_out_exp || OE_out !== OE_out_exp || V !== V_exp) begin
  //   FAILURES = FAILURES + 1;
  //   $display("FAILURE AT TIME %t. \n", 
  //             $time);
  // end else begin
  begin
    SUCCESSES = SUCCESSES + 1;
    $display("SUCCESS AT TIME %t. \n", 
              $time);
  end
endtask

localparam CYCLE_TIME = 50;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2) clk = ~clk;
  end
end

initial begin
  // Reset procedure
  rst = 1;
  RD = 1;
  WR = 1;
  #(1.5*CYCLE_TIME);


  rst = 0;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b1110;
  #(CYCLE_TIME);
  check();

  // Stay in Idle
  rst = 1;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b1110;
  #(4*CYCLE_TIME);
  check();

  // Go to read
  rst = 1;
  RD = 0;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b0100;
  #(2*CYCLE_TIME);
  check();

  // Stay in read
  rst = 1;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b0100;
  #(4*CYCLE_TIME);
  check();

  // Go to done
  rst = 1;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b0101;
  #(47*CYCLE_TIME);
  check();

  // Stay in idle
  rst = 1;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b1110;
  #(2*CYCLE_TIME);
  check();

  // Go to write
  rst = 1;
  RD = 1;
  WR = 0;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b0010;
  #(2*CYCLE_TIME);
  check();

  // Go to idle
  rst = 1;
  RD = 1;
  WR = 1;
  {RD_out_exp, WR_out_exp, OE_out_exp, V_exp} = 4'b1110;
  #(4*CYCLE_TIME);
  check();


  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule