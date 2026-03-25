module sticky_bit_load_fsm_tb;

initial begin
  $vcdplusfile("sticky_bit_load_fsm_tb.dump.vpd");
  $vcdpluson(0, sticky_bit_load_fsm_tb);
end

reg  [2:0] in_long;
reg clk, rst;

wire DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP;

wire DOING_LINE_1_LOAD_DUMMY = in_long[0];
wire LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR = in_long[1];
wire FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR = in_long[2];

sticky_bit_load_fsm DUT(
  .rst(rst),
  .clk(clk),
  .LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR(LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR),
  .FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR(FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR),
  .DOING_LINE_1_LOAD(DOING_LINE_1_LOAD)
);

sticky_bit_load_fsm_behav REF(
  .rst(rst),
  .clk(clk),
  .LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR(LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR),
  .FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR(FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR),
  .DOING_LINE_1_LOAD(DOING_LINE_1_LOAD_EXP)
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

localparam CYCLE_TIME = 9.8;

initial begin
  clk = 0;
  forever #(CYCLE_TIME / 2.0) clk = ~clk;
end


initial begin
  rst = 0;
  in_long = 0;

  #(1.5 * CYCLE_TIME);
  rst = 1;

  in_long[1] <= 0; in_long[2] <= 0;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 1; in_long[2] <= 0;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 0; in_long[2] <= 1;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 0; in_long[2] <= 0;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 0; in_long[2] <= 1;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 1; in_long[2] <= 0;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 1; in_long[2] <= 0;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  in_long[1] <= 1; in_long[2] <= 1;
  #(CYCLE_TIME); check(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_EXP);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule