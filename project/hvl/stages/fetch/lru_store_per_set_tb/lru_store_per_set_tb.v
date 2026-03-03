module lru_store_per_set_tb;

initial begin
  $vcdplusfile("lru_store_per_set_tb.dump.vpd");
  $vcdpluson(0, lru_store_per_set_tb);
end

localparam CYCLE_TIME = 10.0;

reg clk, rst, T1, T0;
wire V1, V0;
wire V1_exp, V0_exp;

lru_store_per_set DUT (
  .clk(clk),
  .rst(rst),
  .T1(T1),
  .T0(T0),
  .V1(V1),
  .V0(V0)
);

lru_store_per_set_behav REF (
  .clk(clk),
  .rst(rst),
  .T1(T1),
  .T0(T0),
  .V1(V1_exp),
  .V0(V0_exp)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

task check;
begin
  if ({V1, V0} !== {V1_exp, V0_exp}) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  Inputs T1,T0 = %b%b", T1, T0);
    $display("  EXP = %b%b", V1_exp, V0_exp);
    $display("  GOT = %b%b\n", V1, V0);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

always #(CYCLE_TIME/2.0) clk = ~clk;

integer i, j, k;

initial begin
  clk = 0;
  rst = 1;
  T1 = 0;
  T0 = 0;

  #(CYCLE_TIME);
  rst = 0;
  #(CYCLE_TIME);
  rst = 1;
  #(CYCLE_TIME);

  for (i = 0; i < 4; i = i + 1) begin
    for (j = 0; j < 4; j = j + 1) begin
      {T1, T0} = i[1:0];
      #(CYCLE_TIME);
      check();
      {T1, T0} = j[1:0];
      #(CYCLE_TIME);
      check();
    end
  end

  for (i = 0; i < 4; i = i + 1) begin
    for (j = 0; j < 4; j = j + 1) begin
      for (k = 0; k < 4; k = k + 1) begin
        {T1, T0} = i[1:0];
        #(CYCLE_TIME);
        check();
        {T1, T0} = j[1:0];
        #(CYCLE_TIME);
        check();
        {T1, T0} = k[1:0];
        #(CYCLE_TIME);
        check();
      end
    end
  end

  for (i = 0; i < 1 << 13; i = i + 1) begin
    {T1, T0} = $random % 4;
    #(CYCLE_TIME);
    check();
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule