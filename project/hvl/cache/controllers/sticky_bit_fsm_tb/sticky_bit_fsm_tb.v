module sticky_bit_fsm_tb;

initial begin
  $vcdplusfile("sticky_bit_fsm_tb.dump.vpd");
  $vcdpluson(0, sticky_bit_fsm_tb);
end

reg  [3:0] in_long;
reg clk, rst;

wire STICKY, STICKY_EXP;

wire Q0_DUMMY = in_long[0]; // unused but keeps style consistent
wire IO_READ_AND_NOT_FLUSH = in_long[1];
wire FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ = in_long[2];
wire FILL_BUSY = in_long[3];

sticky_bit_fsm DUT(
  .rst(rst),
  .clk(clk),
  .IO_READ_AND_NOT_FLUSH(IO_READ_AND_NOT_FLUSH),
  .FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ(FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ),
  .FILL_BUSY(FILL_BUSY),
  .STICKY(STICKY)
);

sticky_bit_fsm_behav REF(
  .rst(rst),
  .clk(clk),
  .IO_READ_AND_NOT_FLUSH(IO_READ_AND_NOT_FLUSH),
  .FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ(FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ),
  .FILL_BUSY(FILL_BUSY),
  .STICKY(STICKY_EXP)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. in = %b, out_exp = %b, out = %b\n",
              $time, in_long, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask


initial begin
  clk = 0;
  forever #5 clk = ~clk;
end


initial begin
  rst = 0;
  in_long = 0;

  #12;
  rst = 1;

  repeat (1 << 4) begin
    #10;
    check(STICKY, STICKY_EXP);
    in_long = in_long + 1;
  end

  repeat (1 << 12) begin
    #10;
    check(STICKY, STICKY_EXP);
    in_long = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule