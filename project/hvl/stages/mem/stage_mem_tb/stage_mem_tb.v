module stage_mem_tb;

initial begin
  $vcdplusfile("stage_mem_tb.dump.vpd");
  $vcdpluson(0, stage_mem_tb);
  $vcdpluson(0, stage_mem_tb.DUT);
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

localparam PAGE_SIZE_BYTES      = 4096;
localparam PAGE_BIT_WIDTH       = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH        = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;
localparam VPN_BIT_WIDTH        = 32 - PAGE_BIT_WIDTH;

localparam STORE_DATA_BIT_WIDTH = 64;
localparam TWO_LINES_SHF_AMT_BIT_WIDTH = $clog2((2*RANK_BIT_WIDTH)/8);

localparam MEM_CONTROL_SIGS_BIT_WIDTH = 54;

localparam CYCLE_TIME_X10 = 98;
localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;

/*********************************************
    IMPORTANT: SET MAPPED_VPN AND MAPPED PFN 
    TO THE PAGE YOU WANT TO TEST. RIGHT NOW,
    THEY'RE SET TO THE TLB ON DR. PATT'S
    WEBSITE. IF YOU CHANGE THE TLB, THIS TEST
    WILL FAIL AND YOU NEED TO CHANGE THE MAPPING
*********************************************/

reg [2:0] MAPPED_PFN;
reg [19:0] MAPPED_VPN;

initial begin
  MAPPED_PFN = 3'b010;
  MAPPED_VPN = 20'h02000;
end

reg clk;
reg rst_n;

reg  [MEM_CONTROL_SIGS_BIT_WIDTH-1:0]   to_mem_control_sigs;
reg  [31:0]                             to_mem_ld_addr;
reg  [31:0]                             to_mem_st_addr;
reg  [31:0]                             to_mem_ld_slim;
reg  [31:0]                             to_mem_ld_offset;
reg  [31:0]                             to_mem_st_offset;
reg  [31:0]                             to_mem_st_slim;

reg  [1:0]                              to_mem_exception;
reg                                     to_mem_valid;

wire                                    DCACHE_STALL;
wire [RANK_BIT_WIDTH-1:0]               DCACHE_HIT_DATA;
wire                                    DCACHE_HIT;

wire                                    from_mem_stall;
wire [1:0]                              from_mem_exception;
wire                                    from_mem_valid;

wire                                    MEM_VALID_LOAD_INST;
wire [PAGE_BIT_WIDTH-1:0]               MEM_PAGE_OFFSET;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] WB_PR_ST_ADDR_L0;
reg  [CHIPS_PER_RANK-1:0]               WB_PR_ST_MASK_L0;
reg  [RANK_BIT_WIDTH-1:0]               WB_SHF_ST_DATA_L0;
reg                                     WB_VALID_IO_STORE_INST;

wire [VPN_BIT_WIDTH-1:0]                D_RD_TLB_VPN;
wire [PFN_BIT_WIDTH-1:0]                D_RD_TLB_PFN_OUT;
wire                                    D_RD_TLB_CACHE_ENABLE_OUT;
wire                                    D_RD_TLB_PAGE_FAULT_OUT;

wire [VPN_BIT_WIDTH-1:0]                D_WR0_TLB_VPN;
wire [PFN_BIT_WIDTH-1:0]                D_WR0_TLB_PFN_OUT;
wire                                    D_WR0_TLB_WRITE_DISABLE_OUT;
wire                                    D_WR0_TLB_CACHE_ENABLE_OUT;
wire                                    D_WR0_TLB_PAGE_FAULT_OUT;

wire [VPN_BIT_WIDTH-1:0]                D_WR1_TLB_VPN;
wire [PFN_BIT_WIDTH-1:0]                D_WR1_TLB_PFN_OUT;
wire                                    D_WR1_TLB_WRITE_DISABLE_OUT;
wire                                    D_WR1_TLB_CACHE_ENABLE_OUT;
wire                                    D_WR1_TLB_PAGE_FAULT_OUT;

wire [MEM_ADDR_WIDTH-1:0]               MEM_LD_PHYS_ADDR = {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET};

wire [PFN_BIT_WIDTH-1:0] KB_PFN;
wire [PFN_BIT_WIDTH-1:0] DMA_PFN;

wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [CHIPS_PER_RANK-1:0] WR_mask;

wire from_mem_valid_store_inst;
wire [52:0] from_mem_control_sigs;
wire [2:0] from_mem_dstidA;
wire [2:0] from_mem_dstidB;
wire [31:0] from_mem_srcregA;
wire [31:0] from_mem_srcregB;
wire [31:0] from_mem_srcregC;
wire [15:0] from_mem_srcSREG;
wire [63:0] from_mem_MMA;
wire [63:0] from_mem_MMB;
wire [15:0] from_mem_target_cs;
wire [63:0] from_mem_load_result;

wire from_mem_store_is_io_line_0;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] from_mem_store_addr_line_0;
wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] from_mem_store_addr_line_1;
wire [CHIPS_PER_RANK-1:0] from_mem_store_mask_line_0;
wire [CHIPS_PER_RANK-1:0] from_mem_store_mask_line_1;
wire from_mem_store_queue_alloc_line_0;
wire from_mem_store_queue_alloc_line_1;
wire [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] from_mem_store_data_shf_amt;

wire EX_FLUSH;
wire WB_FLUSH;

reg [31:0] from_rr_code_segment_limit;
reg from_ex_flush;
reg from_wb_flush;

integer FAILURES = 0;
integer SUCCESSES = 0;

stage_mem DUT (
  .clk(clk),
  .rst_n(rst_n),

  .to_mem_control_sigs(to_mem_control_sigs),
  .to_mem_dstidA(3'd0),
  .to_mem_dstidB(3'd0),
  .to_mem_srcregA(32'd0),
  .to_mem_srcregB(32'd0),
  .to_mem_srcregC(32'd0),
  .to_mem_srcSREG(16'd0),
  .to_mem_MMA(64'd0),
  .to_mem_MMB(64'd0),
  .to_mem_target_cs(16'd0),
  .to_mem_ld_addr(to_mem_ld_addr),
  .to_mem_ld_offset(to_mem_ld_offset),
  .to_mem_ld_slim(to_mem_ld_slim),
  .to_mem_st_addr(to_mem_st_addr),
  .to_mem_st_offset(to_mem_st_offset),
  .to_mem_st_slim(to_mem_st_slim),
  .to_mem_inc_esp(32'd0),
  .to_mem_dec_esp(32'd0),
  .to_mem_imm(32'd0),
  .to_mem_rel_eip(32'd0),
  .to_mem_cs(16'd0),
  .to_mem_oeip(32'd0),
  .to_mem_ieip(32'd1), /* Make sure we don't underflow and cause an EIP limit violation */
  .to_mem_pred_eip(32'd0),

  .to_mem_exception(to_mem_exception),
  .to_mem_valid(to_mem_valid),

  .DCACHE_STALL(DCACHE_STALL),
  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),

  .from_rr_code_segment_limit(from_rr_code_segment_limit),
  .from_wb_flush(from_wb_flush),
  .from_ex_flush(from_ex_flush),

  .D_RD_TLB_VPN(D_RD_TLB_VPN),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

  .D_WR0_TLB_VPN(D_WR0_TLB_VPN),
  .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
  .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
  .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
  .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

  .D_WR1_TLB_VPN(D_WR1_TLB_VPN),
  .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
  .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
  .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
  .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .EX_FLUSH(EX_FLUSH),
  .WB_FLUSH(WB_FLUSH),

  .from_mem_stall(from_mem_stall),
  .from_mem_valid_store_inst(from_mem_valid_store_inst),
  .from_mem_control_sigs(from_mem_control_sigs),
  .from_mem_dstidA(from_mem_dstidA),
  .from_mem_dstidB(from_mem_dstidB),
  .from_mem_srcregA(from_mem_srcregA),
  .from_mem_srcregB(from_mem_srcregB),
  .from_mem_srcregC(from_mem_srcregC),
  .from_mem_srcSREG(from_mem_srcSREG),
  .from_mem_MMA(from_mem_MMA),
  .from_mem_MMB(from_mem_MMB),
  .from_mem_target_cs(from_mem_target_cs),
  .from_mem_load_result(from_mem_load_result),

  .from_mem_store_is_io_line_0(from_mem_store_is_io_line_0),
  .from_mem_store_addr_line_0(from_mem_store_addr_line_0),
  .from_mem_store_mask_line_0(from_mem_store_mask_line_0),
  .from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0),
  .from_mem_store_addr_line_1(from_mem_store_addr_line_1),
  .from_mem_store_mask_line_1(from_mem_store_mask_line_1),
  .from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1),
  .from_mem_store_data_shf_amt(from_mem_store_data_shf_amt),

  .from_mem_inc_esp(),
  .from_mem_dec_esp(),
  .from_mem_imm(),
  .from_mem_rel_eip(),
  .from_mem_cs(),
  .from_mem_oeip(),
  .from_mem_ieip(),
  .from_mem_pred_eip(),
  .from_mem_exception(from_mem_exception),
  .from_mem_valid(from_mem_valid)
);

full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (1)
) full_cache_inst (
  .rst(rst_n),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(1'b0),
  .STOREQ_LAST_ENTRY(1'b0),
  .STOREQ_DATA(128'd0),
  .STOREQ_DATA_WR_MASK(16'd0),
  .STOREQ_PHYS_ADDR(11'd0),

  .ITLB_PFN_OUT(3'd0),
  .ITLB_PAGE_FAULT_OUT(1'b0),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),

  .F_PAGE_OFFSET(12'd0),
  .ICACHE_HIT_DATA(),
  .ICACHE_VALID(),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),
  .WBE_BUSY(),

  .DMA_INT(),

  .TEST_CASE_NEW_CHAR(8'd0),
  .TEST_CASE_NEW_CHAR_WR(8'd0),
  .TEST_CASE_NEW_READY(1'b0),
  .TEST_CASE_NEW_READY_WR(1'b0),

  .WB_FLUSH(WB_FLUSH),
  .EX_FLUSH(EX_FLUSH)
);

tlb_wrapper tlb_inst (
  .ITLB_VPN(),
  .ITLB_PFN_OUT(),
  .ITLB_WRITE_DISABLE_OUT(),
  .ITLB_CACHE_ENABLE_OUT(),
  .ITLB_PAGE_FAULT_OUT(),

  .D_RD_TLB_VPN(D_RD_TLB_VPN),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_WRITE_DISABLE_OUT(),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

  .D_WR0_TLB_VPN(D_WR0_TLB_VPN),
  .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
  .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
  .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
  .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

  .D_WR1_TLB_VPN(D_WR1_TLB_VPN),
  .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
  .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
  .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
  .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT),

  .DMA_PFN(DMA_PFN),
  .KB_PFN(KB_PFN)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

reg [RANK_BIT_WIDTH-1:0]  long_cache_line_exp;
wire [63:0]  exp_load_result = long_cache_line_exp[63:0];

reg [2*RANK_BIT_WIDTH-1:0]  double_long_cache_line_exp;
wire [63:0]  double_exp_load_result = double_long_cache_line_exp[63:0];


task check_load_result;
  input integer cross;
  reg [63:0] final_exp_load_result;
begin
  final_exp_load_result = (cross == 1) ? double_exp_load_result : exp_load_result;
  if (from_mem_load_result !== final_exp_load_result) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: from_mem_load_result exp=%h got=%h", $time, final_exp_load_result, from_mem_load_result);
  end else begin
    SUCCESSES = SUCCESSES + 1;
    // $display("SUCCESS AT TIME %t: from_mem_load_result exp=%h got=%h", $time, final_exp_load_result, from_mem_load_result);
  end
end
endtask

task check_store_sigs;
  reg store_crosses_lines;
  reg [31:0] starting_mask, exp_mask;

  reg from_mem_store_is_io_line_0_exp;
  reg [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] from_mem_store_addr_line_0_exp;
  reg [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] from_mem_store_addr_line_1_exp;
  reg [CHIPS_PER_RANK-1:0] from_mem_store_mask_line_0_exp;
  reg [CHIPS_PER_RANK-1:0] from_mem_store_mask_line_1_exp;
  reg from_mem_store_queue_alloc_line_0_exp;
  reg from_mem_store_queue_alloc_line_1_exp;
  reg [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0] from_mem_store_data_shf_amt_exp;

  reg fail;

begin
  fail = 0;

  store_crosses_lines = to_mem_st_addr[4] !== to_mem_st_offset[4];

  case (DUT.mem_ds)
    2'b00: starting_mask = 32'd1;
    2'b01: starting_mask = 32'd3;
    2'b10: starting_mask = 32'd15;
    2'b11: starting_mask = 32'd255;
  endcase

  exp_mask = ~(starting_mask << to_mem_st_addr[3:0]);

  from_mem_store_is_io_line_0_exp = 1'b0;
  from_mem_store_addr_line_0_exp = {MAPPED_PFN, to_mem_st_addr[11:4]};
  from_mem_store_addr_line_1_exp = {MAPPED_PFN, to_mem_st_addr[11:4]} + 1;
  from_mem_store_mask_line_0_exp = exp_mask[15:0];
  from_mem_store_mask_line_1_exp = exp_mask[31:16];
  from_mem_store_queue_alloc_line_0_exp = 1'b1;
  from_mem_store_queue_alloc_line_1_exp = store_crosses_lines;
  from_mem_store_data_shf_amt_exp = to_mem_st_addr[3:0];

  if (from_mem_store_is_io_line_0 !== from_mem_store_is_io_line_0_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_is_io_line_0 exp=%b got=%b", from_mem_store_is_io_line_0_exp, from_mem_store_is_io_line_0);
  end

  if (from_mem_store_addr_line_0 !== from_mem_store_addr_line_0_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_addr_line_0 exp=%h got=%h", from_mem_store_addr_line_0_exp, from_mem_store_addr_line_0);
  end

  if (from_mem_store_addr_line_1 !== from_mem_store_addr_line_1_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_addr_line_1 exp=%h got=%h", from_mem_store_addr_line_1_exp, from_mem_store_addr_line_1);
  end

  if (from_mem_store_mask_line_0 !== from_mem_store_mask_line_0_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_mask_line_0 exp=%h got=%h", from_mem_store_mask_line_0_exp, from_mem_store_mask_line_0);
  end

  if (from_mem_store_mask_line_1 !== from_mem_store_mask_line_1_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_mask_line_1 exp=%h got=%h", from_mem_store_mask_line_1_exp, from_mem_store_mask_line_1);
  end

  if (from_mem_store_queue_alloc_line_0 !== from_mem_store_queue_alloc_line_0_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_queue_alloc_line_0 exp=%b got=%b", from_mem_store_queue_alloc_line_0_exp, from_mem_store_queue_alloc_line_0);
  end

  if (from_mem_store_queue_alloc_line_1 !== from_mem_store_queue_alloc_line_1_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_queue_alloc_line_1 exp=%b got=%b", from_mem_store_queue_alloc_line_1_exp, from_mem_store_queue_alloc_line_1);
  end

  if (from_mem_store_data_shf_amt !== from_mem_store_data_shf_amt_exp) begin
    FAILURES = FAILURES + 1;
    fail = 1;
    $display("FAIL: from_mem_store_data_shf_amt exp=%h got=%h", from_mem_store_data_shf_amt_exp, from_mem_store_data_shf_amt);
  end

  if (fail == 0) begin
    SUCCESSES = SUCCESSES + 1;
  end

end
endtask

task check_exception;
  input [1:0] exp_exception;
begin
  if (from_mem_exception !== exp_exception) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: from_mem_exception exp=%h got=%h", $time, exp_exception, from_mem_exception);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i;

wire [31:0] to_mem_ld_addr_plus_one_line = to_mem_ld_addr + 32'd16;
wire [31:0] to_mem_st_addr_plus_one_line = to_mem_st_addr + 32'd16;

initial begin
  rst_n = 0;
  from_rr_code_segment_limit = 32'h00004FFF;
  to_mem_valid = 0;
  to_mem_exception = 0;
  from_ex_flush = 0;
  from_wb_flush = 0;
  to_mem_ld_addr = {MAPPED_VPN,12'h000};
  to_mem_ld_offset = 0;
  to_mem_st_addr = {MAPPED_VPN,12'h000};
  to_mem_st_offset = 0;
  to_mem_control_sigs = {23'd0, 2'b00, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
  // to_mem_control_sigs = {23'd0, 2'b10, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};

  WB_PR_ST_ADDR_L0        = 11'd0;
  WB_PR_ST_MASK_L0        = 16'd0;
  WB_SHF_ST_DATA_L0       = 64'd0;
  WB_VALID_IO_STORE_INST  = 1'b1;
  #(1.5*CYCLE_TIME);
  rst_n = 1;

  /*** POPULATE MEMORY ***/

  #(CYCLE_TIME);
  while (DCACHE_STALL === 1'b1) begin
    #(CYCLE_TIME);
  end

  for (i = 0; i < 600; i = i + 1) begin
    // if (i[10:8] !== KB_PFN && 
    //     i[10:8] !== DMA_PFN) begin
    if (i[10:8] === MAPPED_PFN) begin
      WB_PR_ST_ADDR_L0 = i[10:0];
      WB_SHF_ST_DATA_L0 = {4{i << 4}};
      #(CYCLE_TIME);
      while (DCACHE_STALL === 1'b1) begin
        #(CYCLE_TIME);
      end
    end
  end

  WB_VALID_IO_STORE_INST  = 1'b0;

  #(20*CYCLE_TIME);

  /*** TEST ONE-CACHE-LINE ACCESSES WITH SHIFTING ***/

  to_mem_st_slim = {MAPPED_VPN, 12'h3FF};
  to_mem_st_addr = {MAPPED_VPN,12'h000};
  to_mem_st_offset = to_mem_st_addr;
  to_mem_valid = 1'b1;
  to_mem_control_sigs = {23'd0, 2'b01, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_store_sigs();
  
  while (to_mem_st_offset < to_mem_st_slim) begin
    to_mem_st_addr = to_mem_st_addr + 1;
    to_mem_st_offset = to_mem_st_addr;
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    check_store_sigs();
  end

  /*** Segment limit violation check ***/
  to_mem_st_addr = to_mem_st_addr + 1;
  to_mem_st_offset = to_mem_st_addr;
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_exception(2'b10);

  /*** TEST TWO-CACHE-LINE ACCESSES WITH SHIFTING ***/
  to_mem_st_slim = {MAPPED_VPN, 12'h3FF};
  to_mem_st_addr = {MAPPED_VPN,12'h00C};
  to_mem_st_offset = to_mem_st_addr + 7;
  to_mem_valid = 1'b1;
  to_mem_control_sigs = {23'd0, 2'b01, 2'b11, 2'b00, 2'b11, 15'd0, 8'd0};
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_store_sigs();

  while (to_mem_st_offset < to_mem_st_slim) begin
    to_mem_st_addr = to_mem_st_addr + 1;
    to_mem_st_offset = to_mem_st_addr + 7;
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    check_store_sigs();
  end
  
  /*** Segment limit violation check ***/
  to_mem_st_addr = to_mem_st_addr + 1;
  to_mem_st_offset = to_mem_st_addr + 7;
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_exception(2'b10);

  to_mem_valid = 1'b0;
  #(CYCLE_TIME);

  /*** TEST ONE-CACHE-LINE ACCESSES WITH SHIFTING ***/

  to_mem_ld_slim = {MAPPED_VPN, 12'h3FF};
  to_mem_ld_addr = {MAPPED_VPN,12'h000};
  to_mem_ld_offset = to_mem_ld_addr;
  to_mem_valid = 1'b1;
  to_mem_control_sigs = {23'd0, 2'b10, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
  check_load_result(0);
  
  while (to_mem_ld_offset < to_mem_ld_slim) begin
    to_mem_ld_addr = to_mem_ld_addr + 1;
    to_mem_ld_offset = to_mem_ld_addr;
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    check_load_result(0);
  end

  /*** Segment limit violation check ***/
  to_mem_ld_addr = to_mem_ld_addr + 1;
  to_mem_ld_offset = to_mem_ld_addr;
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_exception(2'b10);

  /*** TEST TWO-CACHE-LINE ACCESSES WITH SHIFTING ***/
  to_mem_st_slim = {MAPPED_VPN, 12'h3FF};
  to_mem_ld_addr = {MAPPED_VPN,12'h00C};
  to_mem_ld_offset = to_mem_ld_addr + 7;
  to_mem_valid = 1'b1;
  to_mem_control_sigs = {23'd0, 2'b10, 2'b11, 2'b00, 2'b11, 15'd0, 8'd0};
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  double_long_cache_line_exp = {{{4{{17'd0, MAPPED_PFN}, to_mem_ld_addr_plus_one_line[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}}, {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}} >> (8 * to_mem_ld_addr[3:0]);
  check_load_result(1);

  while (to_mem_ld_offset < to_mem_ld_slim) begin
    to_mem_ld_addr = to_mem_ld_addr + 1;
    to_mem_ld_offset = to_mem_ld_addr + 7;
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    double_long_cache_line_exp = {{{4{{17'd0, MAPPED_PFN}, to_mem_ld_addr_plus_one_line[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}}, {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}} >> (8 * to_mem_ld_addr[3:0]);
    check_load_result(1);
  end
  
  /*** Segment limit violation check ***/
  to_mem_ld_addr = to_mem_ld_addr + 1;
  to_mem_ld_offset = to_mem_ld_addr + 7;
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end
  check_exception(2'b10);

  to_mem_valid = 1'b0;
  #(50 * CYCLE_TIME);

  /*** RANDOM TESTS (INSPECTION) ***/
  to_mem_st_slim = {MAPPED_VPN, 12'h3FF};
  to_mem_ld_addr = {MAPPED_VPN,12'h000};
  to_mem_ld_offset = to_mem_ld_addr + 3;
  to_mem_valid = 1'b1;
  to_mem_control_sigs = {23'd0, 2'b10, 2'b10, 2'b00, 2'b10, 15'd0, 8'd0};
  #(CYCLE_TIME);
  while (from_mem_stall === 1'b1) begin
    #(CYCLE_TIME);
  end

  repeat (1 << 10) begin
    i = $random;
    to_mem_ld_addr = {MAPPED_VPN,i[PAGE_BIT_WIDTH-1:0]};
    to_mem_ld_offset = to_mem_ld_addr + 3;
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    double_long_cache_line_exp = {{{4{{17'd0, MAPPED_PFN}, to_mem_ld_addr_plus_one_line[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}}, {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}}} >> (8 * to_mem_ld_addr[3:0]);
    if (to_mem_ld_offset < to_mem_ld_slim && to_mem_ld_addr[3:0] > 4'hC)
      check_load_result(1);
    else if (to_mem_ld_offset < to_mem_ld_slim && to_mem_ld_addr[3:0] <= 4'hC)
      check_load_result(0);
  end

  to_mem_valid = 1'b0;
  #(50 * CYCLE_TIME);

  /*** TEST I/O ACCESSES WITH SHIFTING (INSPECTION) ***/
  repeat (2) begin
    to_mem_st_slim = {20'h08000, 12'h3FF};
    to_mem_st_addr = {20'h08000,12'h000};
    to_mem_st_offset = to_mem_st_addr;
    to_mem_valid = 1'b1;
    to_mem_control_sigs = {23'd0, 2'b01, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    // long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    // check_load_result(0);
    to_mem_valid = 1'b0;
    #(20 * CYCLE_TIME);
  end

  repeat (2) begin
    to_mem_st_slim = {20'h06000, 12'h3FF};
    to_mem_st_addr = {20'h06000,12'h010};
    to_mem_st_offset = to_mem_st_addr;
    to_mem_valid = 1'b1;
    to_mem_control_sigs = {23'd0, 2'b01, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    // long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    // check_load_result(0);
    to_mem_valid = 1'b0;
    #(20 * CYCLE_TIME);
  end

  /*** TEST I/O ACCESSES WITH SHIFTING ***/
  repeat (2) begin
    to_mem_st_slim = {20'h08000, 12'h3FF};
    to_mem_ld_addr = {20'h08000,12'h000};
    to_mem_ld_offset = to_mem_ld_addr;
    to_mem_valid = 1'b1;
    to_mem_control_sigs = {23'd0, 2'b10, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    // long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    // check_load_result(0);
    to_mem_valid = 1'b0;
    #(20 * CYCLE_TIME);
  end

  repeat (2) begin
    to_mem_st_slim = {20'h06000, 12'h3FF};
    to_mem_ld_addr = {20'h06000,12'h010};
    to_mem_ld_offset = to_mem_ld_addr;
    to_mem_valid = 1'b1;
    to_mem_control_sigs = {23'd0, 2'b10, 2'b00, 2'b00, 2'b00, 15'd0, 8'd0};
    #(CYCLE_TIME);
    while (from_mem_stall === 1'b1) begin
      #(CYCLE_TIME);
    end
    // long_cache_line_exp = {4{{17'd0, MAPPED_PFN}, to_mem_ld_addr[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}} >> (8 * to_mem_ld_addr[3:0]);
    // check_load_result(0);
    to_mem_valid = 1'b0;
    #(20 * CYCLE_TIME);
  end

  // /*** TEST TWO-CACHE-LINE ACCESSES WITH PAGE CROSSING, Change LINE 4 to Re-map 0a001 instead of 0b000: 000010100000000000011001101 ***/
  // to_mem_ld_slim = 20'hFFFFF;
  // to_mem_ld_addr = 32'h0A000FFC;
  // to_mem_ld_offset = to_mem_ld_addr + 7;
  // to_mem_valid = 1'b1;
  // to_mem_control_sigs = {23'd0, 2'b10, 2'b11, 2'b00, 2'b11, 15'd0, 8'd0};
  // #(CYCLE_TIME);
  // while (from_mem_stall === 1'b1) begin
  //   #(CYCLE_TIME);
  // end
  // double_long_cache_line_exp = {{192{1'b0}}, 32'h00004000, 32'h00005FF0};
  // check_load_result(1);
  // to_mem_valid = 1'b0;
  // #(50 * CYCLE_TIME);

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule