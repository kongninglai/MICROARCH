module store_queue_tb;

initial begin
  $vcdplusfile("store_queue_tb.dump.vpd");
  $vcdpluson(0, store_queue_tb);
  $vcdpluson(0, store_queue_tb.DUT);
end

localparam MEM_BYTE_CAPACITY = 32768;
localparam MEM_ADDR_WIDTH    = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH    = 8;
localparam BUS_BIT_WIDTH     = 32;
localparam RANK_BIT_WIDTH    = 128;
localparam RANK_BURST_SIZE   = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK    = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam ENTRY_BIT_WIDTH   = CHIPS_PER_RANK + (MEM_ADDR_WIDTH-RANK_BURST_SIZE) + RANK_BIT_WIDTH;
localparam NUM_ENTRIES       = 4;
localparam MULTI_WRITE_AMT   = 2;
localparam PTR_WIDTH         = $clog2(NUM_ENTRIES);
localparam COUNT_WIDTH       = PTR_WIDTH+1;
localparam CYCLE_TIME        = 9.8;

reg clk;
reg rst_n;
reg [MULTI_WRITE_AMT-1:0] wr;
reg rd;
reg [ENTRY_BIT_WIDTH-1:0] data_in0;
reg [ENTRY_BIT_WIDTH-1:0] data_in1;

wire empty;
wire full;
wire [RANK_BIT_WIDTH-1:0] STOREQ_DATA;
wire [RANK_BURST_SIZE*4-1:0] STOREQ_DATA_WR_MASK;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] STOREQ_PHYS_ADDR;

integer SUCCESSES = 0;
integer FAILURES  = 0;
integer i;

store_queue #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)
) DUT (
  .clk(clk),
  .rst_n(rst_n),
  .wr(wr),
  .rd(rd),
  .data_in0(data_in0),
  .data_in1(data_in1),
  .empty(empty),
  .full(full),
  .entry_count(),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME / 2.0) clk = ~clk;
end

task reset_dut;
begin
  rst_n = 0;
  wr    = 0;
  rd    = 0;
  data_in0 = 0;
  data_in1 = 0;
  #(2*CYCLE_TIME);
  rst_n = 1;
  #(1.5*CYCLE_TIME);
end
endtask

task write_entry;
  input [ENTRY_BIT_WIDTH-1:0] d0;
  input [ENTRY_BIT_WIDTH-1:0] d1;
  input [MULTI_WRITE_AMT-1:0] w_mask;
begin
  data_in0 = d0;
  data_in1 = d1;
  wr       = w_mask;
  #(CYCLE_TIME / 2.0);
  wr       = 0;
end
endtask

task check_data;
  input [ENTRY_BIT_WIDTH-1:0] expected;
begin
  if ({STOREQ_DATA, STOREQ_PHYS_ADDR, STOREQ_DATA_WR_MASK} !== expected) begin
    $display("FAIL at time %t: Expected %h, got %h", $time, expected, {STOREQ_DATA, STOREQ_PHYS_ADDR, STOREQ_DATA_WR_MASK});
    FAILURES = FAILURES + 1;
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;
integer rd_ctr = 0;

task read_entry;
begin
  #(CYCLE_TIME / 2.0);
  if (~empty) begin
    rd = 1;
  end
  #(CYCLE_TIME / 2.0);
  if (rd == 1) begin    
    check_data({{rd_ctr, rd_ctr, rd_ctr, rd_ctr}, rd_ctr[10:0], rd_ctr[15:0]});
    rd_ctr = rd_ctr + 1;
  end
  rd = 0;
end
endtask

initial begin
  reset_dut();

  for (i = 0; i < 2048; i = i + 1) begin
    j = i + 1;

    #(CYCLE_TIME / 2.0);
    if (~full) begin
      if (($random & 32'h7FFFFFFF) % 2 == 0) begin /* One write */
        write_entry({{i, i, i, i}, i[10:0], i[15:0]}, 
                    {{j, j, j, j}, j[10:0], j[15:0]},
                    2'b01);
      end else begin /* Two writes */
        write_entry({{i, i, i, i}, i[10:0], i[15:0]}, 
                    {{j, j, j, j}, j[10:0], j[15:0]},
                    2'b11);
        i = i + 1;
      end
    end else begin
      i = i - 1;
      #(CYCLE_TIME / 2.0);
    end

    repeat (($random & 32'h7FFFFFFF) % 4) begin
      read_entry();
    end
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule