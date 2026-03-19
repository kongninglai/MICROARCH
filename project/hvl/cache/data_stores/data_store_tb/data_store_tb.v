module data_store_tb;

initial begin
  $vcdplusfile("data_store_tb.dump.vpd");
  $vcdpluson(0, data_store_tb);
end

localparam RANK_BIT_WIDTH     = 128;
localparam BUS_BIT_WIDTH      = 32;
localparam CHIP_BIT_WIDTH     = 8;
localparam RANK_BURST_SIZE    = 4;
localparam BYTES_PER_BUS      = 4;
localparam NUM_SETS           = 8;
localparam INDEX_WIDTH        = $clog2(NUM_SETS);
localparam NUM_WAYS           = 4;
localparam NUM_BYTES_PER_RANK = RANK_BURST_SIZE * BYTES_PER_BUS;
localparam CYCLE_TIME         = 2.5;

reg  [INDEX_WIDTH-1:0]                            set_index;
reg  [NUM_WAYS*NUM_BYTES_PER_RANK-1:0]           wr_en_bar_one_hot;
reg  [RANK_BIT_WIDTH-1:0]                         data_in;

wire [NUM_WAYS*RANK_BIT_WIDTH-1:0]               data_out;
wire [NUM_WAYS*RANK_BIT_WIDTH-1:0]               data_out_exp;

data_store #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .CHIP_BIT_WIDTH(CHIP_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .BYTES_PER_BUS(BYTES_PER_BUS),
  .NUM_SETS(NUM_SETS),
  .NUM_WAYS(NUM_WAYS)
) DUT (
  .set_index(set_index),
  .wr_en_bar_one_hot(wr_en_bar_one_hot),
  .data_in(data_in),
  .data_out(data_out)
);

data_store_behav #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .CHIP_BIT_WIDTH(CHIP_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .BYTES_PER_BUS(BYTES_PER_BUS),
  .NUM_SETS(NUM_SETS),
  .NUM_WAYS(NUM_WAYS)
) REF (
  .set_index(set_index),
  .wr_en_bar_one_hot(wr_en_bar_one_hot),
  .data_in(data_in),
  .data_out(data_out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if (data_out !== data_out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  set_index = %0d", set_index);
    $display("  wr_en_bar_one_hot = %b", wr_en_bar_one_hot);
    $display("  data_in = %h", data_in);
    $display("  EXP = %h", data_out_exp);
    $display("  GOT = %h\n", data_out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j, k;
integer t;

initial begin
  set_index = 0;
  wr_en_bar_one_hot = {NUM_WAYS*NUM_BYTES_PER_RANK{1'b1}};
  data_in = 0;
  #(CYCLE_TIME);

  for (i = 0; i < NUM_SETS; i = i + 1) begin
    set_index = i[INDEX_WIDTH-1:0];
    data_in = {$random, $random, $random, $random};
    wr_en_bar_one_hot = {NUM_WAYS*NUM_BYTES_PER_RANK{1'b1}};
    #(CYCLE_TIME);

    for (j = 0; j < NUM_WAYS; j = j + 1) begin
      for (k = 0; k < NUM_BYTES_PER_RANK; k = k + 1)
        wr_en_bar_one_hot[j*NUM_BYTES_PER_RANK + k] = 1'b0;
      #(CYCLE_TIME);
    end

    wr_en_bar_one_hot = {NUM_WAYS*NUM_BYTES_PER_RANK{1'b1}};
    #(CYCLE_TIME);

    check();
  end

  for (t = 0; t < 1024; t = t + 1) begin
    set_index = $random % NUM_SETS;
    data_in = {$random, $random, $random, $random};
    wr_en_bar_one_hot = {NUM_WAYS*NUM_BYTES_PER_RANK{1'b1}};

    #(CYCLE_TIME);

    for (j = 0; j < NUM_WAYS; j = j + 1) begin
      for (k = 0; k < NUM_BYTES_PER_RANK; k = k + 1) begin
        if ($random % 2 == 0)
          wr_en_bar_one_hot[j*NUM_BYTES_PER_RANK + k] = 1'b0;
      end
    end

    #(CYCLE_TIME);
    wr_en_bar_one_hot = {NUM_WAYS*NUM_BYTES_PER_RANK{1'b1}};
    #(CYCLE_TIME);

    check();
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule