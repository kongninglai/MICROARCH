module bit_duplicator_tb;

initial begin
  $vcdplusfile("bit_duplicator_tb.dump.vpd");
  $vcdpluson(0, bit_duplicator_tb);
end

localparam IN_WIDTH  = 16;
localparam MULTIPLIER = 4;
localparam OUT_WIDTH = IN_WIDTH * MULTIPLIER;

reg  [IN_WIDTH-1:0]  in;
wire [OUT_WIDTH-1:0] out, out_exp;

bit_duplicator DUT(
  .in(in),
  .out(out)
);

bit_duplicator_behav REF(
  .in(in),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t in=%h out=%h out_exp=%h\n",
              $time, in, out, out_exp);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i;

initial begin
  in = 0;
  repeat (1 << IN_WIDTH) begin
    #5;
    check();
    in = in + 1;
  end

  repeat (1 << 10) begin
    in = $random;
    #5;
    check();
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule