module valid_or_dirty_store_tb;

initial begin
  $vcdplusfile("valid_or_dirty_store_tb.dump.vpd");
  $vcdpluson(0, valid_or_dirty_store_tb);
end

localparam NUM_SETS     = 8;
localparam INDEX_WIDTH  = $clog2(NUM_SETS);
localparam NUM_WAYS     = 4;
localparam WAY_WIDTH    = $clog2(NUM_WAYS);
localparam CYCLE_TIME   = 10.0;

reg clk, rst;
reg [INDEX_WIDTH-1:0] set_index;
reg set_or_clr;
reg [INDEX_WIDTH+WAY_WIDTH-1:0] wr_en;
reg wr_en_global;

wire [NUM_WAYS-1:0] out;
wire [NUM_WAYS-1:0] out_exp;

valid_or_dirty_store #(
  .NUM_SETS(NUM_SETS),
  .INDEX_WIDTH(INDEX_WIDTH),
  .NUM_WAYS(NUM_WAYS),
  .WAY_WIDTH(WAY_WIDTH)
) DUT (
  .clk(clk),
  .rst(rst),
  .set_index(set_index),
  .set_or_clr(set_or_clr),
  .wr_en(wr_en),
  .wr_en_global(wr_en_global),
  .out(out)
);

valid_or_dirty_store_behav #(
  .NUM_SETS(NUM_SETS),
  .INDEX_WIDTH(INDEX_WIDTH),
  .NUM_WAYS(NUM_WAYS),
  .WAY_WIDTH(WAY_WIDTH)
) REF (
  .clk(clk),
  .rst(rst),
  .set_index(set_index),
  .set_or_clr(set_or_clr),
  .wr_en(wr_en),
  .wr_en_global(wr_en_global),
  .out(out_exp)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

task check;
begin
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  set_index = %0d", set_index);
    $display("  wr_en = %b", wr_en);
    $display("  wr_en_global = %b", wr_en_global);
    $display("  set_or_clr = %b", set_or_clr);
    $display("  EXP = %b", out_exp);
    $display("  GOT = %b\n", out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

always #(CYCLE_TIME/2.0) clk = ~clk;

integer i, j;
reg [NUM_WAYS-1:0] one_hot_mask;
integer rand_way, rand_set;

initial begin
  clk = 0;
  rst = 1;
  set_index = 0;
  set_or_clr = 0;
  wr_en = 0;
  wr_en_global = 0;

  #(CYCLE_TIME);
  rst = 0;
  #(CYCLE_TIME);
  rst = 1;
  #(CYCLE_TIME);

  for (i = 0; i < NUM_SETS; i = i + 1) begin
    for (j = 0; j < NUM_WAYS; j = j + 1) begin
      set_index = i;
      set_or_clr = $random % 2;
      wr_en[INDEX_WIDTH+WAY_WIDTH-1:WAY_WIDTH] = i;
      wr_en[WAY_WIDTH-1:0] = j;
      wr_en_global = 1;
      #(CYCLE_TIME);
      wr_en_global = 0;
      #(CYCLE_TIME);
      check();
    end
  end

  for (i = 0; i < 1 << 10; i = i + 1) begin
    set_index = $random % NUM_SETS;
    set_or_clr = $random % 2;
    rand_set = $random % NUM_SETS;
    rand_way = $random % NUM_WAYS;
    wr_en[INDEX_WIDTH+WAY_WIDTH-1:WAY_WIDTH] = rand_set;
    wr_en[WAY_WIDTH-1:0] = rand_way;
    wr_en_global = 1;
    #(CYCLE_TIME);
    wr_en_global = 0;
    #(CYCLE_TIME);
    check();
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule