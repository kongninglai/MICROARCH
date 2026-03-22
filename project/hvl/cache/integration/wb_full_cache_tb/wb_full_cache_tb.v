module wb_full_cache_tb;

initial begin
  $vcdplusfile("wb_full_cache_tb.dump.vpd");
  $vcdpluson(0, wb_full_cache_tb);
  $vcdpluson(0, wb_full_cache_tb.DUT);
  $vcdpluson(0, wb_full_cache_tb.DUT.store_queue_full_cache_inst.full_cache_inst.dcache_data_store.data_store_generation[0].data_position_generation[0].ram8b8w$_data_store_one_bus.mem);
end

localparam MEM_BYTE_CAPACITY    = 32768;
localparam MEM_ADDR_WIDTH       = $clog2(MEM_BYTE_CAPACITY);

localparam CHIP_BIT_WIDTH       = 8;
localparam CHIP_BYTE_WIDTH      = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT       = 128;
localparam CHIP_BYTE_CAPACITY   = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT           = MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;

localparam BUS_BIT_WIDTH        = 32;
localparam RANK_BIT_WIDTH       = 128;
localparam RANK_BURST_SIZE      = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK       = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;

localparam RANK_BYTE_CAPACITY   = CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT           = MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH       = $clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH      = MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);

localparam PHYS_LINE_BIT_WIDTH  = MEM_ADDR_WIDTH-RANK_BURST_SIZE;
localparam BYTES_PER_BUS        = 4;
localparam NUM_SETS             = 8;
localparam INDEX_WIDTH          = $clog2(NUM_SETS);
localparam NUM_WAYS             = 4;
localparam WAY_WIDTH            = $clog2(NUM_WAYS);
localparam TAG_WIDTH            = 8;

localparam PAGE_SIZE_BYTES      = 4096;
localparam PAGE_BIT_WIDTH       = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH        = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;

localparam ENTRY_BIT_WIDTH      = CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH;

localparam NUM_ENTRIES          = 4;
localparam PTR_WIDTH            = $clog2(NUM_ENTRIES);
localparam COUNT_WIDTH          = PTR_WIDTH+1;
localparam MULTI_WRITE_AMT      = 2;

localparam STORE_DATA_BIT_WIDTH = 64;
localparam TWO_LINES_BIT_WIDTH  = 2*RANK_BIT_WIDTH;
localparam TWO_LINES_NUM_BYTES  = TWO_LINES_BIT_WIDTH/8;
localparam TWO_LINES_SHF_AMT_BIT_WIDTH = $clog2(TWO_LINES_NUM_BYTES);

localparam CYCLE_TIME_X10       = 98;
localparam TRUE_LRU             = 1;
localparam CYCLE_TIME           = CYCLE_TIME_X10 / 10.0;

reg clk;
reg rst_n;

reg  [STORE_DATA_BIT_WIDTH-1:0] to_wb_store_data;
reg                             to_wb_store_is_io_line_0;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] to_wb_store_addr_line_0;
reg  [CHIPS_PER_RANK-1:0]               to_wb_store_mask_line_0;
reg                                     to_wb_store_queue_alloc_line_0;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] to_wb_store_addr_line_1;
reg  [CHIPS_PER_RANK-1:0]               to_wb_store_mask_line_1;
reg                                     to_wb_store_queue_alloc_line_1;

reg  [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] to_wb_store_data_shf_amt;
reg  [1:0]  to_wb_exception;
reg         to_wb_valid;

wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [CHIPS_PER_RANK-1:0] WR_mask;

reg  [PFN_BIT_WIDTH-1:0] D_RD_TLB_PFN_OUT;
reg  [PAGE_BIT_WIDTH-1:0] MEM_PAGE_OFFSET;
reg  MEM_VALID_LOAD_INST;

wire [RANK_BIT_WIDTH-1:0] DCACHE_HIT_DATA;
wire DCACHE_HIT;
wire DCACHE_STALL;

wire from_wb_valid_store_inst;
wire from_wb_flush;

integer FAILURES  = 0;
integer SUCCESSES = 0;

wb_full_cache #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10),
  .TRUE_LRU(TRUE_LRU)
) DUT (
  .clk(clk),
  .rst_n(rst_n),

  .to_wb_store_data(to_wb_store_data),
  .to_wb_store_is_io_line_0(to_wb_store_is_io_line_0),

  .to_wb_store_addr_line_0(to_wb_store_addr_line_0),
  .to_wb_store_mask_line_0(to_wb_store_mask_line_0),
  .to_wb_store_queue_alloc_line_0(to_wb_store_queue_alloc_line_0),

  .to_wb_store_addr_line_1(to_wb_store_addr_line_1),
  .to_wb_store_mask_line_1(to_wb_store_mask_line_1),
  .to_wb_store_queue_alloc_line_1(to_wb_store_queue_alloc_line_1),

  .to_wb_store_data_shf_amt(to_wb_store_data_shf_amt),
  .to_wb_exception(to_wb_exception),
  .to_wb_valid(to_wb_valid),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),

  .from_wb_valid_store_inst(from_wb_valid_store_inst),
  .from_wb_flush(from_wb_flush)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

task reset_dut;
begin
  rst_n = 0;

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
  to_wb_store_data = 0;

  to_wb_store_is_io_line_0 = 0;
  to_wb_store_data_shf_amt = 0;
  to_wb_exception = 2'b00;
  to_wb_valid = 1'b1;

  D_RD_TLB_PFN_OUT = 0;
  MEM_PAGE_OFFSET = 0;
  MEM_VALID_LOAD_INST = 0;

  #(2*CYCLE_TIME);
  rst_n = 1;
  #(1.5*CYCLE_TIME);
end
endtask

task write_entry;
  input integer addr0;
  input integer addr1;
  input [1:0]  mode;
begin
  to_wb_store_data = {(addr0 << 4), (addr0 << 4)};

  to_wb_store_addr_line_0 = addr0;
  to_wb_store_mask_line_0 = 16'hFF00;
  to_wb_store_queue_alloc_line_0 = mode[0];

  to_wb_store_addr_line_1 = addr1;
  to_wb_store_mask_line_1 = 16'hFF00;
  to_wb_store_queue_alloc_line_1 = mode[1];

  #(CYCLE_TIME);

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
end
endtask

task write_entry_custom;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr0;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr1;
  input [CHIPS_PER_RANK-1:0]  mask0;
  input [CHIPS_PER_RANK-1:0]  mask1;
  input [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] shf_amt;
  input [1:0]  mode;
  input [STORE_DATA_BIT_WIDTH-1:0] data;
begin
  to_wb_store_data = data;

  to_wb_store_addr_line_0 = addr0;
  to_wb_store_mask_line_0 = mask0;
  to_wb_store_queue_alloc_line_0 = mode[0];

  to_wb_store_addr_line_1 = addr1;
  to_wb_store_mask_line_1 = mask1;
  to_wb_store_queue_alloc_line_1 = mode[1];

  to_wb_store_data_shf_amt = shf_amt;

  #(CYCLE_TIME);

  to_wb_store_queue_alloc_line_0 = 0;
  to_wb_store_queue_alloc_line_1 = 0;
  to_wb_store_data_shf_amt = 0;
end
endtask

task check_dcache_write_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] addr;
begin
  if (DCACHE_HIT_DATA !== {{64{1'bX}}, {2{{16{1'b0}}, 1'b0, addr, 4'd0}}}) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, {{64{1'bX}}, {2{{16{1'b0}}, 1'b0, addr, 4'd0}}}, DCACHE_HIT_DATA);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

task check_dcache_write_data_custom;
  input [RANK_BIT_WIDTH-1:0] data;
begin
  if (DCACHE_HIT_DATA !== data) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, data, DCACHE_HIT_DATA);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;

initial begin
  reset_dut();

  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== DUT.store_queue_full_cache_inst.full_cache_inst.KB_PFN && 
        i[10:8] !== DUT.store_queue_full_cache_inst.full_cache_inst.DMA_PFN) begin
      j = i + 1;

      if (~DCACHE_STALL) begin
        write_entry(i, j, 2'b01);
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
    if (i[10:8] !== DUT.store_queue_full_cache_inst.full_cache_inst.KB_PFN && 
        i[10:8] !== DUT.store_queue_full_cache_inst.full_cache_inst.DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
      #(30 * CYCLE_TIME);
      check_dcache_write_data(i[10:0]);
    end
  end

  #(20 * CYCLE_TIME);
  MEM_VALID_LOAD_INST = 1'b0;

  // write_entry_custom(addr0, addr1, mask0, mask1, shf_amt, mode, data);

  write_entry_custom(11'd0, 11'd1, 16'h01FF, 16'hFFFE, 5'd9, 2'b11, 64'h6767676767676767);

  #(50 * CYCLE_TIME);

  for (i = 0; i < 2; i = i + 1) begin
    MEM_VALID_LOAD_INST = 1'b1;
    {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
    #(30 * CYCLE_TIME);
    if (i == 0) begin
      check_dcache_write_data_custom(128'h67676767676767XX0000000000000000);
    end else begin
      check_dcache_write_data_custom(128'hXXXXXXXXXXXXXXXX0000001000000067);
    end
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule