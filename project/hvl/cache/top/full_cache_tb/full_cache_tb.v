module full_cache_tb;

initial begin
  // $vcdplusfile("full_cache_tb.dump.vpd");
  // $vcdpluson(0, full_cache_tb);
  // $vcdpluson(0, full_cache_tb.DUT);
  // $vcdpluson(0, full_cache_tb.DUT.icache_tag_store.tag_store_generation[0].ram8b8w$_tag_store_one_way.mem);
  // $vcdpluson(0, full_cache_tb.DUT.icache_tag_store.tag_store_generation[3].ram8b8w$_tag_store_one_way.mem);
  // $vcdpluson(0, full_cache_tb.DUT.dcache_data_store.data_store_generation[0].data_position_generation[0].ram8b8w$_data_store_one_bus.mem);
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
localparam CYCLE_TIME_X10      = 98; // breaks at 89
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

reg  [MEM_ADDR_WIDTH-1:0]  DCACHE_PHYS_ADDR_READ_PREV;

reg  CHANGED_DCACHE_PHYS_ADDR_READ;

reg  CHECK_DCACHE;


integer FAILURES  = 0;
integer SUCCESSES = 0;

integer file_handle_icache, file_handle;
integer file_dump;
integer clk_ctr_$;
integer k;
initial begin
  // Open the file for writing
  CHANGED_ICACHE_PHYS_ADDR_READ = 1'b0;
  CHANGED_DCACHE_PHYS_ADDR_READ = 1'b0;
  file_handle = $fopen("cache.csv", "w");
  if (file_handle == 0) begin
    $display("Error: Filed to open file for cache!");
  end
  file_handle_icache = $fopen("icache.csv", "w");
  if (file_handle_icache == 0) begin
    $display("Error: Filed to open file for icache!");
  end
  clk_ctr_$ = 0;
end

always @(posedge (clk)) begin
  clk_ctr_$ = clk_ctr_$ + 1;
end

always @(posedge clk) begin
  if (ICACHE_PHYS_ADDR_READ !== ICACHE_PHYS_ADDR_READ_PREV)
      CHANGED_ICACHE_PHYS_ADDR_READ <= 1'b1;
  else
      CHANGED_ICACHE_PHYS_ADDR_READ <= 1'b0;

  ICACHE_PHYS_ADDR_READ_PREV <= ICACHE_PHYS_ADDR_READ;

  
  if (DCACHE_PHYS_ADDR_READ !== DCACHE_PHYS_ADDR_READ_PREV)
      CHANGED_DCACHE_PHYS_ADDR_READ <= 1'b1;
  else
      CHANGED_DCACHE_PHYS_ADDR_READ <= 1'b0;

  DCACHE_PHYS_ADDR_READ_PREV <= DCACHE_PHYS_ADDR_READ;
end




integer ic_set, ic_way, ic_byte;
genvar ic_s;

genvar ic_gway, ic_gbyte;
genvar ic_gtagway;
genvar ic_vset, ic_vway;
genvar dc_dset, dc_dway;
genvar ic_lset;

genvar dc_gway, dc_gbyte, dc_s, dc_vset, dc_vway, dc_lset;

generate

/* ---------------- ICACHE DATA STORE DUMP ---------------- */

for (ic_gway = 0; ic_gway < 4; ic_gway = ic_gway + 1) begin : IC_DATA_WAY
  for (ic_gbyte = 15; ic_gbyte >= 0; ic_gbyte = ic_gbyte - 1) begin : IC_DATA_BYTE

    always begin
      @(posedge ICACHE_VALID);
      @(posedge clk);

      if (ICACHE_VALID === 1'b1) begin
        if (ic_gway == 0 && ic_gbyte == 15) begin
          $fwrite(file_handle_icache, "////////////////////// NEW DATA, PHYS ADDR = %04x @ time = %0t //////////////////////\n", ICACHE_PHYS_ADDR_READ, $time);
          $fwrite(file_handle_icache, "/*** DATA STORE SET 0 ***/\n");
        end
        $fwrite(file_handle_icache,"%02x ",
          DUT.icache_data_store
            .data_store_generation[ic_gway]
            .data_position_generation[ic_gbyte]
            .ram8b8w$_data_store_one_bus
            .mem[0]
        );
        if (ic_gbyte == 0) begin
          $fwrite(file_handle_icache,"\n");
        end
      end
    end

  end
end

/* ---------------- ICACHE TAG STORE DUMP ---------------- */

for (ic_s = 0; ic_s < 8; ic_s = ic_s + 1) begin : IC_TAG_WAY

  always begin
    @(posedge ICACHE_VALID);
    @(posedge clk);

    if (ICACHE_VALID === 1'b1) begin
      if (ic_s == 0) begin
        $fwrite(file_handle_icache, "/*** TAG STORE ***/\n");
      end
        $fwrite(file_handle_icache,
          "%02x ",
          DUT.icache_tag_store
            .tag_store_generation[0]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x ",
          DUT.icache_tag_store
            .tag_store_generation[1]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x ",
          DUT.icache_tag_store
            .tag_store_generation[2]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x\n",
          DUT.icache_tag_store
            .tag_store_generation[3]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
      end

  end

end

/* ---------------- ICACHE VALID STORE DUMP ---------------- */

for (ic_vset = 0; ic_vset < 8; ic_vset = ic_vset + 1) begin : IC_VSET
  for (ic_vway = 0; ic_vway < 4; ic_vway = ic_vway + 1) begin : IC_VWAY

    always begin
      @(posedge ICACHE_VALID);
      @(posedge clk);

      if (ICACHE_VALID === 1'b1) begin
        if (ic_vway == 0 && ic_vset == 0) begin
          $fwrite(file_handle_icache, "/*** VALID STORE ***/\n");
        end
        $fwrite(file_handle_icache,
          "%0d ",
          DUT.icache_valid_store
            .valid_per_set[ic_vset]
            .valid_per_way[ic_vway]
            .reg_n_stream_buffer_next_line_addr.q
        );
        if (ic_vway == 3) begin
          $fwrite(file_handle_icache, "\n");
        end
      end
    end

  end
end

/* ---------------- ICACHE LRU STORE DUMP ---------------- */

for (ic_lset = 0; ic_lset < 8; ic_lset = ic_lset + 1) begin : IC_LSET

  always begin
    @(posedge ICACHE_VALID);
    @(posedge clk);

    if (ICACHE_VALID === 1'b1) begin
      if (ic_lset == 0) begin
        $fwrite(file_handle_icache, "/*** LRU STORE ***/\n");
      end
      $fwrite(file_handle_icache,
        "%0d%0d\n",
        DUT.lru_store_ICACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[ic_lset]
          .lru_store_per_set_VICT_WAYS.D4,
        DUT.lru_store_ICACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[ic_lset]
          .lru_store_per_set_VICT_WAYS.D3
      );
      if (ic_lset == 7) begin
        $fwrite(file_handle_icache, "\n");
      end
    end

  end

end

/* ---------------- DCACHE DATA STORE DUMP ---------------- */

for (dc_gway = 0; dc_gway < 4; dc_gway = dc_gway + 1) begin : DC_DATA_WAY
  for (dc_gbyte = 15; dc_gbyte >= 0; dc_gbyte = dc_gbyte - 1) begin : DC_DATA_BYTE

    always begin
      @(negedge DCACHE_STALL or posedge CHECK_DCACHE);
      @(posedge clk);

      if (DCACHE_STALL === 1'b0) begin
        if (dc_gway == 0 && dc_gbyte == 15) begin
          $fwrite(file_handle, "////////////////////// NEW DATA, PHYS ADDR = %04x @ time = %0t //////////////////////\n", STOREQ_PHYS_ADDR, $time);
          $fwrite(file_handle, "/*** DATA STORE SET 0 ***/\n");
        end
        $fwrite(file_handle,"%02x ",
          DUT.dcache_data_store
            .data_store_generation[dc_gway]
            .data_position_generation[dc_gbyte]
            .ram8b8w$_data_store_one_bus
            .mem[0]
        );
        if (dc_gbyte == 0) begin
          $fwrite(file_handle,"\n");
        end
      end
    end

  end
end

/* ---------------- DCACHE TAG STORE DUMP ---------------- */

for (dc_s = 0; dc_s < 8; dc_s = dc_s + 1) begin : DC_TAG_WAY

  always begin
    @(negedge DCACHE_STALL or posedge CHECK_DCACHE);
    @(posedge clk);

    if (DCACHE_STALL === 1'b0) begin
      if (dc_s == 0) begin
        $fwrite(file_handle, "/*** TAG STORE ***/\n");
      end
        $fwrite(file_handle,
          "%02x ",
          DUT.dcache_tag_store
            .tag_store_generation[0]
            .ram8b8w$_tag_store_one_way
            .mem[dc_s]
        );
        $fwrite(file_handle,
          "%02x ",
          DUT.dcache_tag_store
            .tag_store_generation[1]
            .ram8b8w$_tag_store_one_way
            .mem[dc_s]
        );
        $fwrite(file_handle,
          "%02x ",
          DUT.dcache_tag_store
            .tag_store_generation[2]
            .ram8b8w$_tag_store_one_way
            .mem[dc_s]
        );
        $fwrite(file_handle,
          "%02x\n",
          DUT.dcache_tag_store
            .tag_store_generation[3]
            .ram8b8w$_tag_store_one_way
            .mem[dc_s]
        );
      end

  end

end

/* ---------------- DCACHE VALID STORE DUMP ---------------- */

for (dc_vset = 0; dc_vset < 8; dc_vset = dc_vset + 1) begin : DC_VSET
  for (dc_vway = 0; dc_vway < 4; dc_vway = dc_vway + 1) begin : DC_VWAY

    always begin
      @(negedge DCACHE_STALL or posedge CHECK_DCACHE);
      @(posedge clk);

      if (DCACHE_STALL === 1'b0) begin
        if (dc_vway == 0 && dc_vset == 0) begin
          $fwrite(file_handle, "/*** VALID STORE ***/\n");
        end
        $fwrite(file_handle,
          "%0d ",
          DUT.dcache_valid_store
            .valid_per_set[dc_vset]
            .valid_per_way[dc_vway]
            .reg_n_stream_buffer_next_line_addr.q
        );
        if (dc_vway == 3) begin
          $fwrite(file_handle, "\n");
        end
      end
    end

  end
end

/* ---------------- DCACHE DIRTY STORE DUMP ---------------- */

for (dc_dset = 0; dc_dset < 8; dc_dset = dc_dset + 1) begin : DC_DIRTY_VSET
  for (dc_dway = 0; dc_dway < 4; dc_dway = dc_dway + 1) begin : DC_DIRTY_VWAY

    always begin
      @(negedge DCACHE_STALL or posedge CHECK_DCACHE);
      @(posedge clk);

      if (DCACHE_STALL === 1'b0) begin
        if (dc_dway == 0 && dc_dset == 0) begin
          $fwrite(file_handle, "/*** DIRTY STORE ***/\n");
        end
        $fwrite(file_handle,
          "%0d ",
          DUT.dcache_dirty_store
            .valid_per_set[dc_dset]
            .valid_per_way[dc_dway]
            .reg_n_stream_buffer_next_line_addr.q
        );
        if (dc_dway == 3) begin
          $fwrite(file_handle, "\n");
        end
      end
    end

  end
end

/* ---------------- DCACHE LRU STORE DUMP ---------------- */

for (dc_lset = 0; dc_lset < 8; dc_lset = dc_lset + 1) begin : DC_LSET

  always begin
    @(negedge DCACHE_STALL or posedge CHECK_DCACHE);
    @(posedge clk);

    if (DCACHE_STALL === 1'b0) begin
      if (dc_lset == 0) begin
        $fwrite(file_handle, "/*** LRU STORE ***/\n");
      end
      $fwrite(file_handle,
        "%0d%0d\n",
        DUT.lru_store_DCACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[dc_lset]
          .lru_store_per_set_VICT_WAYS.D4,
        DUT.lru_store_DCACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[dc_lset]
          .lru_store_per_set_VICT_WAYS.D3
      );
      if (dc_lset == 7) begin
        $fwrite(file_handle, "\n");
      end
    end

  end

end

endgenerate




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
  CHECK_DCACHE = 1'b0;

  KB_PFN = 3'd1;
  DMA_PFN = 3'd3;

  STOREQ_LAST_ENTRY = 1;
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
  MEM_VALID_LOAD_INST = 1'b0;

  WB_PR_ST_ADDR_L0 = 0;
  WB_PR_ST_MASK_L0 = 0;
  WB_SHF_ST_DATA_L0 = 0;
  WB_VALID_IO_STORE_INST = 1'b1;

  TEST_CASE_NEW_CHAR = 0;
  TEST_CASE_NEW_CHAR_WR = 0;
  TEST_CASE_NEW_READY = 0;
  TEST_CASE_NEW_READY_WR = 0;

  WB_FLUSH = 0;
  EX_FLUSH = 0;

  rst = 0;
  #(1.5*CYCLE_TIME);
  rst = 1;

  #(3 * CYCLE_TIME);
  @(posedge clk);
  while (DCACHE_STALL === 1'b1) begin
    @(posedge clk);
  end

  /*** BEGIN Populate NON-IO memory locations ***/
  for (i = 1; i < 2048; i = i + 1) begin
    if (i[10:8] != KB_PFN && i[10:8] != DMA_PFN) begin
      WB_PR_ST_ADDR_L0 = i[10:0];
      WB_SHF_ST_DATA_L0 = {4{17'd0, i[10:0], 4'd0}};
      #(CYCLE_TIME);
      while (DCACHE_STALL === 1'b1) begin
        @(posedge clk);
      end
    end
  end
  WB_VALID_IO_STORE_INST = 1'b0;
  /*** END Populate NON-IO memory locations ***/

  /*** BEGIN I$ Read ***/
  #(30*CYCLE_TIME);
  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      {ITLB_PFN_OUT, F_PAGE_OFFSET} <= {i[10:0], 4'b0000};
      @(posedge clk);
      while (ICACHE_VALID === 1'b0) begin
        @(posedge clk);
      end
      check_icache_data(i[10:0]);
    end
  end
  /*** END I$ Read ***/

  /*** BEGIN D$ NON-IO Read ***/
  #(30*CYCLE_TIME);
  MEM_VALID_LOAD_INST = 1'b1;
  #(CYCLE_TIME);
  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
      @(posedge clk);
      while (DCACHE_STALL === 1'b1) begin
        @(posedge clk);
      end
      check_dcache_data(i[10:0]);
    end
  end
  MEM_VALID_LOAD_INST = 1'b0;
  /*** END D$ NON-IO Read ***/

  /*** BEGIN D$ NON-IO Write ***/
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0;
  MEM_VALID_LOAD_INST = 1'b0;
  STOREQ_STORING = 1;
  STOREQ_DATA = {4{{16{1'b1}}, {12{1'b0}}, 4'd0}};
  STOREQ_PHYS_ADDR = 0;
  
  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      STOREQ_PHYS_ADDR = i[10:0];
      STOREQ_DATA = {4{{16{1'b1}}, 1'b0, STOREQ_PHYS_ADDR, 4'd0}};
      #(CYCLE_TIME);
      while (DCACHE_STALL === 1'b1) begin
        @(posedge clk);
      end
      check_dcache_write_data(i[10:0]);
    end
  end

  STOREQ_STORING = 0;
  /*** END D$ NON-IO Write ***/

  /*** BEGIN D$ NON-IO Re-Read ***/
  #(30*CYCLE_TIME);
  MEM_VALID_LOAD_INST = 1'b1;
  #(CYCLE_TIME);
  for (i = 0; i < 2048; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {i[10:0], 4'b0000};
      @(posedge clk);
      while (DCACHE_STALL === 1'b1) begin
        @(posedge clk);
      end
      check_dcache_write_data(i[10:0]);
    end
  end
  MEM_VALID_LOAD_INST = 1'b0;
  /*** END D$ NON-IO Re-Read ***/

  /*** BEGIN I/O TEST ***/
  #(30 * CYCLE_TIME);

  /* DMA CONFIG */
  WB_PR_ST_ADDR_L0 = {DMA_PFN, 8'd1};
  WB_SHF_ST_DATA_L0 = {4{17'd0, {DMA_PFN, 8'd1}, 4'd0}};
  WB_VALID_IO_STORE_INST = 1'b1;

  @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  @(posedge clk);

  /* KB Enable */
  WB_PR_ST_ADDR_L0 = {KB_PFN, 8'b00000010};
  WB_SHF_ST_DATA_L0 = {4{17'd0, {KB_PFN, 8'b00000010}, 4'd1}};
  WB_VALID_IO_STORE_INST = 1'b1;

  @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  @(posedge clk);
  WB_VALID_IO_STORE_INST = 1'b0;

  /* DMA READ */
  MEM_VALID_LOAD_INST = 1'b1;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b0;

  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {DMA_PFN, 8'd1, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data({4{17'd0, {DMA_PFN, 8'd1}, 4'd0}});

  /* KB READ */
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd1);
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000101, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd0);
  MEM_VALID_LOAD_INST = 1'b0;

  TEST_CASE_NEW_CHAR = 8'h67;
  TEST_CASE_NEW_CHAR_WR = {8{1'b1}};
  TEST_CASE_NEW_READY = 1'b1;
  TEST_CASE_NEW_READY_WR = 1'b1;

  #(CYCLE_TIME);

  TEST_CASE_NEW_CHAR = 8'h55;
  TEST_CASE_NEW_CHAR_WR = {8{1'b0}};
  TEST_CASE_NEW_READY = 1'b0;
  TEST_CASE_NEW_READY_WR = 1'b0;

  #(CYCLE_TIME);

  /* KB READ */
  MEM_VALID_LOAD_INST = 1'b1;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b0;
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data({64'd1, 64'd1});
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000101, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd103); // 0x67 = 103
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd1); // Self-clearing ready
  MEM_VALID_LOAD_INST = 1'b0;

  /* DMA CONFIG INIT */
  WB_PR_ST_ADDR_L0 = {DMA_PFN, 8'd1};
  WB_SHF_ST_DATA_L0 = {32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67};
  WB_VALID_IO_STORE_INST = 1'b1;

  @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  @(posedge clk);
  WB_VALID_IO_STORE_INST = 1'b0;
  
  @(posedge DMA_INT);
  @(posedge clk);

  /*** END I/O TEST ***/

  /*** BEGIN I$ Re-Read (Inspection of DMA transfer) ***/
  #(30*CYCLE_TIME);
  for (i = 0; i < 256; i = i + 1) begin
    if (i[10:8] !== KB_PFN && i[10:8] !== DMA_PFN) begin
      {ITLB_PFN_OUT, F_PAGE_OFFSET} <= {i[10:0], 4'b0000};
      @(posedge clk);
      while (ICACHE_VALID === 1'b0) begin
        @(posedge clk);
      end
    end
  end
  /*** END I$ Re-Read (Inspection of DMA transfer) ***/


  /*** BEGIN D$ I/O Reads with Flushes ***/
  #(CYCLE_TIME);

  MEM_VALID_LOAD_INST = 1'b1;
  D_RD_TLB_CACHE_ENABLE_OUT = 1'b0;

  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {DMA_PFN, 8'd1, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data({32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67});
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0;
  @(negedge DCACHE_STALL);
  @(posedge clk);
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {DMA_PFN, 8'd1, 4'b0000};
  #(CYCLE_TIME);
  EX_FLUSH = 1'b1;
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0;
  MEM_VALID_LOAD_INST = 1'b0;
  #(CYCLE_TIME);
  EX_FLUSH = 1'b0;
  while (DCACHE_STALL === 1'b1) begin
    @(DCACHE_STALL);
  end
  @(posedge clk);
  MEM_VALID_LOAD_INST = 1'b1;
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {DMA_PFN, 8'd1, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data({32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67});
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data({32'd1, 32'd3988, 32'h00000067, 32'hFFFFFF67});
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd1);
  {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000101, 4'b0000};
  @(negedge DCACHE_STALL);
  @(posedge clk);
  check_dcache_io_data(128'd103);
  /*** END D$ I/O Reads with Flushes ***/


  // for (i = 0; i < 8; i = i + 1) begin
  //   // Fill 4 ways
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = 0 + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 7) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 8) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 9) + (i << 4);
  //   #(20 * CYCLE_TIME);
  // end

  // {ITLB_PFN_OUT, F_PAGE_OFFSET} = 0;
  // #(20 * CYCLE_TIME);


  // for (i = 0; i < 8; i = i + 1) begin
  //   // Fill 4 ways
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = 0 + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 7) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 8) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = (1 << 9) + (i << 4);
  //   #(20 * CYCLE_TIME);
  // end

  // MEM_VALID_LOAD_INST = 1'b1;

  // for (i = 0; i < 8; i = i + 1) begin
  //   // Fill 4 ways
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0 + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 7) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 8) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 9) + (i << 4);
  //   #(20 * CYCLE_TIME);
  // end

  // // Random store of 1 byte to address 0
  // {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0;
  // MEM_VALID_LOAD_INST = 1'b0;
  // STOREQ_STORING = 1;
  // STOREQ_DATA = {4{{16{1'b1}}, {12{1'b0}}, 4'd0}};
  // STOREQ_DATA_WR_MASK = 16'h7FFF;
  // STOREQ_PHYS_ADDR = 0;

  // #(CYCLE_TIME);

  // #(20 * CYCLE_TIME);
  
  // for (i = 0; i < 8; i = i + 1) begin
  //   // Fill 4 ways
  //   STOREQ_PHYS_ADDR = 0 + (i << 3);
  //   STOREQ_DATA = {4{{16{1'b1}}, 1'b0, STOREQ_PHYS_ADDR, 4'd0}};
  //   #(28 * CYCLE_TIME);
  //   CHECK_DCACHE = 1'b1;
  //   #(2 * CYCLE_TIME);
  //   CHECK_DCACHE = 1'b0;
  // end

  // STOREQ_STORING = 0;


  // for (i = 0; i < 32; i = i + 1) begin
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} + (1 << 4);
  //   #((($random & 32'h7FFFFFFF) % 30) * CYCLE_TIME);

  //   // ITLB_PFN_OUT = 0;
  //   // F_PAGE_OFFSET = $random & 12'hF80;
  //   // #(20 * CYCLE_TIME);
  // end
  // #(20 * CYCLE_TIME);

  // for (i = 0; i < 8; i = i + 1) begin
  //   // Fill 4 ways
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = 0 + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 7) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 8) + (i << 4);
  //   #(20 * CYCLE_TIME);
  //   {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = (1 << 9) + (i << 4);
  //   #(20 * CYCLE_TIME);
  // end

  // for (i = 0; i < 32; i = i + 1) begin
  //   {ITLB_PFN_OUT, F_PAGE_OFFSET} = {ITLB_PFN_OUT, F_PAGE_OFFSET} + (1 << 4);
  //   #((($random & 32'h7FFFFFFF) % 30) * CYCLE_TIME);

  //   // ITLB_PFN_OUT = 0;
  //   // F_PAGE_OFFSET = $random & 12'hF80;
  //   // #(20 * CYCLE_TIME);
  // end
  // #(20 * CYCLE_TIME);

  // #(30 * CYCLE_TIME);

  // WB_PR_ST_ADDR_L0 = {DMA_PFN, 8'd1};
  // WB_SHF_ST_DATA_L0 = {4{17'd0, {DMA_PFN, 8'd1}, 4'd0}};
  // WB_VALID_IO_STORE_INST = 1'b1;

  // @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  // @(posedge clk);
  // WB_VALID_IO_STORE_INST = 1'b0;

  // #(30 * CYCLE_TIME);

  // WB_PR_ST_ADDR_L0 = {KB_PFN, 8'b00000010};
  // WB_SHF_ST_DATA_L0 = {4{17'd0, {KB_PFN, 8'b00000010}, 4'd1}};
  // WB_VALID_IO_STORE_INST = 1'b1;

  // @(negedge DUT.WBE_BUSY); @(negedge DUT.WBE_BUSY);
  // @(posedge clk);
  // WB_VALID_IO_STORE_INST = 1'b0;

  // #(30 * CYCLE_TIME);
  // MEM_VALID_LOAD_INST = 1'b1;
  // D_RD_TLB_CACHE_ENABLE_OUT = 1'b0;

  // // Fill 4 ways
  // {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {DMA_PFN, 8'd1, 4'b0000};
  // @(negedge DCACHE_STALL);
  // @(posedge clk);
  // {D_RD_TLB_PFN_OUT, MEM_PAGE_OFFSET} = {KB_PFN, 8'b00000010, 4'b0000};
  // @(negedge DCACHE_STALL);
  // @(posedge clk);
  // MEM_VALID_LOAD_INST = 1'b0;

  #(2 * CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);


  $finish;

end

endmodule