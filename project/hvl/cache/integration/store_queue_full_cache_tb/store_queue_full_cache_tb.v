module store_queue_full_cache_tb;

initial begin
  $vcdplusfile("store_queue_full_cache_tb.dump.vpd");
  $vcdpluson(0, store_queue_full_cache_tb);
  $vcdpluson(0, store_queue_full_cache_tb.DUT);
end

localparam MEM_BYTE_CAPACITY    = 32768;
localparam MEM_ADDR_WIDTH       = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH       = 8;
localparam CHIP_BYTE_WIDTH      = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT       = 128;
localparam CHIP_BYTE_CAPACITY   = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam BUS_BIT_WIDTH        = 32;
localparam RANK_BIT_WIDTH       = 128;
localparam RANK_BURST_SIZE      = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK       = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam PHYS_LINE_BIT_WIDTH  = MEM_ADDR_WIDTH - RANK_BURST_SIZE;
localparam BYTES_PER_BUS        = 4;
localparam PAGE_SIZE_BYTES      = 4096;
localparam PAGE_BIT_WIDTH       = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH        = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;
localparam STOREQ_MASK_WIDTH    = RANK_BURST_SIZE * BYTES_PER_BUS;
localparam ENTRY_BIT_WIDTH      = CHIPS_PER_RANK + (MEM_ADDR_WIDTH - RANK_BURST_SIZE) + RANK_BIT_WIDTH;
localparam MULTI_WRITE_AMT      = 2;
localparam CYCLE_TIME           = 9.8;

reg clk;
reg rst_n;

reg  [MULTI_WRITE_AMT-1:0] wr;
reg  [ENTRY_BIT_WIDTH-1:0] data_in0;
reg  [ENTRY_BIT_WIDTH-1:0] data_in1;

wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [CHIPS_PER_RANK-1:0] WR_mask;

reg  [PFN_BIT_WIDTH-1:0] D_RD_TLB_PFN_OUT;
reg  [PAGE_BIT_WIDTH-1:0] MEM_PAGE_OFFSET;
reg  MEM_VALID_LOAD_INST;

wire [RANK_BIT_WIDTH-1:0] DCACHE_HIT_DATA;
wire DCACHE_HIT;
wire DCACHE_STALL;

integer FAILURES  = 0;
integer SUCCESSES = 0;

store_queue_full_cache #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY)
) DUT (
  .rst_n(rst_n),
  .clk(clk),
  .wr(wr),
  .data_in0(data_in0),
  .data_in1(data_in1),
  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),
  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

task reset_dut;
begin
  rst_n               = 0;
  wr                  = 0;
  data_in0            = 0;
  data_in1            = 0;
  D_RD_TLB_PFN_OUT    = 0;
  MEM_PAGE_OFFSET     = 0;
  MEM_VALID_LOAD_INST = 0;
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
  #(CYCLE_TIME);
  wr       = 0;
end
endtask

task check_dcache_write_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr;
begin
  if (DCACHE_HIT_DATA !== {4{{16{1'b0}}, 1'b0, addr, 4'd0}}) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, {4{{16{1'b0}}, 1'b0, addr, 4'd0}}, DCACHE_HIT_DATA);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;
integer rd_ctr = 0;

reg DCACHE_HIT_PREV;

always @(posedge clk) begin
  DCACHE_HIT_PREV <= DCACHE_HIT;
  if (DCACHE_HIT === 1'b1 && DCACHE_HIT_PREV === 1'b0 && DUT.STOREQ_STORING) begin
    check_dcache_write_data(rd_ctr[10:0]);
    if (rd_ctr == 255 || rd_ctr == 767) begin
      rd_ctr <= rd_ctr + 257;
    end else begin
      rd_ctr <= rd_ctr + 1;
    end
  end
end

initial begin
  reset_dut();

  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== DUT.full_cache_inst.KB_PFN && i[10:8] !== DUT.full_cache_inst.DMA_PFN) begin
      j = i + 1;
      if (~DCACHE_STALL) begin
        if ((($random & 32'h7FFFFFFF) % 2 == 0) || (i == 2047) || (i == 255) || (i == 767)) begin /* One write */
          write_entry({{(i << 4), (i << 4), (i << 4), (i << 4)}, i[10:0], 16'd0}, 
                      {{(j << 4), (j << 4), (j << 4), (j << 4)}, j[10:0], 16'd0},
                      2'b01);
        end else begin /* Two writes */
          write_entry({{(i << 4), (i << 4), (i << 4), (i << 4)}, i[10:0], 16'd0}, 
                      {{(j << 4), (j << 4), (j << 4), (j << 4)}, j[10:0], 16'd0},
                      2'b11);
          i = i + 1;
        end
      end else begin
        i = i - 1;
        #(CYCLE_TIME);
      end
      #(CYCLE_TIME);
    end
  end

  #(50 * CYCLE_TIME);

  for (i = 0; i < 2048; i = i + 1) begin
    MEM_VALID_LOAD_INST = 1'b1;
    if (i[10:8] !== DUT.full_cache_inst.KB_PFN && i[10:8] !== DUT.full_cache_inst.DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
      #(30 * CYCLE_TIME);
      check_dcache_write_data(i[10:0]);
    end
  end

  #(20 * CYCLE_TIME);

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule