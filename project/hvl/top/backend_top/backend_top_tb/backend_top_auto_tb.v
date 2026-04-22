module backend_top_auto_tb;

// initial begin
//   $vcdplusfile("backend_top_auto_tb.dump.vpd");
//   $vcdpluson(0, backend_top_auto_tb); 
// end

integer i;
integer NUM_TESTS = 0;
integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME_X10 = 97;
localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;
localparam TRUE_LRU = 1;

reg clk;
reg rst_n;

wire [6:0]  from_de_prefix;
wire [7:0]  from_de_opcode;
wire [7:0]  from_de_modrm;
wire [7:0]  from_de_sib;
wire [31:0] from_de_disp;
wire [1:0]  from_de_dispsize;
wire [47:0] from_de_imm;
wire [2:0]  from_de_imm_size;
wire [1:0]  from_de_addr_mode;

wire  [31:0] from_de_oeip;
wire  [31:0] from_de_ieip;
wire  [31:0] from_de_pred_eip;
wire  [1:0]  from_de_exception;
wire         from_de_valid;

wire [6:0]  to_rr_prefix;
wire [7:0]  to_rr_opcode;
wire [7:0]  to_rr_modrm;
wire [7:0]  to_rr_sib;
wire [31:0] to_rr_disp;
wire [1:0]  to_rr_dispsize;
wire [47:0] to_rr_imm;
wire [2:0]  to_rr_imm_size;
wire [1:0]  to_rr_addr_mode;

wire  [31:0] to_rr_oeip;
wire  [31:0] to_rr_ieip;
wire  [31:0] to_rr_pred_eip;
wire  [1:0]  to_rr_exception;
wire         to_rr_valid;

/*** CACHE / TLB INTERNAL WIRES ***/
wire [11:0] MEM_PAGE_OFFSET;
wire        MEM_VALID_LOAD_INST;

wire [14:4] WB_PR_ST_ADDR_L0;
wire [15:0] WB_PR_ST_MASK_L0;
wire [127:0] WB_SHF_ST_DATA_L0;
wire        WB_VALID_IO_STORE_INST;

wire        STOREQ_STORING;
wire        STOREQ_LAST_ENTRY;
wire [127:0] STOREQ_DATA;
wire [15:0]  STOREQ_DATA_WR_MASK;
wire [14:4]  STOREQ_PHYS_ADDR;

wire [19:0] D_RD_TLB_VPN;
wire [2:0]  D_RD_TLB_PFN_OUT;
wire        D_RD_TLB_CACHE_ENABLE_OUT;
wire        D_RD_TLB_PAGE_FAULT_OUT;

wire [19:0] D_WR0_TLB_VPN;
wire [2:0]  D_WR0_TLB_PFN_OUT;
wire        D_WR0_TLB_WRITE_DISABLE_OUT;
wire        D_WR0_TLB_CACHE_ENABLE_OUT;
wire        D_WR0_TLB_PAGE_FAULT_OUT;

wire [19:0] D_WR1_TLB_VPN;
wire [2:0]  D_WR1_TLB_PFN_OUT;
wire        D_WR1_TLB_WRITE_DISABLE_OUT;
wire        D_WR1_TLB_CACHE_ENABLE_OUT;
wire        D_WR1_TLB_PAGE_FAULT_OUT;

/*** CACHE INTERFACES ***/
wire [127:0] DCACHE_HIT_DATA;
wire         DCACHE_HIT;
wire         DCACHE_STALL;
wire         WBE_BUSY;
wire         DMA_INT;

/*** FULL CACHE BUS WIRES (TB SIDE) ***/
wire [31:0] DATA_BUS;
wire [14:0]  ADDR_BUS;
wire [15:0]  WR_mask;

wire [2:0] KB_PFN;
wire [2:0] DMA_PFN;

/*** OUTPUTS FROM DUT ***/
wire from_rr_stall;
wire [15:0] from_regunit_CS;
wire [31:0] from_regunit_cs_limit;
wire from_ex_flush;
wire from_ex_br_t_nt;
wire from_ex_br_valid;
wire [31:0] from_ex_eip_target;
wire from_wb_flush;

reg [31:0] wb_ieip;
reg [31:0] wb_eflags;

reg        arch_snap_valid;
reg [31:0] arch_snap_ieip;
reg [31:0] arch_snap_oeip;
reg [31:0] arch_snap_eflags;

reg [31:0] arch_snap_gpr [0:7];
reg [63:0] arch_snap_mmx [0:7];
reg [15:0] arch_snap_seg [0:5];
reg [15:0] arch_snap_cs;

/*** KEYBOARD TEST CASE ***/
reg [7:0] TEST_CASE_NEW_CHAR, TEST_CASE_NEW_CHAR_WR;
reg TEST_CASE_NEW_READY, TEST_CASE_NEW_READY_WR;

/*** DUT ***/
backend_top dut (
  .clk(clk),
  .rst_n(rst_n),

  .to_rr_prefix(to_rr_prefix),
  .to_rr_opcode(to_rr_opcode),
  .to_rr_modrm(to_rr_modrm),
  .to_rr_sib(to_rr_sib),
  .to_rr_disp(to_rr_disp),
  .to_rr_dispsize(to_rr_dispsize),
  .to_rr_imm(to_rr_imm),
  .to_rr_imm_size(to_rr_imm_size),
  .to_rr_addr_mode(to_rr_addr_mode),
  .to_rr_oeip(to_rr_oeip),
  .to_rr_ieip(to_rr_ieip),
  .to_rr_pred_eip(to_rr_pred_eip),
  .to_rr_exception(to_rr_exception),
  .to_rr_valid(to_rr_valid),

  .from_rr_stall(from_rr_stall),
  .from_regunit_CS(from_regunit_CS),
  .from_regunit_cs_limit(from_regunit_cs_limit),
  .from_ex_flush(from_ex_flush),
  .from_ex_br_t_nt(from_ex_br_t_nt),
  .from_ex_br_valid(from_ex_br_valid),
  .from_ex_eip_target(from_ex_eip_target),
  .from_wb_flush(from_wb_flush),

  /*** CACHE INTERFACE ***/
  .DCACHE_STALL(DCACHE_STALL),
  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .WBE_BUSY(WBE_BUSY),
  .DMA_INT(DMA_INT),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  /*** TLB INTERFACE ***/
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
  .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT)
);

full_cache #(
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) full_cache_inst (
  .rst(rst_n),
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
  .WBE_BUSY(WBE_BUSY),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(TEST_CASE_NEW_CHAR),
  .TEST_CASE_NEW_CHAR_WR(TEST_CASE_NEW_CHAR_WR),
  .TEST_CASE_NEW_READY(TEST_CASE_NEW_READY),
  .TEST_CASE_NEW_READY_WR(TEST_CASE_NEW_READY_WR),

  .WB_FLUSH(from_wb_flush),
  .EX_FLUSH(from_ex_flush)
);

always @(posedge full_cache_inst.full_cc_off_core_inst.off_core_top_inst.kb_inst.KBER) begin
  TEST_CASE_NEW_CHAR <= 8'h67;
  TEST_CASE_NEW_CHAR_WR <= 8'hFF;
  TEST_CASE_NEW_READY <= 1'b1;
  TEST_CASE_NEW_READY_WR <= 1'b1;
  #(CYCLE_TIME);
  TEST_CASE_NEW_CHAR <= 8'h00;
  TEST_CASE_NEW_CHAR_WR <= 8'h00;
  TEST_CASE_NEW_READY <= 1'b0;
  TEST_CASE_NEW_READY_WR <= 1'b0;
end

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

reg [127:0] to_de_outbytes;
reg         to_de_valid;

localparam NUM_TESTS_MEM = 4096;
reg [127:0] mem_in [0:NUM_TESTS_MEM-1];

always #(CYCLE_TIME / 2.0) clk = ~clk;

localparam MAX_MAP_ENTRIES = 4096;

reg [31:0] map_eip [0:MAX_MAP_ENTRIES-1];
integer    map_idx [0:MAX_MAP_ENTRIES-1];
integer    map_count;

task load_eip_idx_map;
  input [1023:0] filename;
  integer fd;
  integer code;
  reg [31:0] eip_tmp;
  integer idx_tmp;
begin
  map_count = 0;

  fd = $fopen(filename, "r");
  if (fd == 0) begin
    $display("ERROR: cannot open mapping file: %0s", filename);
    $finish;
  end

  while (!$feof(fd)) begin
    code = $fscanf(fd, "0x%h %d\n", eip_tmp, idx_tmp);
    if (code == 2) begin
      map_eip[map_count] = eip_tmp;
      map_idx[map_count] = idx_tmp;
      map_count = map_count + 1;
    end
  end

  $fclose(fd);
  // $display("Loaded %0d eip->idx entries", map_count);
end
endtask

task clear_inputs;
begin
  to_de_outbytes = {128{1'b0}};
  to_de_valid = 1'b0;
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/gen_testcases.mem", mem_in);
end
endtask


task take_arch_snapshot;
  input [31:0] snap_oeip;
  input [31:0] snap_ieip;
  input [31:0] snap_eflags;
  integer si;
begin
  arch_snap_valid  = 1'b1;
  arch_snap_oeip   = snap_oeip;
  arch_snap_ieip   = snap_ieip;
  arch_snap_eflags = snap_eflags;

  for (si = 0; si < 8; si = si + 1)
    arch_snap_gpr[si] = dut.inst_regunit.gprf.q[si];

  for (si = 0; si < 8; si = si + 1)
    arch_snap_mmx[si] = dut.inst_regunit.mmxrf.mmx_regs.q[si];

  arch_snap_seg[0] = dut.inst_regunit.segrf.seg_rf.q[0]; // ES
  arch_snap_cs     = dut.inst_regunit.segrf.cs_q;        // CS
  arch_snap_seg[1] = dut.inst_regunit.segrf.seg_rf.q[2]; // SS
  arch_snap_seg[2] = dut.inst_regunit.segrf.seg_rf.q[3]; // DS
  arch_snap_seg[3] = dut.inst_regunit.segrf.seg_rf.q[4]; // FS
  arch_snap_seg[4] = dut.inst_regunit.segrf.seg_rf.q[5]; // GS
end
endtask

reg [31:0] saved_st_addr;
reg [255:0] combined_data;
reg [31:0] combined_mask;
reg [31:0] saved_ieip, halt_ieip;

// Pending Read/Wrote buffer: each entry tagged with the ieip of the instruction
localparam MAX_PENDING_MEM = 64;
reg        pend_mem_is_wr [0:MAX_PENDING_MEM-1]; // 0=Read, 1=Wrote
reg [7:0]  pend_mem_val   [0:MAX_PENDING_MEM-1];
reg [31:0] pend_mem_va    [0:MAX_PENDING_MEM-1];
reg [15:0] pend_mem_pa    [0:MAX_PENDING_MEM-1];
reg [31:0] pend_mem_oeip  [0:MAX_PENDING_MEM-1]; // which instruction this belongs to
integer    pend_mem_cnt;

// Snapshot buffer: holds the Read/Wrote lines to print after the separator
reg        snap_is_wr [0:MAX_PENDING_MEM-1];
reg [7:0]  snap_val   [0:MAX_PENDING_MEM-1];
reg [31:0] snap_va    [0:MAX_PENDING_MEM-1];
reg [15:0] snap_pa    [0:MAX_PENDING_MEM-1];
integer    snap_cnt;

integer flush_i;
// Print and remove all pending entries whose ieip matches the given ieip
task flush_pending_for_oeip;
  input [31:0] target_oeip;
  integer fi, new_cnt;
begin
  // First pass: print matching entries
  for (fi = 0; fi < pend_mem_cnt; fi = fi + 1) begin
    if (pend_mem_oeip[fi] === target_oeip) begin
      if (pend_mem_is_wr[fi] === 1'b0)
        $fdisplay(file_handle_cmp,"Read  0x%02x from va = 0x%08x and pa = 0x%04x",
          pend_mem_val[fi], pend_mem_va[fi], pend_mem_pa[fi]);
      else
        $fdisplay(file_handle_cmp,"Wrote 0x%02x to   va = 0x%08x and pa = 0x%04x",
          pend_mem_val[fi], pend_mem_va[fi], pend_mem_pa[fi]);
    end
  end
  // Second pass: compact out matched entries
  new_cnt = 0;
  for (fi = 0; fi < pend_mem_cnt; fi = fi + 1) begin
    if (pend_mem_oeip[fi] !== target_oeip) begin
      pend_mem_is_wr[new_cnt] = pend_mem_is_wr[fi];
      pend_mem_val  [new_cnt] = pend_mem_val  [fi];
      pend_mem_va   [new_cnt] = pend_mem_va   [fi];
      pend_mem_pa   [new_cnt] = pend_mem_pa   [fi];
      pend_mem_oeip [new_cnt] = pend_mem_oeip [fi];
      new_cnt = new_cnt + 1;
    end
  end
  pend_mem_cnt = new_cnt;
end
endtask

task print_arch_snapshot;
  input integer is_hlt_status;
begin
  flush_pending_for_oeip(arch_snap_oeip);

  $fdisplay(file_handle_cmp,"Architectural State %0d", NUM_TESTS);

  $fdisplay(file_handle_cmp,"EAX: 0x%08X    ECX: 0x%08X    EDX: 0x%08X    EBX: 0x%08X",
           arch_snap_gpr[0], arch_snap_gpr[1], arch_snap_gpr[2], arch_snap_gpr[3]);

  $fdisplay(file_handle_cmp,"ESP: 0x%08X    EBP: 0x%08X    ESI: 0x%08X    EDI: 0x%08X",
           arch_snap_gpr[4], arch_snap_gpr[5], arch_snap_gpr[6], arch_snap_gpr[7]);

    // ---------------- MMX ----------------
  $fdisplay(file_handle_cmp,"MM0: 0x%016X               MM1: 0x%016X          ",
           arch_snap_mmx[0], arch_snap_mmx[1]);

  $fdisplay(file_handle_cmp,"MM2: 0x%016X               MM3: 0x%016X          ",
           arch_snap_mmx[2], arch_snap_mmx[3]);

  $fdisplay(file_handle_cmp,"MM4: 0x%016X               MM5: 0x%016X          ",
           arch_snap_mmx[4], arch_snap_mmx[5]);

  $fdisplay(file_handle_cmp,"MM6: 0x%016X               MM7: 0x%016X          ",
           arch_snap_mmx[6], arch_snap_mmx[7]);

  $fdisplay(file_handle_cmp," ES: 0x%04X CS: 0x%04X SS: 0x%04X DS: 0x%04X FS: 0x%04X GS: 0x%04X",
           arch_snap_seg[0], arch_snap_cs, arch_snap_seg[1],
           arch_snap_seg[2], arch_snap_seg[3], arch_snap_seg[4]);

  $fdisplay(file_handle_cmp," CF: %0d      PF: %0d      AF: %0d      ZF: %0d      SF: %0d      OF: %0d      DF: %0d",
           arch_snap_eflags[0],
           arch_snap_eflags[2],
           arch_snap_eflags[4],
           arch_snap_eflags[6],
           arch_snap_eflags[7],
           arch_snap_eflags[11],
           arch_snap_eflags[10]);

  $fdisplay(file_handle_cmp,"EIP: 0x%08X",
           (is_hlt_status === 1'b1 ? dut.to_rr_ieip : arch_snap_ieip));

  $fdisplay(file_handle_cmp,"----------------------------------------");
end
endtask

integer load_iters, k, m, n, difference, starting_point;

always @(posedge clk) begin
  if (!rst_n) begin 
    halt_ieip <= 32'b0;
  end else if (to_rr_opcode == 8'hF4) begin 
    halt_ieip <= to_rr_ieip;
  end
  saved_ieip <= dut.to_ex_ieip;

  if ((dut.to_wb_ieip == halt_ieip) && dut.to_wb_valid === 1'b1) begin
    #(10 * CYCLE_TIME);

    if (arch_snap_valid) begin
      print_arch_snapshot(1);
      NUM_TESTS = NUM_TESTS + 1;
      arch_snap_valid = 1'b0;
    end

    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
    $finish;
  end

  if (dut.inst_stage_mem.rw_buf16[0] === 1'b1 && dut.from_mem_stall === 1'b0 && dut.inst_stage_mem.from_mem_valid === 1'b1) begin
    saved_st_addr = dut.inst_stage_mem.to_mem_st_addr;
  end
  if (((dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b0 && dut.from_mem_stall === 1'b0 && dut.inst_stage_mem.from_mem_valid === 1'b1) ||
       (dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b1 && dut.inst_stage_mem.LINE_0_LOAD_DONE === 1'b1) ||
       (dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b1 && dut.inst_stage_mem.DOING_LINE_1_LOAD === 1'b1 && dut.from_mem_stall === 1'b0)) &&
        dut.inst_stage_mem.from_mem_exception === 2'b00) begin
    case (dut.inst_stage_mem.mem_ds)
      2'b00: load_iters=1;
      2'b01: load_iters=2;
      2'b10: load_iters=4;
      2'b11: load_iters=8;
    endcase
    if ((dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b1 && dut.from_mem_stall === 1'b0)) begin
      difference = 16 - dut.inst_stage_mem.to_mem_ld_addr[3:0];
      starting_point = 0;
    end else begin
      difference = 0;
      starting_point = dut.inst_stage_mem.to_mem_ld_addr[3:0];
    end
    // $display("TIME %t: difference = %d, starting_point = %d", $time, difference, starting_point);
    for (k = starting_point; k < (starting_point + load_iters - difference) && k < 16; k = k + 1) begin
      if (pend_mem_cnt < MAX_PENDING_MEM) begin
        pend_mem_is_wr[pend_mem_cnt] = 1'b0;
        pend_mem_val  [pend_mem_cnt] = (dut.inst_stage_mem.from_mem_load_result >> (8 * ((k-starting_point)+difference))) & 8'hFF;
        pend_mem_va   [pend_mem_cnt] = dut.inst_stage_mem.to_mem_ld_addr[31:0] + ((k-starting_point)+difference);
        pend_mem_pa   [pend_mem_cnt] = (dut.inst_stage_mem.to_mem_ld_addr[14:0] + ((k-starting_point)+difference)) & 16'h7FFF;
        pend_mem_pa   [pend_mem_cnt][14:12] = D_RD_TLB_PFN_OUT[2:0];
        pend_mem_oeip [pend_mem_cnt] = dut.to_mem_oeip;
        pend_mem_cnt = pend_mem_cnt + 1;
      end
    end
  end
  if (dut.inst_stage_wb.to_wb_store_is_io_line_0 === 1'b1 && dut.inst_stage_wb.no_exception === 1'b1 && dut.inst_stage_wb.to_wb_valid_buf16 === 1'b1) begin
    for (m = 0; m < 16; m = m + 1) begin
      if (WB_PR_ST_MASK_L0[m] === 1'b0) begin
        if (pend_mem_cnt < MAX_PENDING_MEM) begin
          pend_mem_is_wr[pend_mem_cnt] = 1'b1;
          pend_mem_val  [pend_mem_cnt] = (WB_SHF_ST_DATA_L0 >> (8*m)) & 8'hFF;
          pend_mem_va   [pend_mem_cnt] = {saved_st_addr[31:4], 4'd0} + m;
          pend_mem_pa   [pend_mem_cnt] = {WB_PR_ST_ADDR_L0[14:4], 4'd0} + m;
          pend_mem_oeip [pend_mem_cnt] = dut.to_wb_oeip;
          pend_mem_cnt = pend_mem_cnt + 1;
        end
      end
    end
  end
  if ((dut.inst_stage_wb.to_wb_store_queue_alloc_line_0 === 1'b1 || dut.inst_stage_wb.to_wb_store_queue_alloc_line_1 === 1'b1) && dut.inst_stage_wb.no_exception === 1'b1 && dut.inst_stage_wb.to_wb_valid_buf16 === 1'b1) begin
    combined_data = {dut.inst_stage_wb.store_data_line_1, dut.inst_stage_wb.store_data_line_0};
    combined_mask = {dut.inst_stage_wb.to_wb_store_mask_line_1, dut.inst_stage_wb.to_wb_store_mask_line_0};
    for (n = 0; n < 32; n = n + 1) begin
      if (combined_mask[n] === 1'b0) begin
        if (pend_mem_cnt < MAX_PENDING_MEM) begin
          pend_mem_is_wr[pend_mem_cnt] = 1'b1;
          pend_mem_val  [pend_mem_cnt] = (combined_data >> (8*n)) & 8'hFF;
          pend_mem_va   [pend_mem_cnt] = {saved_st_addr[31:4], 4'd0} + n;
          pend_mem_pa   [pend_mem_cnt] = {dut.inst_stage_wb.to_wb_store_addr_line_0[14:4], 4'd0} + n;
          if (n >= 16) 
            pend_mem_pa   [pend_mem_cnt] = {dut.inst_stage_wb.to_wb_store_addr_line_1[14:4], 4'd0} + (n-16);
          pend_mem_oeip [pend_mem_cnt] = dut.to_wb_oeip;
          pend_mem_cnt = pend_mem_cnt + 1;
        end
      end
    end
  end
end


integer cur_test;
reg        stream_done;
reg [31:0] accepted_cnt;
reg [31:0] stalled_cnt;

dummy_fe dut_fe(
  .clk(clk),
  .rst_n(rst_n),
  .from_rr_stall(from_rr_stall),
  .from_ex_flush(from_ex_flush),
  .from_ex_eip_target(from_ex_eip_target),
  .to_de_outbytes(to_de_outbytes),
  .to_de_valid(to_de_valid),
  .from_de_prefix(from_de_prefix),
  .from_de_opcode(from_de_opcode),
  .from_de_modrm(from_de_modrm),
  .from_de_sib(from_de_sib),
  .from_de_disp(from_de_disp),
  .from_de_dispsize(from_de_dispsize),
  .from_de_imm(from_de_imm),
  .from_de_imm_size(from_de_imm_size),
  .from_de_addr_mode(from_de_addr_mode),
  .from_de_oeip(from_de_oeip),
  .from_de_ieip(from_de_ieip),
  .from_de_pred_eip(from_de_pred_eip),
  .from_de_exception(from_de_exception),
  .from_de_valid(from_de_valid)
);

dummy_fe_to_be dut_fe_to_be(
  .clk(clk),
  .rst_n(rst_n),
  .from_rr_stall(from_rr_stall),
  .from_ex_flush(from_ex_flush),
  .from_wb_flush(from_wb_flush),
  .from_de_prefix(from_de_prefix),
  .from_de_opcode(from_de_opcode),
  .from_de_modrm(from_de_modrm),
  .from_de_sib(from_de_sib),
  .from_de_disp(from_de_disp),
  .from_de_dispsize(from_de_dispsize),
  .from_de_imm(from_de_imm),
  .from_de_imm_size(from_de_imm_size),
  .from_de_addr_mode(from_de_addr_mode),
  .from_de_oeip(from_de_oeip),
  .from_de_ieip(from_de_ieip),
  .from_de_pred_eip(from_de_pred_eip),
  .from_de_exception(from_de_exception),
  .from_de_valid(from_de_valid),

  .to_rr_prefix(to_rr_prefix),
  .to_rr_opcode(to_rr_opcode),
  .to_rr_modrm(to_rr_modrm),
  .to_rr_sib(to_rr_sib),
  .to_rr_disp(to_rr_disp),
  .to_rr_dispsize(to_rr_dispsize),
  .to_rr_imm(to_rr_imm),
  .to_rr_imm_size(to_rr_imm_size),
  .to_rr_addr_mode(to_rr_addr_mode),
  .to_rr_oeip(to_rr_oeip),
  .to_rr_ieip(to_rr_ieip),
  .to_rr_pred_eip(to_rr_pred_eip),
  .to_rr_exception(to_rr_exception),
  .to_rr_valid(to_rr_valid)
);

task drive_testcase;
  input integer idx;
begin
  to_de_outbytes   = mem_in[idx];
  to_de_valid      = 1'b1;
end
endtask

task drive_idle;
begin
  to_de_outbytes   = {128{1'bz}};
  to_de_valid      = 1'b0;
end
endtask

function integer find_idx_from_eip_filemap;
  input [31:0] target_eip;
  integer fi;
  begin
    find_idx_from_eip_filemap = -1;
    for (fi = 0; fi < map_count; fi = fi + 1) begin
      if (map_eip[fi] == target_eip) begin
        find_idx_from_eip_filemap = map_idx[fi];
      end
    end
  end
endfunction


reg        testcase_seen [0:NUM_TESTS_MEM-1];
reg [31:0] testcase_oeip [0:NUM_TESTS_MEM-1];
reg [31:0] testcase_ieip [0:NUM_TESTS_MEM-1];

function integer find_idx_from_eip;
  input [31:0] target_eip;
  integer fi;
  begin
    find_idx_from_eip = -1;
    for (fi = 0; fi < NUM_TESTS_MEM; fi = fi + 1) begin
      if (testcase_seen[fi] && (testcase_oeip[fi] == target_eip))
        find_idx_from_eip = fi;
    end
  end
endfunction

task run_test_stream;
  integer drain_cycles;
  integer redirect_idx;
begin
  cur_test     = 0;
  accepted_cnt = 0;
  stalled_cnt  = 0;
  stream_done  = 1'b0;

  @(posedge clk);
  if (cur_test < NUM_TESTS_MEM)
    drive_testcase(cur_test);
  else
    drive_idle();

  while (!stream_done) begin
    @(posedge clk);

    // --------------------------------------------------------
    // Highest priority: EX flush redirects FE immediately
    // --------------------------------------------------------
    if (from_ex_flush) begin
      redirect_idx = find_idx_from_eip_filemap(from_ex_eip_target);

      if (redirect_idx >= 0) begin
        cur_test = redirect_idx;

        // optional debug
        // $display("[FLUSH-REDIRECT] target_eip=%08x -> idx=%0d time=%0t",
        //          from_ex_eip_target, redirect_idx, $time);

        drive_testcase(cur_test);
      end else begin
        $display("[FLUSH-ERROR] cannot find testcase for target_eip=%08x at time=%0t",
                 from_ex_eip_target, $time);
        $finish;
      end
    end

    // --------------------------------------------------------
    // Normal FE->RR accept
    // --------------------------------------------------------
    else if (!from_rr_stall) begin
      accepted_cnt = accepted_cnt + 1;

      // Record mapping the first time this testcase is accepted
      if (!testcase_seen[cur_test]) begin
        testcase_seen[cur_test] = 1'b1;
        testcase_oeip[cur_test] = from_de_oeip;
        testcase_ieip[cur_test] = from_de_ieip;
      end

      // optional debug
      // $display("[ACCEPT] idx=%0d oeip=%08x ieip=%08x time=%0t",
      //          cur_test, from_de_oeip, from_de_ieip, $time);

      cur_test = cur_test + 1;

      if (cur_test >= NUM_TESTS_MEM) begin
        stream_done = 1'b1;
        drive_idle();
      end else begin
        drive_testcase(cur_test);
      end
    end

    // --------------------------------------------------------
    // Frontend stalled: keep driving same testcase
    // --------------------------------------------------------
    else if (to_rr_valid && from_rr_stall) begin
      stalled_cnt = stalled_cnt + 1;

      // optional debug
      // $display("[STALL] idx=%0d oeip=%08x time=%0t",
      //          cur_test, from_de_oeip, $time);

      drive_testcase(cur_test);
    end

    else begin
      drive_testcase(cur_test);
    end
  end

  for (drain_cycles = 0; drain_cycles < 30; drain_cycles = drain_cycles + 1)
    @(posedge clk);

  $display("accepted_cnt = %0d", accepted_cnt);
  $display("stalled_cnt  = %0d", stalled_cnt);
end
endtask

reg wb_commit_pending;
reg [31:0] wb_commit_ieip;
reg [31:0] wb_commit_oeip;
reg [31:0] wb_commit_eflags;

always @(posedge clk) begin
  if (!rst_n) begin
    wb_commit_pending <= 1'b0;
    wb_commit_ieip    <= 32'b0;
    wb_commit_oeip    <= 32'b0;
    wb_commit_eflags  <= 32'b0;
    arch_snap_valid   <= 1'b0;
    pend_mem_cnt      = 0;
  end else begin
    // wait until the next cycle of the wb commit
    #1;
    if (wb_commit_pending) begin
      if (!arch_snap_valid) begin
        // first commit, only take a snapshot
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end else if (arch_snap_oeip == wb_commit_oeip) begin
        // if it's the same ieip, it's the same instruction
        // only update snapshot, don't print
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end else begin
        // if ieip changes, it means the rep has ended
        // $display("[ARCH COMMIT] time=%0t ieip=%08x", $time, arch_snap_ieip);
        print_arch_snapshot(0);
        NUM_TESTS = NUM_TESTS + 1;

        // start recording new instructions
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end
    end

    wb_commit_pending <= 1'b0;

    // check if there's new commit, latch it to next cycle
    if (dut.inst_stage_wb.to_wb_valid_buf16 && dut.inst_stage_wb.no_exception) begin
      wb_commit_pending <= 1'b1;
      wb_commit_ieip    <= dut.to_wb_ieip;
      wb_commit_oeip    <= dut.to_wb_oeip;
      wb_commit_eflags  <= dut.inst_stage_ex.eflags_out;
    end
  end
end

integer j;
integer file_handle_cmp;
integer map_i;
initial begin 
  TEST_CASE_NEW_CHAR         <= 8'd0;
  TEST_CASE_NEW_CHAR_WR      <= 8'd0;
  TEST_CASE_NEW_READY        <= 1'b0;
  TEST_CASE_NEW_READY_WR     <= 1'b0;
  clk = 1'b1;
  rst_n = 1'b0;
  file_handle_cmp = $fopen("/home/ecelrc/students/aak3265/MICROARCH/project/hvl/top/backend_top/backend_top_tb/results_cmp.txt", "w");
  if (file_handle_cmp == 0) begin
    $display("Error: Failed to open results_cmp.txt!");
  end
  clear_inputs();
  load_eip_idx_map("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/program_eip_idx_map.txt");

  for (map_i = 0; map_i < NUM_TESTS_MEM; map_i = map_i + 1) begin
    testcase_seen[map_i] = 1'b0;
    testcase_oeip[map_i] = 32'b0;
    testcase_ieip[map_i] = 32'b0;
  end


  @(posedge clk);
  @(posedge clk);
  rst_n = 1'b1;
  
  // print_arch_status();

  // Iterate through all tests
  // for (j = 0; j < NUM_TESTS_MEM; j = j + 1) begin
  //     test_with_nops(j);
  // end

  run_test_stream();
  #(30 * CYCLE_TIME);
                  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

// initial begin 
//   #(5000 * CYCLE_TIME);
//   $finish;
// end

// Auto-generated memory initialization (Verilog-2005)

initial begin
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
end


endmodule