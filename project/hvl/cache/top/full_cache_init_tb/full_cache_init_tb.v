module full_cache_init_tb;

initial begin
  // $vcdplusfile("full_cache_init_tb.dump.vpd");
  // $vcdpluson(0, full_cache_init_tb);
  // $vcdpluson(0, full_cache_init_tb.DUT);
  // $vcdpluson(0, full_cache_init_tb.DUT.icache_tag_store.tag_store_generation[0].ram8b8w$_tag_store_one_way.mem);
  // $vcdpluson(0, full_cache_init_tb.DUT.icache_tag_store.tag_store_generation[3].ram8b8w$_tag_store_one_way.mem);
  // $vcdpluson(0, full_cache_init_tb.DUT.dcache_data_store.data_store_generation[0].data_position_generation[0].ram8b8w$_data_store_one_bus.mem);
end

localparam MEM_BYTE_CAPACITY   = 32768;
localparam MEM_ADDR_WIDTH      = $clog2(MEM_BYTE_CAPACITY);
localparam CHIP_BIT_WIDTH      = 8;
localparam CHIP_BYTE_WIDTH     = CHIP_BIT_WIDTH/8;
localparam CHIP_ROW_COUNT      = 128;
localparam CHIP_BYTE_CAPACITY  = CHIP_ROW_COUNT*CHIP_BYTE_WIDTH;
localparam CHIP_COUNT          = MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY;
localparam BUS_BIT_WIDTH       = 32;
localparam RANK_BIT_WIDTH      = 128;
localparam RANK_BURST_SIZE     = RANK_BIT_WIDTH/BUS_BIT_WIDTH;
localparam CHIPS_PER_RANK      = RANK_BIT_WIDTH/CHIP_BIT_WIDTH;
localparam RANK_BYTE_CAPACITY  = CHIP_BYTE_CAPACITY*CHIPS_PER_RANK;
localparam RANK_COUNT          = MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY;
localparam RANK_IDX_WIDTH      = $clog2(RANK_COUNT);
localparam RANK_ADDR_WIDTH     = MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK);
localparam CYCLE_TIME_X10      = 98;
localparam CYCLE_TIME          = CYCLE_TIME_X10/10.0;
localparam BYTES_PER_BUS       = 4;
localparam NUM_SETS            = 8;
localparam INDEX_WIDTH         = $clog2(NUM_SETS);
localparam NUM_WAYS            = 4;
localparam WAY_WIDTH           = $clog2(NUM_WAYS);
localparam TAG_WIDTH           = 8;
localparam PAGE_SIZE_BYTES     = 4096;
localparam PAGE_BIT_WIDTH      = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH       = MEM_ADDR_WIDTH-PAGE_BIT_WIDTH;
localparam TRUE_LRU            = 1;
localparam STOREQ_MASK_WIDTH   = RANK_BURST_SIZE*BYTES_PER_BUS;

reg  clk;
reg  rst;

reg  [2:0]                     KB_PFN;
reg  [2:0]                     DMA_PFN;

wire [BUS_BIT_WIDTH-1:0]       DATA_BUS;
wire [MEM_ADDR_WIDTH-1:0]      ADDR_BUS;
wire [CHIPS_PER_RANK-1:0]      WR_mask;

reg                            STOREQ_STORING;
reg                            STOREQ_LAST_ENTRY;
reg  [RANK_BIT_WIDTH-1:0]      STOREQ_DATA;
reg  [STOREQ_MASK_WIDTH-1:0]   STOREQ_DATA_WR_MASK;
reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] STOREQ_PHYS_ADDR;

reg  [PFN_BIT_WIDTH-1:0]       ITLB_PFN_OUT;
reg                            ITLB_PAGE_FAULT_OUT;

reg  [PFN_BIT_WIDTH-1:0]       D_RD_TLB_PFN_OUT;
reg                            D_RD_TLB_CACHE_ENABLE_OUT;

reg  [PAGE_BIT_WIDTH-1:0]      F_PAGE_OFFSET;

wire [RANK_BIT_WIDTH-1:0]      ICACHE_HIT_DATA;
wire                           ICACHE_VALID;

reg  [PAGE_BIT_WIDTH-1:0]      MEM_PAGE_OFFSET;
reg                            MEM_VALID_LOAD_INST;

reg  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] WB_PR_ST_ADDR_L0;
reg  [CHIPS_PER_RANK-1:0]      WB_PR_ST_MASK_L0;
reg  [RANK_BIT_WIDTH-1:0]      WB_SHF_ST_DATA_L0;
reg                            WB_VALID_IO_STORE_INST;

wire [RANK_BIT_WIDTH-1:0]      DCACHE_HIT_DATA;
wire                           DCACHE_HIT;
wire                           DCACHE_STALL;
wire                           WBE_BUSY;

wire                           DMA_INT;

reg  [7:0]                     TEST_CASE_NEW_CHAR;
reg  [7:0]                     TEST_CASE_NEW_CHAR_WR;
reg                            TEST_CASE_NEW_READY;
reg                            TEST_CASE_NEW_READY_WR;

reg                            WB_FLUSH;
reg                            EX_FLUSH;

wire  [TAG_WIDTH-1:0]       ICACHE_RQ_TAG = {ITLB_PFN_OUT, F_PAGE_OFFSET[11:7]};
wire  [INDEX_WIDTH-1:0]     ICACHE_RQ_SET = {F_PAGE_OFFSET[6:4]};
wire  [MEM_ADDR_WIDTH-1:0]  ICACHE_PHYS_ADDR_READ = {ITLB_PFN_OUT, F_PAGE_OFFSET};

reg  [MEM_ADDR_WIDTH-1:0]  ICACHE_PHYS_ADDR_READ_PREV;

reg  CHANGED_ICACHE_PHYS_ADDR_READ;

wire  [TAG_WIDTH-1:0]       DCACHE_RQ_TAG = {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET[11:7]};
wire  [INDEX_WIDTH-1:0]     DCACHE_RQ_SET = {MEM_PAGE_OFFSET[6:4]};
wire  [MEM_ADDR_WIDTH-1:0]  DCACHE_PHYS_ADDR_READ = {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET};

wire  [TAG_WIDTH-1:0]       STOREQ_RQ_TAG = STOREQ_PHYS_ADDR[14:7];
wire  [INDEX_WIDTH-1:0]     STOREQ_RQ_SET = STOREQ_PHYS_ADDR[6:4];


integer FAILURES  = 0;
integer SUCCESSES = 0;

full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) DUT (
  .rst(rst),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),

  .F_PAGE_OFFSET(F_PAGE_OFFSET),
  .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
  .ICACHE_VALID(ICACHE_VALID),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),
  .WBE_BUSY(WBE_BUSY),
  .DCACHE_STALL_UNCOND_BAR(),
  .DCACHE_STALL_IF_MEM_BAR(),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),

  .WB_FLUSH(WB_FLUSH),
  .EX_FLUSH(EX_FLUSH)
);

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

task check_icache_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  icache_addr;
  begin
    if (ICACHE_HIT_DATA !== {4{17'd0, icache_addr, 4'd0}}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: ICACHE_HIT_DATA exp=%h got=%h", $time, {4{17'd0, icache_addr, 4'd0}}, ICACHE_HIT_DATA);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_dcache_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  dcache_addr;
  begin
    if (DCACHE_HIT_DATA !== {4{17'd0, dcache_addr, 4'd0}}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, {4{17'd0, dcache_addr, 4'd0}}, DCACHE_HIT_DATA);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_dcache_write_data;
  input [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  dcache_addr;
  begin
    if (DCACHE_HIT_DATA !== {4{{16{1'b1}}, 1'b0, dcache_addr, 4'd0}}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, {4{{16{1'b1}}, 1'b0, dcache_addr, 4'd0}}, DCACHE_HIT_DATA);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_dcache_io_data;
  input [RANK_BIT_WIDTH-1:0]  exp_data;
  begin
    if (DCACHE_HIT_DATA !== exp_data) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: DCACHE_HIT_DATA exp=%h got=%h", $time, exp_data, DCACHE_HIT_DATA);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

integer i, j;

initial begin

  KB_PFN = 3'd1;
  DMA_PFN = 3'd3;

  STOREQ_LAST_ENTRY = 0;
  STOREQ_STORING = 0;
  STOREQ_DATA = 0;
  STOREQ_DATA_WR_MASK = 0;
  STOREQ_PHYS_ADDR = 0;

  ITLB_PFN_OUT = 0;
  ITLB_PAGE_FAULT_OUT = 0;

  D_RD_TLB_PFN_OUT = 0;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b1;

  F_PAGE_OFFSET = 0;

  MEM_PAGE_OFFSET = 0;
  MEM_VALID_LOAD_INST = 0;

  WB_PR_ST_ADDR_L0 = 0;
  WB_PR_ST_MASK_L0 = 0;
  WB_SHF_ST_DATA_L0 = 0;
  WB_VALID_IO_STORE_INST = 0;

  TEST_CASE_NEW_CHAR = 0;
  TEST_CASE_NEW_CHAR_WR = 0;
  TEST_CASE_NEW_READY = 0;
  TEST_CASE_NEW_READY_WR = 0;

  WB_FLUSH = 0;
  EX_FLUSH = 0;

  rst = 0;
  #(1.5*CYCLE_TIME);
  rst = 1;

  /*** BEGIN I$ Read ***/
  #(30*CYCLE_TIME);
  for (i = 0; i < 4; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      {ITLB_PFN_OUT, F_PAGE_OFFSET} <= {i[10:0], 4'b0000};
      #(50 * CYCLE_TIME);
    end
  end
  /*** END I$ Read ***/

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);


  $finish;

end

initial begin
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip0.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip1.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip2.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip3.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip4.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip5.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip6.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip7.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip8.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip9.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip10.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip11.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip12.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip13.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip14.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip15.hex", DUT.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
end




endmodule