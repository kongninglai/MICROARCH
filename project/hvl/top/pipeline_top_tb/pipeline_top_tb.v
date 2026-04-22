module pipeline_top_tb;

// initial begin
//   // $vcdplusfile("pipeline_top_tb.dump.vpd");
//   // $vcdpluson(0, pipeline_top_tb); 
// end

integer i;
integer NUM_TESTS = 0;
integer FAILURES  = 0;
integer SUCCESSES = 0;

`ifdef AUTO_CHECKER
integer auto_checker_rc;
reg auto_checker_ready;
reg auto_checker_done;
`endif

localparam CYCLE_TIME_X10 = 160;
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

wire [6:0] fe_to_rr_prefix;
assign to_rr_prefix = fe_to_rr_prefix;

wire [19:0]  ITLB_VPN;
wire [2:0]   ITLB_PFN_OUT;
wire         ITLB_PAGE_FAULT_OUT;

wire         ICACHE_VALID;
wire [127:0] ICACHE_HIT_DATA;
wire [11:0]  F_PAGE_OFFSET;

wire [15:0]  from_rr_cs;
wire         from_ex_ld_cs;
wire [3:0]   from_ex_pht_idx;
wire [31:0]  to_pr_pred_eip;

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

assign from_rr_cs = from_regunit_CS;
assign from_ex_ld_cs = 1'b0;
assign from_ex_pht_idx = 4'd0;

reg [31:0] wb_ieip;
reg [31:0] wb_eflags;

integer dbg_fetch_en;
integer dbg_cycle;
reg dbg_seen_icache_valid;
reg dbg_seen_to_rr_valid;
reg dbg_seen_itlb_pf;
reg dbg_seen_icache_x;

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
  .DCACHE_STALL_UNCOND_BAR(DCACHE_STALL_UNCOND_BAR),
  .DCACHE_STALL_IF_MEM_BAR(DCACHE_STALL_IF_MEM_BAR),

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
  .ITLB_VPN(ITLB_VPN),
  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_WRITE_DISABLE_OUT(),
  .ITLB_CACHE_ENABLE_OUT(),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

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

task clear_inputs;
begin
  to_de_outbytes = {128{1'b0}};
  to_de_valid = 1'b0;
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/gen_testcases.mem", mem_in);
end
endtask

always @(posedge clk) begin
  if (!rst_n) begin
    dbg_cycle <= 0;
    dbg_seen_icache_valid <= 1'b0;
    dbg_seen_to_rr_valid <= 1'b0;
    dbg_seen_itlb_pf <= 1'b0;
    dbg_seen_icache_x <= 1'b0;
  end else if (dbg_fetch_en) begin
    dbg_cycle <= dbg_cycle + 1;

    if ((dbg_cycle % 5000) == 0) begin
      $display("[FETCH-DBG] cyc=%0d ITLB_VPN=%05h ITLB_PFN=%0h PF=%0b ICV=%0b RRV=%0b STALL=%0b IEIP=%08h",
               dbg_cycle, ITLB_VPN, ITLB_PFN_OUT, ITLB_PAGE_FAULT_OUT,
               ICACHE_VALID, to_rr_valid, from_rr_stall, to_rr_ieip);
    end

    if (ICACHE_VALID && !dbg_seen_icache_valid) begin
      dbg_seen_icache_valid <= 1'b1;
      $display("[FETCH-DBG] first ICACHE_VALID at cyc=%0d IEIP=%08h F_PAGE_OFFSET=%03h",
               dbg_cycle, to_rr_ieip, F_PAGE_OFFSET);
    end

    if (to_rr_valid && !dbg_seen_to_rr_valid) begin
      dbg_seen_to_rr_valid <= 1'b1;
      $display("[FETCH-DBG] first to_rr_valid at cyc=%0d IEIP=%08h OPCODE=%02h",
               dbg_cycle, to_rr_ieip, to_rr_opcode);
    end

    if (ITLB_PAGE_FAULT_OUT && !dbg_seen_itlb_pf) begin
      dbg_seen_itlb_pf <= 1'b1;
      $display("[FETCH-DBG] ITLB page fault asserted at cyc=%0d VPN=%05h",
               dbg_cycle, ITLB_VPN);
    end

    if (ICACHE_VALID && (^ICACHE_HIT_DATA === 1'bx) && !dbg_seen_icache_x) begin
      dbg_seen_icache_x <= 1'b1;
      $display("[FETCH-DBG] ICACHE_VALID with X data at cyc=%0d", dbg_cycle);
    end
  end
end



reg [31:0] saved_st_addr;
reg [255:0] combined_data;
reg [31:0] combined_mask;
reg [31:0] saved_ieip, halt_ieip;

// Pending Read/Wrote buffer: each entry tagged with the ieip of the instruction
localparam MAX_PENDING_MEM = 128;
reg        pend_mem_is_wr [0:MAX_PENDING_MEM-1]; // 0=Read, 1=Wrote
reg [7:0]  pend_mem_val   [0:MAX_PENDING_MEM-1];
reg [31:0] pend_mem_va    [0:MAX_PENDING_MEM-1];
reg [15:0] pend_mem_pa    [0:MAX_PENDING_MEM-1];
reg [31:0] pend_mem_oeip  [0:MAX_PENDING_MEM-1]; // which instruction this belongs to
integer    pend_mem_cnt;


reg        arch_snap_valid;
reg [31:0] arch_snap_oeip;
reg [31:0] arch_snap_ieip;
reg [31:0] arch_snap_eflags;
reg [31:0] arch_snap_gpr [0:7];
reg [63:0] arch_snap_mmx [0:7];
reg [15:0] arch_snap_seg [0:4];
reg [15:0] arch_snap_cs;

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

  // IMPORTANT: Make sure `dut.inst_regunit...` matches your actual pipeline hierarchy!
  // If your regunit is inside a backend wrapper, it might be `dut.backend.inst_regunit...`
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


integer flush_i;
// Print and remove all pending entries whose oeip matches the given oeip
task flush_pending_for_oeip;
  input [31:0] target_oeip;
  integer fi, new_cnt;
begin
  // First pass: print matching entries
  for (fi = 0; fi < pend_mem_cnt; fi = fi + 1) begin
    if (pend_mem_oeip[fi] === target_oeip) begin
      if (pend_mem_is_wr[fi] === 1'b0)
        // EXACT FORMATTING FOR READS
        $fdisplay(file_handle_cmp,"Read  0x%02x from va = 0x%08x and pa = 0x%04x",
          pend_mem_val[fi], pend_mem_va[fi], pend_mem_pa[fi]);
      else
        // EXACT FORMATTING FOR WRITES
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

task print_arch_status;
  input integer is_hlt_status;
begin
  flush_pending_for_oeip(arch_snap_oeip);
  $fdisplay(file_handle_cmp,"Architectural State %0d", NUM_TESTS);

  // ---------------- GPR ----------------
  $fdisplay(file_handle_cmp,"EAX: 0x%08X    ECX: 0x%08X    EDX: 0x%08X    EBX: 0x%08X",
           arch_snap_gpr[0],
           arch_snap_gpr[1],
           arch_snap_gpr[2],
           arch_snap_gpr[3]);

  $fdisplay(file_handle_cmp,"ESP: 0x%08X    EBP: 0x%08X    ESI: 0x%08X    EDI: 0x%08X",
           arch_snap_gpr[4],
           arch_snap_gpr[5],
           arch_snap_gpr[6],
           arch_snap_gpr[7]);

  // ---------------- MMX ----------------
  $fdisplay(file_handle_cmp,"MM0: 0x%016X               MM1: 0x%016X          ",
           arch_snap_mmx[0],
           arch_snap_mmx[1]);

  $fdisplay(file_handle_cmp,"MM2: 0x%016X               MM3: 0x%016X          ",
           arch_snap_mmx[2],
           arch_snap_mmx[3]);

  $fdisplay(file_handle_cmp,"MM4: 0x%016X               MM5: 0x%016X          ",
           arch_snap_mmx[4],
           arch_snap_mmx[5]);

  $fdisplay(file_handle_cmp,"MM6: 0x%016X               MM7: 0x%016X          ",
           arch_snap_mmx[6],
           arch_snap_mmx[7]);

  // ---------------- Segment Registers ----------------
  $fdisplay(file_handle_cmp," ES: 0x%04X CS: 0x%04X SS: 0x%04X DS: 0x%04X FS: 0x%04X GS: 0x%04X",
           arch_snap_seg[0], // ES
           arch_snap_cs,     // CS
           arch_snap_seg[1], // SS
           arch_snap_seg[2], // DS
           arch_snap_seg[3], // FS
           arch_snap_seg[4]  // GS
  );

  // ---------------- EFLAGS ----------------
  $fdisplay(file_handle_cmp," CF: %0d      PF: %0d      AF: %0d      ZF: %0d      SF: %0d      OF: %0d      DF: %0d",
           arch_snap_eflags[0],   // CF
           arch_snap_eflags[2],   // PF
           arch_snap_eflags[4],   // AF
           arch_snap_eflags[6],   // ZF
           arch_snap_eflags[7],   // SF
           arch_snap_eflags[11],  // OF
           arch_snap_eflags[10]   // DF
  );

  // ---------------- EIP ----------------
  $fdisplay(file_handle_cmp,"EIP: 0x%08X", (is_hlt_status === 1'b1 ? dut.to_rr_ieip : arch_snap_ieip));

  $fdisplay(file_handle_cmp,"----------------------------------------");
end
endtask

`ifdef AUTO_CHECKER
task run_python_golden;
begin
  auto_checker_ready = 1'b0;
  auto_checker_rc = $system("/usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/readmemh.py && /usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/gen_test_cases.py && /usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/main.py > /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/results_script.txt");
  if (auto_checker_rc == 0)
    auto_checker_ready = 1'b1;
  else begin
    FAILURES = FAILURES + 1;
    $display("AUTO_CHECKER: Failed to generate golden model output (rc=%0d)", auto_checker_rc);
  end
end
endtask

task check_results_against_golden;
begin
  if (!auto_checker_done) begin
    auto_checker_done = 1'b1;
    if (auto_checker_ready) begin
      auto_checker_rc = $system("diff /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/results_script.txt /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/results_cmp.txt > /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/diff_output.txt");
      if (auto_checker_rc == 0) begin
        SUCCESSES = SUCCESSES + 1;
        $display("PASS: RESULTS MATCH");
      end else begin
        FAILURES = FAILURES + 1;
        $display("FAIL: RESULTS MISMATCH");
        auto_checker_rc = $system("cat /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/diff_output.txt");
      end
    end else begin
      $display("AUTO_CHECKER: Skipping diff because golden output was not generated.");
    end
  end
end
endtask
`endif

integer load_iters, k, m, n, difference, starting_point;

reg handle_hlt;
initial begin
  handle_hlt = 0;
end

always @(posedge clk) begin
  
  if (!rst_n) begin 
    halt_ieip <= 32'b0;
  end else if (to_rr_opcode == 8'hF4) begin 
    halt_ieip <= to_rr_ieip;
  end
  //saved_ieip <= dut.from_wb_ieip;

  if ((dut.to_wb_ieip == halt_ieip) && dut.to_wb_valid === 1'b1 && handle_hlt == 1'b0) begin
    handle_hlt = 1;
    #(10 * CYCLE_TIME);
    print_arch_status(1);
`ifdef AUTO_CHECKER
    check_results_against_golden();
`endif
    #(CYCLE_TIME);
    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
    $finish;

  end
  if (dut.inst_stage_mem.rw_buf16[0] === 1'b1 && dut.from_mem_stall === 1'b0 && dut.inst_stage_mem.from_mem_valid === 1'b1) begin
    saved_st_addr = dut.inst_stage_mem.to_mem_st_addr;
  end
  if ((dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b0 && dut.from_mem_stall === 1'b0 && dut.inst_stage_mem.from_mem_valid === 1'b1) ||
      (dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b1 && dut.inst_stage_mem.LINE_0_LOAD_DONE === 1'b1) ||
      (dut.inst_stage_mem.rw_buf16[1] === 1'b1 && dut.inst_stage_mem.NEEDS_LINE_1_LOAD === 1'b1 && dut.inst_stage_mem.DOING_LINE_1_LOAD === 1'b1 && dut.from_mem_stall === 1'b0)) begin
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
          pend_mem_va   [pend_mem_cnt] = saved_st_addr[31:0] + m;
          pend_mem_pa   [pend_mem_cnt] = {WB_PR_ST_ADDR_L0[14:4], saved_st_addr[3:0]} + m;
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

// task test_with_nops;
//   input integer test_num;
// begin 
//   @(posedge clk);
//   to_de_outbytes = mem_in[test_num];
//   to_rr_valid = 1'b1;
//   // @(posedge clk); // updated rr_to_ag
//   #(CYCLE_TIME-2);
//   to_rr_ieip = to_rr_oeip + from_de_instr_len;
//   to_rr_pred_eip = to_rr_ieip;
//   @(posedge clk); // updated ag_to_mem
//   to_rr_valid = 1'b0;
//   to_de_outbytes = {128{1'bz}};
//   #(30 * CYCLE_TIME);
//   to_rr_oeip = to_rr_ieip;
//   print_arch_status();
//   NUM_TESTS = NUM_TESTS + 1;
//   #(CYCLE_TIME);
// end
// endtask

reg        stream_done;
reg [31:0] accepted_cnt;
reg [31:0] stalled_cnt;
localparam integer MAX_STREAM_CYCLES = 200000;

fetch_decode_top FRONTEND_TOP(
    .clk(clk),
    .rst_bar(rst_n),

    .ITLB_VPN(ITLB_VPN),
    .ITLB_PFN_OUT(ITLB_PFN_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

    .ICACHE_VALID(ICACHE_VALID),
    .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
    .F_PAGE_OFFSET(F_PAGE_OFFSET),

    //Pipeline Inputs
    .from_rr_cs(from_rr_cs),
    .from_rr_stall(from_rr_stall),

    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_eip_target(from_ex_eip_target),
    .from_ex_flush(from_ex_flush),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_pht_idx(from_ex_pht_idx),

    .from_wb_flush(from_wb_flush),

    //Outputs
    .to_rr_prefix(fe_to_rr_prefix),
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
    .to_pr_pred_eip(to_pr_pred_eip),
    .to_rr_exception(to_rr_exception),
    .to_rr_valid(to_rr_valid)
);

task run_test_stream;
  integer drain_cycles;
  integer run_cycles;
begin
  accepted_cnt = 0;
  stalled_cnt  = 0;
  stream_done  = 1'b0;
  run_cycles   = 0;

  // Real frontend flow: fetch pulls cache lines via I-TLB/I-cache.
  // Keep synthetic decode-byte drivers idle.
  to_de_outbytes = {128{1'bz}};
  to_de_valid    = 1'b0;

  while (!stream_done && run_cycles < MAX_STREAM_CYCLES) begin
    @(posedge clk);
    run_cycles = run_cycles + 1;

    if (to_rr_valid && !from_rr_stall) begin
      accepted_cnt = accepted_cnt + 1;
    end
    else if (to_rr_valid && from_rr_stall) begin
      stalled_cnt = stalled_cnt + 1;
    end

    if (dut.inst_rr.is_hlt_valid && dut.to_ag_valid === 1'b0 && dut.to_mem_valid === 1'b0 &&
        dut.to_ex_valid === 1'b0 && dut.to_wb_valid === 1'b0)
      stream_done = 1'b1;
  end

  if (stream_done) begin
    for (drain_cycles = 0; drain_cycles < 30; drain_cycles = drain_cycles + 1)
      @(posedge clk);
  end else begin
    $display("TB TIMEOUT after %0d cycles without observing HALT drain", run_cycles);
  end

  $display("run_cycles   = %0d", run_cycles);
  $display("accepted_cnt = %0d", accepted_cnt);
  $display("stalled_cnt  = %0d", stalled_cnt);
end
endtask

reg print_pending;

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
  end else begin
    #1; // wait until the next cycle of the wb commit
    
    // ----------- THE SQUISH LOGIC -----------
    if (wb_commit_pending) begin
      if (!arch_snap_valid) begin
        // First commit, only take a snapshot
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end else if (arch_snap_oeip == wb_commit_oeip) begin
        // If it's the same OEIP, it's just another micro-op for the same instruction.
        // Update the snapshot with the new state, but DO NOT print to file!
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end else begin
        // If OEIP changes, the previous macro-instruction is fully done.
        // Print the finalized snapshot to the text file.
        flush_pending_for_oeip(arch_snap_oeip);
        print_arch_status(0); 
        NUM_TESTS = NUM_TESTS + 1;

        // Start recording the new instruction's snapshot
        take_arch_snapshot(wb_commit_oeip, wb_commit_ieip, wb_commit_eflags);
      end
    end

    wb_commit_pending <= 1'b0;

    // ----------- YOUR LATCH LOGIC -----------
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

initial begin 
  TEST_CASE_NEW_CHAR         <= 8'd0;
  TEST_CASE_NEW_CHAR_WR      <= 8'd0;
  TEST_CASE_NEW_READY        <= 1'b0;
  TEST_CASE_NEW_READY_WR     <= 1'b0;
`ifdef AUTO_CHECKER
  auto_checker_ready         = 1'b0;
  auto_checker_done          = 1'b0;
`endif
  clk = 1'b1;
  rst_n = 1'b0;
  file_handle_cmp = $fopen("/home/ecelrc/students/var2427/MICROARCH/project/hvl/top/pipeline_top_tb/results_cmp.txt", "w");
  if (file_handle_cmp == 0) begin
    $display("Error: Failed to open results_cmp.txt!");
  end
  clear_inputs();
`ifdef AUTO_CHECKER
  run_python_golden();
`endif
  dbg_fetch_en = $test$plusargs("DBG_FETCH");
  @(posedge clk);
  @(posedge clk);
  rst_n = 1'b1;

  // print_arch_status(0);

  // Iterate through all tests
  // for (j = 0; j < NUM_TESTS_MEM; j = j + 1) begin
  //     test_with_nops(j);
  // end

  run_test_stream();
`ifdef AUTO_CHECKER
  check_results_against_golden();
`endif
                  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

// Auto-generated memory initialization (Verilog-2005)

initial begin
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank0_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank1_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank2_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank3_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank4_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank5_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank6_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank7_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank8_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank9_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank10_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank11_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank12_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank13_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank14_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/testcase_exception/mem_rank15_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
end


endmodule