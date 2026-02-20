module reg_n_tb;

initial begin
  $vcdplusfile("reg_n_tb.dump.vpd");
  $vcdpluson(0, reg_n_tb); 
end

localparam IN_WIDTH = 1 + 1 + 8 + 8;

reg   [IN_WIDTH-1:0]  in;
wire  [7:0]           q, q_exp;

wire        clk = in[0];
wire        rst = in[1];
wire  [7:0] en  = in[9:2];
wire  [7:0] d   = in[17:10];

reg_n #(
  .WIDTH(8),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) DUT (
  .clk(clk),
  .rst(rst),
  .en(en),
  .d(d),
  .q(q)
);

reg_n_behav #(
  .WIDTH(8),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) REF (
  .clk(clk),
  .rst(rst),
  .en(en),
  .d(d),
  .q(q_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [7:0] q, q_exp;
  if (q !== q_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. q_exp = %h, q = %h\n", 
              $time, q_exp, q);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

always #5 in[0] = ~in[0];

initial begin
  in = 0;
  in[1] = 1;
  @(posedge clk);
  in[1] = 0;
  @(posedge clk);
  in[1] = 1;

  repeat (1000) begin
    @(posedge clk);
    in[9:2]  = $random;
    in[17:10]= $random;
    @(posedge clk);
    #1;
    check(q, q_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule
