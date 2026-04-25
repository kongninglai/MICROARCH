module big_or_11_tb;

initial begin
  // $vcdplusfile("big_or_11_tb.dump.vpd");
  // $vcdpluson(0, big_or_11_tb); 
end

localparam WIDTH = 11;

reg  [WIDTH-1:0] in;

wire out, out_exp;

wire depSREG = in[0];
wire depSR1  = in[1];
wire depSR2  = in[2];
wire depMMA  = in[3];
wire depMMB  = in[4];
wire depBS1  = in[5];
wire depBS2  = in[6];
wire depIDX  = in[7];
wire depA    = in[8];
wire depB    = in[9];
wire depC    = in[10];

big_or_11 DUT(
  .depSREG(depSREG),
  .depSR1(depSR1),
  .depSR2(depSR2),
  .depMMA(depMMA),
  .depMMB(depMMB),
  .depBS1(depBS1),
  .depBS2(depBS2),
  .depIDX(depIDX),
  .depA(depA),
  .depB(depB),
  .depC(depC),
  .out(out)
);

big_or_11_behav REF(
  .depSREG(depSREG),
  .depSR1(depSR1),
  .depSR2(depSR2),
  .depMMA(depMMA),
  .depMMB(depMMB),
  .depBS1(depBS1),
  .depBS2(depBS2),
  .depIDX(depIDX),
  .depA(depA),
  .depB(depB),
  .depC(depC),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %b, out = %b, in = %b\n", 
              $time, out_exp, out, in);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

integer i;

initial begin
  in = 0;
  #5;
  check(out, out_exp);

  for (i = 0; i < (1 << WIDTH); i = i + 1) begin
    in = i[10:0];
    #5;
    check(out, out_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule