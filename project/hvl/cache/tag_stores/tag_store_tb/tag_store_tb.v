module tag_store_tb;

initial begin
  // $vcdplusfile("tag_store_tb.dump.vpd");
  // $vcdpluson(0, tag_store_tb);
end

localparam NUM_SETS     = 8;
localparam INDEX_WIDTH  = $clog2(NUM_SETS);
localparam NUM_WAYS     = 4;
localparam TAG_WIDTH    = 8;
localparam CYCLE_TIME   = 2.5;

reg  [INDEX_WIDTH-1:0]        set_index;
reg  [NUM_WAYS-1:0]           wr_en_bar_one_hot;
reg  [TAG_WIDTH-1:0]          tag_in;

wire [NUM_WAYS*TAG_WIDTH-1:0] tag_out;
wire [NUM_WAYS*TAG_WIDTH-1:0] tag_out_exp;

tag_store #(
  .NUM_SETS(NUM_SETS),
  .INDEX_WIDTH(INDEX_WIDTH),
  .NUM_WAYS(NUM_WAYS),
  .TAG_WIDTH(TAG_WIDTH)
) DUT (
  .set_index(set_index),
  .wr_en_bar_one_hot(wr_en_bar_one_hot),
  .tag_in(tag_in),
  .tag_out(tag_out)
);

tag_store_behav #(
  .NUM_SETS(NUM_SETS),
  .INDEX_WIDTH(INDEX_WIDTH),
  .NUM_WAYS(NUM_WAYS),
  .TAG_WIDTH(TAG_WIDTH)
) REF (
  .set_index(set_index),
  .wr_en_bar_one_hot(wr_en_bar_one_hot),
  .tag_in(tag_in),
  .tag_out(tag_out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if (tag_out !== tag_out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  set_index = %0d", set_index);
    $display("  wr_en_bar_one_hot = %b", wr_en_bar_one_hot);
    $display("  tag_in = %h", tag_in);
    $display("  EXP = %h", tag_out_exp);
    $display("  GOT = %h\n", tag_out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;
integer rand_way;
reg [NUM_WAYS-1:0] one_hot_mask;

initial begin
  set_index = 0;
  wr_en_bar_one_hot = {NUM_WAYS{1'b1}};
  tag_in = 0;

  #(CYCLE_TIME);

  for (i = 0; i < NUM_SETS; i = i + 1) begin
    for (j = 0; j < NUM_WAYS; j = j + 1) begin
      set_index = i[INDEX_WIDTH-1:0];
      tag_in = $random;
      wr_en_bar_one_hot = {NUM_WAYS{1'b1}};
      #(CYCLE_TIME);

      wr_en_bar_one_hot[j] = 1'b0;
      #(CYCLE_TIME);

      wr_en_bar_one_hot = {NUM_WAYS{1'b1}};
      #(CYCLE_TIME);

      check();
    end
  end

  for (i = 0; i < (1 << (NUM_WAYS + INDEX_WIDTH)); i = i + 1) begin
      set_index = $random;
      tag_in = $random;
      wr_en_bar_one_hot = {NUM_WAYS{1'b1}};
      #(CYCLE_TIME);

      rand_way = $random % NUM_WAYS;
      if (rand_way < 0) rand_way = -rand_way;
      one_hot_mask = (1 << rand_way);

      wr_en_bar_one_hot = ~one_hot_mask;
      #(CYCLE_TIME);

      wr_en_bar_one_hot = {NUM_WAYS{1'b1}};
      #(CYCLE_TIME);

      check();
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule