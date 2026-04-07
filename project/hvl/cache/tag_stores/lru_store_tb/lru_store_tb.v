module lru_store_tb;

initial begin
  // $vcdplusfile("lru_store_tb.dump.vpd");
  // $vcdpluson(0, lru_store_tb);
end

localparam NUM_SETS = 8;
localparam INDEX_WIDTH = $clog2(NUM_SETS);
localparam NUM_WAYS = 4;
localparam WAY_WIDTH = $clog2(NUM_WAYS);
localparam TAG_WIDTH = 8;
localparam RANK_BURST_SIZE = 4;
localparam MEM_ADDR_WIDTH = 15;

localparam IN_WIDTH = 7;
localparam CYCLE_TIME = 10.0;

reg  [IN_WIDTH-1:0] in;
reg  clk, rst;

wire [WAY_WIDTH-1:0] TAG_HIT_WAY = in[1:0];
wire CACHE_HIT = in[2];
wire CC_STREAM_BUF_HIT = in[3];

wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] CC_ADDR_OUT;
assign CC_ADDR_OUT = { {(MEM_ADDR_WIDTH-RANK_BURST_SIZE-3){1'b0}}, in[6:4] };

wire [WAY_WIDTH-1:0] VICT_WAY, VICT_WAY_EXP;

localparam TRUE_LRU = 1;

lru_store #(.TRUE_LRU(TRUE_LRU)) DUT(
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(TAG_HIT_WAY),
  .CACHE_HIT(CACHE_HIT),
  .CC_ADDR_OUT(CC_ADDR_OUT),
  .CC_STREAM_BUF_HIT(CC_STREAM_BUF_HIT),
  .VICT_WAY(VICT_WAY)
);

lru_store_behav #(.TRUE_LRU(TRUE_LRU)) REF(
  .rst(rst),
  .clk(clk),
  .TAG_HIT_WAY(TAG_HIT_WAY),
  .CACHE_HIT(CACHE_HIT),
  .CC_ADDR_OUT(CC_ADDR_OUT),
  .CC_STREAM_BUF_HIT(CC_STREAM_BUF_HIT),
  .VICT_WAY(VICT_WAY_EXP)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WAY_WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h",
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask


initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end


initial begin
  rst = 0;
  in <= 0;

  #(1.5 * CYCLE_TIME);
  rst = 1;
  #(CYCLE_TIME);

  // Exhaustive over packed inputs
  repeat (1 << IN_WIDTH) begin
    #(CYCLE_TIME);
    check(VICT_WAY, VICT_WAY_EXP);
    in <= in + 1;
  end

  // Random stress
  repeat (1 << 10) begin
    #(CYCLE_TIME);
    check(VICT_WAY, VICT_WAY_EXP);
    in <= $random;
  end

  #(CYCLE_TIME);
  in <= 0;

  repeat (1 << IN_WIDTH) begin
    #(CYCLE_TIME);
    check(VICT_WAY, VICT_WAY_EXP);
    in <= in + 1;
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule