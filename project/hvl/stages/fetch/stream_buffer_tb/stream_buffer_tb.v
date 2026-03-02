module stream_buffer_tb;

initial begin
  $vcdplusfile("stream_buffer_tb.dump.vpd");
  $vcdpluson(0, stream_buffer_tb);
end

localparam RANK_BIT_WIDTH  = 128;
localparam BUS_BIT_WIDTH   = 32;
localparam RANK_BURST_SIZE = 4;
localparam MEM_ADDR_WIDTH  = 15;
localparam CYCLE_TIME      = 10;

reg clk, rst;

reg [RANK_BURST_SIZE-1:0] stream_buffer_wr_mask;
reg icache_controller_set_valid;

reg [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] icache_addr;
reg [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] icache_controller_next_line_addr;

reg [RANK_BIT_WIDTH-1:0] DATA_BUS_SHF;

wire stream_buffer_hit, stream_buffer_miss;
wire [RANK_BIT_WIDTH-1:0] stream_buffer_data;

wire stream_buffer_hit_exp, stream_buffer_miss_exp;
wire [RANK_BIT_WIDTH-1:0] stream_buffer_data_exp;

stream_buffer #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
) DUT (
  .clk(clk),
  .rst(rst),
  .stream_buffer_wr_mask(stream_buffer_wr_mask),
  .icache_addr(icache_addr),
  .icache_controller_next_line_addr(icache_controller_next_line_addr),
  .DATA_BUS_SHF(DATA_BUS_SHF),
  .icache_controller_set_valid(icache_controller_set_valid),
  .stream_buffer_hit(stream_buffer_hit),
  .stream_buffer_miss(stream_buffer_miss),
  .stream_buffer_data(stream_buffer_data)
);

stream_buffer_behav #(
  .RANK_BIT_WIDTH(RANK_BIT_WIDTH),
  .BUS_BIT_WIDTH(BUS_BIT_WIDTH),
  .RANK_BURST_SIZE(RANK_BURST_SIZE),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
) REF (
  .clk(clk),
  .rst(rst),
  .stream_buffer_wr_mask(stream_buffer_wr_mask),
  .icache_addr(icache_addr),
  .icache_controller_next_line_addr(icache_controller_next_line_addr),
  .DATA_BUS_SHF(DATA_BUS_SHF),
  .icache_controller_set_valid(icache_controller_set_valid),
  .stream_buffer_hit(stream_buffer_hit_exp),
  .stream_buffer_miss(stream_buffer_miss_exp),
  .stream_buffer_data(stream_buffer_data_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if (stream_buffer_hit      !== stream_buffer_hit_exp  ||
      stream_buffer_miss     !== stream_buffer_miss_exp ||
      stream_buffer_data     !== stream_buffer_data_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  HIT  : exp=%b  got=%b",  stream_buffer_hit_exp,  stream_buffer_hit);
    $display("  MISS : exp=%b  got=%b",  stream_buffer_miss_exp, stream_buffer_miss);
    $display("  DATA : exp=%h", stream_buffer_data_exp);
    $display("         got=%h\n", stream_buffer_data);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

always #(CYCLE_TIME/2.0) clk = ~clk;

reg [RANK_BURST_SIZE:0] combo;
reg [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] saved_addr;

integer i;

initial begin
  clk = 0;
  rst = 1'b1;

  stream_buffer_wr_mask = 0;
  icache_controller_set_valid = 0;
  icache_addr = 0;
  icache_controller_next_line_addr = 0;
  DATA_BUS_SHF = 0;

  #(CYCLE_TIME);
  rst <= 1'b0;
  #(CYCLE_TIME);
  rst <= 1'b1;
  #(0.5*CYCLE_TIME);
  #(CYCLE_TIME);

  combo = 0;

  for (i = 0; i < (1 << (RANK_BURST_SIZE+1)); i = i + 1) begin
    stream_buffer_wr_mask = combo[RANK_BURST_SIZE-1:0];
    icache_controller_set_valid = combo[RANK_BURST_SIZE];
    DATA_BUS_SHF = {$random,$random,$random,$random};
    icache_controller_next_line_addr = $random;
    icache_addr = $random;
    @(posedge clk);
    check();
    combo = combo + 1;
  end
  
  saved_addr = $random;

  @(posedge clk);
  stream_buffer_wr_mask = {RANK_BURST_SIZE{1'b1}};
  icache_controller_set_valid = 1'b1;
  icache_controller_next_line_addr = saved_addr;
  icache_addr = $random;
  DATA_BUS_SHF = {$random,$random,$random,$random};
  @(posedge clk);
  check();

  @(posedge clk);
  stream_buffer_wr_mask = 0;
  icache_controller_set_valid = 1'b0;
  icache_addr = saved_addr;
  DATA_BUS_SHF = {$random,$random,$random,$random};
  @(posedge clk);
  check();

  repeat (1 << 12) begin
    @(posedge clk);
    stream_buffer_wr_mask = $random;
    icache_controller_set_valid = $random;
    icache_controller_next_line_addr = $random;
    icache_addr = $random;
    DATA_BUS_SHF = {$random,$random,$random,$random};
    @(posedge clk);
    check();
  end
  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule