module iq_de_to_rr_tb;

initial begin
  // $vcdplusfile("iq_de_to_rr_tb.dump.vpd");
  // $vcdpluson(0, iq_de_to_rr_tb);
  // $vcdpluson(0, iq_de_to_rr_tb.DUT);
  // $vcdpluson(0, iq_de_to_rr_tb.REF);
end

localparam ENTRY_BIT_WIDTH = 221;
localparam VALID_BIT       = 122;
localparam NUM_ENTRIES     = 4;
localparam PTR_WIDTH       = $clog2(NUM_ENTRIES);
localparam COUNT_WIDTH     = PTR_WIDTH + 1;
localparam CYCLE_TIME      = 10.0;

reg                         clk;
reg                         rst_n;
reg                         wr;
reg                         rd;
reg                         flush;
reg  [ENTRY_BIT_WIDTH-1:0]  data_in;

wire                        DUT_empty;
wire                        DUT_full;
wire [COUNT_WIDTH-1:0]      DUT_entry_count;
wire [ENTRY_BIT_WIDTH-1:0]  DUT_data_out;
wire                        DUT_head_valid;

wire                        REF_empty;
wire                        REF_full;
wire [COUNT_WIDTH-1:0]      REF_entry_count;
wire [ENTRY_BIT_WIDTH-1:0]  REF_data_out;
wire                        REF_head_valid;

integer SUCCESSES = 0;
integer FAILURES  = 0;
integer i;
integer sw_count;

reg [ENTRY_BIT_WIDTH-1:0] entry_with_valid;
reg [ENTRY_BIT_WIDTH-1:0] entry_no_valid;

iq_de_to_rr #(
  .ENTRY_BIT_WIDTH(ENTRY_BIT_WIDTH),
  .VALID_BIT(VALID_BIT)
) DUT (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .flush(flush),
  .data_in(data_in),
  .empty(DUT_empty),
  .full(DUT_full),
  .entry_count(DUT_entry_count),
  .data_out(DUT_data_out),
  .head_valid(DUT_head_valid)
);

iq_de_to_rr_behav #(
  .ENTRY_BIT_WIDTH(ENTRY_BIT_WIDTH),
  .VALID_BIT(VALID_BIT)
) REF (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .flush(flush),
  .data_in(data_in),
  .empty(REF_empty),
  .full(REF_full),
  .entry_count(REF_entry_count),
  .data_out(REF_data_out),
  .head_valid(REF_head_valid)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

task reset_dut;
begin
  rst_n    <= 0;
  wr       <= 0;
  rd       <= 0;
  flush    <= 0;
  data_in  <= 0;
  sw_count  = 0;
  #(2 * CYCLE_TIME);
  rst_n <= 1;
  #(1.5 * CYCLE_TIME);
end
endtask

task check;
begin
  if (DUT_data_out    !== REF_data_out    ||
      DUT_empty       !== REF_empty       ||
      DUT_full        !== REF_full        ||
      DUT_entry_count !== REF_entry_count ||
      DUT_head_valid  !== REF_head_valid) begin
    $display("FAIL at time %t:", $time);
    $display("  data_out:    DUT=%h REF=%h", DUT_data_out,    REF_data_out);
    $display("  empty:       DUT=%b REF=%b", DUT_empty,       REF_empty);
    $display("  full:        DUT=%b REF=%b", DUT_full,        REF_full);
    $display("  entry_count: DUT=%0d REF=%0d", DUT_entry_count, REF_entry_count);
    $display("  head_valid:  DUT=%b REF=%b", DUT_head_valid,  REF_head_valid);
    FAILURES = FAILURES + 1;
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

task do_write;
  input [ENTRY_BIT_WIDTH-1:0] d;
begin
  data_in  <= d;
  wr       <= 1;
  sw_count  = sw_count + 1;
  #(CYCLE_TIME);
  wr       <= 0;
  data_in  <= 0;
  check();
end
endtask

task do_read;
begin
  rd       <= 1;
  sw_count  = sw_count - 1;
  #(CYCLE_TIME);
  rd       <= 0;
  check();
end
endtask

task do_flush;
begin
  flush    <= 1;
  sw_count  = 0;
  #(CYCLE_TIME);
  flush    <= 0;
  check();
end
endtask

initial begin
  reset_dut();

  /* Fill queue to full */
  repeat (NUM_ENTRIES) begin
    do_write({$random, $random, $random, $random, $random, $random, $random});
  end

  /* Drain queue */
  repeat (NUM_ENTRIES) begin
    do_read();
  end

  /* Write with valid bit set */
  entry_with_valid = 0;
  entry_with_valid[VALID_BIT] = 1'b1;
  do_write(entry_with_valid);
  do_read();

  /* Write with valid bit clear */
  entry_no_valid = 0;
  entry_no_valid[VALID_BIT] = 1'b0;
  do_write(entry_no_valid);
  do_read();

  /* Flush clears queue */
  do_write({$random, $random, $random, $random, $random, $random, $random});
  do_write({$random, $random, $random, $random, $random, $random, $random});
  do_flush();

  /* Simultaneous read and write */
  do_write({$random, $random, $random, $random, $random, $random, $random});
  data_in <= {$random, $random, $random, $random, $random, $random, $random};
  wr      <= 1;
  rd      <= 1;
  /* count stays same... */
  #(CYCLE_TIME);
  wr      <= 0;
  rd      <= 0;
  data_in <= 0;
  check();
  /* drain the remaining entry */
  do_read();

  /* Random stress test */
  reset_dut();
  begin : STRESS
    integer do_wr, do_rd, do_fl;
    for (i = 0; i < 1 << 10; i = i + 1) begin
      do_fl = (($random & 32'h7FFFFFFF) % 32 == 0);
      do_wr = ($random & 1) && (sw_count < NUM_ENTRIES) && !do_fl;
      do_rd = ($random & 1) && (sw_count > 0)           && !do_fl;

      wr      <= do_wr;
      rd      <= do_rd;
      flush   <= do_fl;
      data_in <= {$random, $random, $random, $random, $random, $random, $random};

      if (do_fl) begin
        sw_count = 0;
      end else begin
        if      (do_wr && !do_rd) sw_count = sw_count + 1;
        else if (do_rd && !do_wr) sw_count = sw_count - 1;
      end

      #(CYCLE_TIME);
      check();
      wr    <= 0;
      rd    <= 0;
      flush <= 0;
    end
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule
