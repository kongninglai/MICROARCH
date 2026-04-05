module store_queue_entry_tb;

initial begin
  // $vcdplusfile("store_queue_entry_tb.dump.vpd");
  // $vcdpluson(0, store_queue_entry_tb);
end

localparam MEM_BYTE_CAPACITY    = 32768;
localparam MEM_ADDR_WIDTH       = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH       = 8;
localparam BUS_BIT_WIDTH        = 32;
localparam RANK_BIT_WIDTH       = 128;
localparam RANK_BURST_SIZE      = RANK_BIT_WIDTH / BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK       = RANK_BIT_WIDTH / CHIP_BIT_WIDTH;
localparam PHYS_LINE_BIT_WIDTH  = MEM_ADDR_WIDTH - RANK_BURST_SIZE;
localparam ENTRY_BIT_WIDTH      = CHIPS_PER_RANK + PHYS_LINE_BIT_WIDTH + RANK_BIT_WIDTH;
localparam CYCLE_TIME           = 9.8;

reg                        clk;
reg                        rst_n;
reg                        wr;
reg                        rd;
reg  [ENTRY_BIT_WIDTH-1:0] data_in;

wire [ENTRY_BIT_WIDTH-1:0] data_out;
wire [ENTRY_BIT_WIDTH-1:0] data_out_exp;
wire                       pending;
wire                       pending_exp;

store_queue_entry #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)
) DUT (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .data_in(data_in),
  .data_out(data_out),
  .pending(pending)
);

store_queue_entry_behav #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)
) REF (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .data_in(data_in),
  .data_out(data_out_exp),
  .pending(pending_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if (data_out !== data_out_exp || pending !== pending_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  data_in      = %h", data_in);
    $display("  data_out EXP = %h", data_out_exp);
    $display("  data_out GOT = %h", data_out);
    $display("  pending EXP  = %b", pending_exp);
    $display("  pending GOT  = %b\n", pending);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer t;
integer i;

initial begin
  clk = 0;
  forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

initial begin
  rst_n <= 0;
  wr <= 0;
  rd <= 0;
  data_in <= 0;
  #(CYCLE_TIME);
  rst_n <= 1;
  #(1.5 * CYCLE_TIME);

  for (i = 0; i < 16; i = i + 1) begin
    data_in <= {$random, $random, $random, $random, $random}[ENTRY_BIT_WIDTH-1:0];
    wr <= 1;
    rd <= 0;
    #(CYCLE_TIME);
    wr <= 0;
    rd <= 0;
    #(CYCLE_TIME);
    check();
  end

  for (t = 0; t < 1 << 12; t = t + 1) begin
    data_in <= {$random, $random, $random, $random, $random}[ENTRY_BIT_WIDTH-1:0];
    wr <= $random % 2;
    rd <= $random % 2;
    #(CYCLE_TIME);
    wr <= 0;
    rd <= 0;
    #(CYCLE_TIME);
    check();
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule