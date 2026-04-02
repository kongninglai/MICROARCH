module stage_mem #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),
  parameter CYCLE_TIME_X10=100,
  
  parameter PHYS_LINE_BIT_WIDTH=MEM_ADDR_WIDTH-RANK_BURST_SIZE,
  parameter BYTES_PER_BUS=4,
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter VA_BIT_WIDTH=32,
  parameter PA_BIT_WIDTH=15,
  parameter PAGE_SIZE_BYTES=4096,
  parameter PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES),
  parameter VPN_BIT_WIDTH=VA_BIT_WIDTH-PAGE_BIT_WIDTH,
  parameter PFN_BIT_WIDTH=MEM_ADDR_WIDTH-PAGE_BIT_WIDTH,

  parameter TRUE_LRU=0,
  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,

  parameter NUM_ENTRIES=4,
  parameter PTR_WIDTH=$clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH=PTR_WIDTH+1,
  parameter MULTI_WRITE_AMT=2,

  parameter STORE_DATA_BIT_WIDTH=64,
  parameter STORE_DATA_BYTE_WIDTH=8,
  parameter TWO_LINES_BIT_WIDTH=2*RANK_BIT_WIDTH,
  parameter TWO_LINES_NUM_BYTES=TWO_LINES_BIT_WIDTH/8,
  parameter TWO_LINES_SHF_AMT_BIT_WIDTH=$clog2(TWO_LINES_NUM_BYTES),

  parameter NUM_GPRS=8,
  parameter GPR_ID_BIT_WIDTH=$clog2(NUM_GPRS),
  parameter GENERAL_DATA_BIT_WIDTH=32,
  parameter SEGR_DATA_BIT_WIDTH=16,
  parameter MMXR_DATA_BIT_WIDTH=64,
  parameter SLIM_BIT_WIDTH=32,

  parameter MEM_CONTROL_SIGS_BIT_WIDTH=57

) (
  input                                       clk,
  input                                       rst_n,

  /*** Inputs from pipeline registers (memory-related) ***/
  input   [MEM_CONTROL_SIGS_BIT_WIDTH-1:0]    to_mem_control_sigs,
  input   [GPR_ID_BIT_WIDTH-1:0]              to_mem_dstidA,
  input   [GPR_ID_BIT_WIDTH-1:0]              to_mem_dstidB,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_srcregA,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_srcregB,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_srcregC,
  input   [SEGR_DATA_BIT_WIDTH-1:0]           to_mem_srcSREG,
  input   [MMXR_DATA_BIT_WIDTH-1:0]           to_mem_MMA,
  input   [MMXR_DATA_BIT_WIDTH-1:0]           to_mem_MMB,
  input   [SEGR_DATA_BIT_WIDTH-1:0]           to_mem_target_cs,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_ld_addr,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_ld_offset,
  input   [SLIM_BIT_WIDTH-1:0]                to_mem_ld_slim,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_st_addr,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_st_offset,
  input   [SLIM_BIT_WIDTH-1:0]                to_mem_st_slim,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_inc_esp,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_dec_esp,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_imm,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_rel_eip,
  input   [SEGR_DATA_BIT_WIDTH-1:0]           to_mem_cs,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_oeip,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_ieip,
  input   [GENERAL_DATA_BIT_WIDTH-1:0]        to_mem_pred_eip,

  /*** Valid / exception inputs from pipeline registers ***/
  input   [1:0]                               to_mem_exception,
  input                                       to_mem_valid,

  /*** Inputs from full_cache module ***/
  input                                       DCACHE_STALL,
  input   [RANK_BIT_WIDTH-1:0]                DCACHE_HIT_DATA,

  /*** Inputs from other stages ***/
  input   [SLIM_BIT_WIDTH-1:0]                from_rr_code_segment_limit,
  input                                       from_wb_flush,
  input                                       from_ex_flush,

  /*** TLB I/Os: Note the inout behavior for D_RD_TLB_PFN_OUT, D_RD_TLB_CACHE_ENABLE_OUT ***/
  output  [VPN_BIT_WIDTH-1:0]                 D_RD_TLB_VPN,
  inout   [PFN_BIT_WIDTH-1:0]                 D_RD_TLB_PFN_OUT, 
  inout                                       D_RD_TLB_CACHE_ENABLE_OUT, 
  input                                       D_RD_TLB_PAGE_FAULT_OUT,
  output  [VPN_BIT_WIDTH-1:0]                 D_WR0_TLB_VPN,
  input   [PFN_BIT_WIDTH-1:0]                 D_WR0_TLB_PFN_OUT, 
  input                                       D_WR0_TLB_WRITE_DISABLE_OUT, 
  input                                       D_WR0_TLB_CACHE_ENABLE_OUT, 
  input                                       D_WR0_TLB_PAGE_FAULT_OUT,
  output  [VPN_BIT_WIDTH-1:0]                 D_WR1_TLB_VPN,
  input   [PFN_BIT_WIDTH-1:0]                 D_WR1_TLB_PFN_OUT, 
  input                                       D_WR1_TLB_WRITE_DISABLE_OUT,
  input                                       D_WR1_TLB_CACHE_ENABLE_OUT, 
  input                                       D_WR1_TLB_PAGE_FAULT_OUT,

  /*** Outputs to full_cache module (load-related) ***/
  /* Handled by TLB I/Os 
  output  [PFN_BIT_WIDTH-1:0]                 D_RD_TLB_PFN_OUT,
  output                                      D_RD_TLB_CACHE_ENABLE_OUT,
  */
  output  [PAGE_BIT_WIDTH-1:0]                MEM_PAGE_OFFSET,
  output                                      MEM_VALID_LOAD_INST,

  /*** Outputs to other stages in the pipeline ***/
  output                                      from_mem_stall,
  output                                      from_mem_valid_store_inst,

  /*** Outputs to pipeline registers ***/
  output  [MEM_CONTROL_SIGS_BIT_WIDTH-1-2:0]  from_mem_control_sigs,
  output  [GPR_ID_BIT_WIDTH-1:0]              from_mem_dstidA,
  output  [GPR_ID_BIT_WIDTH-1:0]              from_mem_dstidB,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_srcregA,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_srcregB,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_srcregC,
  output  [SEGR_DATA_BIT_WIDTH-1:0]           from_mem_srcSREG,
  output  [MMXR_DATA_BIT_WIDTH-1:0]           from_mem_MMA,
  output  [MMXR_DATA_BIT_WIDTH-1:0]           from_mem_MMB,
  output  [SEGR_DATA_BIT_WIDTH-1:0]           from_mem_target_cs,
  output  [STORE_DATA_BIT_WIDTH-1:0]          from_mem_load_result,

  output                                      from_mem_store_is_io_line_0,
  output  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  from_mem_store_addr_line_0,
  output  [CHIPS_PER_RANK-1:0]                from_mem_store_mask_line_0,
  output                                      from_mem_store_queue_alloc_line_0,
  output  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  from_mem_store_addr_line_1,
  output  [CHIPS_PER_RANK-1:0]                from_mem_store_mask_line_1,
  output                                      from_mem_store_queue_alloc_line_1,
  output  [TWO_LINES_SHF_AMT_BIT_WIDTH-1:0]   from_mem_store_data_shf_amt,

  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_inc_esp,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_dec_esp,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_imm,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_rel_eip,
  output  [SEGR_DATA_BIT_WIDTH-1:0]           from_mem_cs,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_oeip,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_ieip,
  output  [GENERAL_DATA_BIT_WIDTH-1:0]        from_mem_pred_eip,
  output  [1:0]                               from_mem_exception,
  output                                      from_mem_valid

);

wire to_mem_valid_buf16;
bufferH16$    bufferH16$_to_mem_valid_buf16(to_mem_valid_buf16, to_mem_valid);

/*** CONTROL SIGNALS ***/

wire ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, seg_dst_mux, rm, op_ovr, palu_size;
wire [1:0] ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux, mem_ds;
wire [2:0] ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux;
wire [3:0] gp_dsta_mux, store_data_mux;

mem_sig mem_sig_inst (
  .ucode_sig(to_mem_control_sigs),
  .ldAB(ldAB), .dstA_size(dstA_size), .dstB_size(dstB_size), .ldREGS(ldREGS),
  .ldEFLAGS(ldEFLAGS), .ldEIP(ldEIP), .ldCS(ldCS),
  .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux), .eflags_mux(eflags_mux),
  .eip_mux(eip_mux), .cs_mux(cs_mux),
  .mmx_op(mmx_op), .alu_op(alu_op), .shf_op(shf_op), .cmps(cmps), .con_jmp(con_jmp),
  .cmpxchg(cmpxchg), .cmovc(cmovc),
  .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
  .store_data_mux(store_data_mux), .rw(rw),
  .ds(ds), .mem_ds(mem_ds), .rm(rm), .op_ovr(op_ovr), .palu_size(palu_size)
);

wire [1:0] rw_buf16;
bufferH16$    bufferH16$_rw_buf16[1:0](rw_buf16, rw);

assign from_mem_control_sigs = {
    ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, seg_dst_mux,
    ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw_buf16, ds, shf_srcb_mux,
    ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux,
    gp_dsta_mux, store_data_mux, rm, op_ovr, palu_size
};

/*** TWO-CYCLE ACCESSES ***/

/* LOADS */

wire  LINE_0_LOAD_DONE, LINE_1_LOAD_DONE;
wire  NEEDS_LINE_1_LOAD, DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_BAR;
xor2$   xor2$_NEEDS_LINE_1_LOAD(NEEDS_LINE_1_LOAD, to_mem_ld_addr[RANK_BURST_SIZE], to_mem_ld_offset[RANK_BURST_SIZE]);

wire  FLUSH, FLUSH_BAR;
or2$    or2$_FLUSH(FLUSH, from_ex_flush, from_wb_flush);
nor2$   nor2$_FLUSH_BAR(FLUSH_BAR, from_ex_flush, from_wb_flush);

wire  LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR, DCACHE_STALL_BAR;
inv1$   inv1$_DCACHE_STALL_BAR(DCACHE_STALL_BAR, DCACHE_STALL);
inv1$   inv1$_DOING_LINE_1_LOAD_BAR(DOING_LINE_1_LOAD_BAR, DOING_LINE_1_LOAD);

and3$   and3$_LINE_0_LOAD_DONE(LINE_0_LOAD_DONE, DCACHE_STALL_BAR, DOING_LINE_1_LOAD_BAR, MEM_VALID_LOAD_INST);

and3$   and3$_LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR
(
  LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR,
  LINE_0_LOAD_DONE,
  NEEDS_LINE_1_LOAD,
  FLUSH_BAR
);

wire    from_mem_stall_bar;
inv1$   inv1$_from_mem_stall_bar(from_mem_stall_bar, from_mem_stall);

and3$   and3$_LINE_1_LOAD_DONE(LINE_1_LOAD_DONE, DCACHE_STALL_BAR, DOING_LINE_1_LOAD, MEM_VALID_LOAD_INST);

wire    LINE_1_LOAD_DONE_AND_MEM_STALL_BAR;
and2$   and2$_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR( LINE_1_LOAD_DONE_AND_MEM_STALL_BAR,
                                                  LINE_1_LOAD_DONE,
                                                  from_mem_stall_bar);

wire  FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR;
or4$    or4$_FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR( FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR,
                                                          FLUSH,
                                                          LINE_1_LOAD_DONE_AND_MEM_STALL_BAR,
                                                          from_mem_exception[0],
                                                          from_mem_exception[1]);

sticky_bit_load_fsm sticky_bit_load_fsm_DOING_LINE_1_LOAD (
  .rst(rst_n), 
  .clk(clk), 
  .LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR(LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR), 
  .FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR(FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR),
  .DOING_LINE_1_LOAD(DOING_LINE_1_LOAD)
);

/* STORES */

wire  NEEDS_LINE_1_STORE;
xor2$   xor2$_NEEDS_LINE_1_STORE(NEEDS_LINE_1_STORE, to_mem_st_addr[RANK_BURST_SIZE], to_mem_st_offset[RANK_BURST_SIZE]);

wire  STORE_LINE_0_EXCEPTION, STORE_LINE_1_EXCEPTION, STORE_EXCEPTION, STORE_EXCEPTION_BAR;
wire  STORE_LINE_0_EXCEPTION_COND, STORE_LINE_1_EXCEPTION_COND;

or2$    or2$_STORE_LINE_0_EXCEPTION_COND(STORE_LINE_0_EXCEPTION_COND, D_WR0_TLB_PAGE_FAULT_OUT, D_WR0_TLB_WRITE_DISABLE_OUT);
or2$    or2$_STORE_LINE_1_EXCEPTION_COND(STORE_LINE_1_EXCEPTION_COND, D_WR1_TLB_PAGE_FAULT_OUT, D_WR1_TLB_WRITE_DISABLE_OUT);

and3$   and3$_STORE_LINE_0_EXCEPTION(STORE_LINE_0_EXCEPTION, rw_buf16[0], STORE_LINE_0_EXCEPTION_COND, to_mem_valid_buf16);
and4$   and4$_STORE_LINE_1_EXCEPTION(STORE_LINE_1_EXCEPTION, rw_buf16[0], STORE_LINE_1_EXCEPTION_COND, NEEDS_LINE_1_STORE, to_mem_valid_buf16);

or2$    or2$_STORE_EXCEPTION(STORE_EXCEPTION, STORE_LINE_0_EXCEPTION, STORE_LINE_1_EXCEPTION);
nor2$   nor2$_STORE_EXCEPTION_BAR(STORE_EXCEPTION_BAR, STORE_LINE_0_EXCEPTION, STORE_LINE_1_EXCEPTION);

wire  [1:0]   STORE_EXCEPTION_MASK_LINE_0, STORE_EXCEPTION_MASK_LINE_1, STORE_EXCEPTION_MASK;

mux2$   mux2$_STORE_EXCEPTION_MASK_LINE_0[1:0]( STORE_EXCEPTION_MASK_LINE_0,
                                                2'b00,
                                                {D_WR0_TLB_WRITE_DISABLE_OUT, D_WR0_TLB_PAGE_FAULT_OUT},
                                                STORE_LINE_0_EXCEPTION);

mux2$   mux2$_STORE_EXCEPTION_MASK_LINE_1[1:0]( STORE_EXCEPTION_MASK_LINE_1,
                                                2'b00,
                                                {D_WR1_TLB_WRITE_DISABLE_OUT, D_WR1_TLB_PAGE_FAULT_OUT},
                                                STORE_LINE_1_EXCEPTION);

or2$    or2$_STORE_EXCEPTION_MASK[1:0](STORE_EXCEPTION_MASK, STORE_EXCEPTION_MASK_LINE_0, STORE_EXCEPTION_MASK_LINE_1);

/*** TLB SIGNALS ***/

/* LOADS */

wire  [GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE] to_mem_ld_addr_next_line_aligned_top;
wire  [GENERAL_DATA_BIT_WIDTH-1:0] to_mem_ld_addr_aligned, to_mem_ld_addr_next_line_aligned;

assign to_mem_ld_addr_aligned = {to_mem_ld_addr[GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0};
assign to_mem_ld_addr_next_line_aligned = {to_mem_ld_addr_next_line_aligned_top, 4'd0};

big_increment #(
  .WIDTH(GENERAL_DATA_BIT_WIDTH-RANK_BURST_SIZE)
) big_increment_to_mem_ld_addr_next_line_aligned_top (
  .a(to_mem_ld_addr[GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE]),
  .s(to_mem_ld_addr_next_line_aligned_top)
);

mux2_16$ mux2_16$_D_RD_TLB_VPN( D_RD_TLB_VPN[VPN_BIT_WIDTH-1:VPN_BIT_WIDTH-16],
                                to_mem_ld_addr_aligned[GENERAL_DATA_BIT_WIDTH-1:GENERAL_DATA_BIT_WIDTH-16],
                                to_mem_ld_addr_next_line_aligned[GENERAL_DATA_BIT_WIDTH-1:GENERAL_DATA_BIT_WIDTH-16],
                                DOING_LINE_1_LOAD);

mux2$    mux2$_D_RD_TLB_VPN[3:0]( D_RD_TLB_VPN[3:0],
                                to_mem_ld_addr_aligned[GENERAL_DATA_BIT_WIDTH-17:GENERAL_DATA_BIT_WIDTH-20],
                                to_mem_ld_addr_next_line_aligned[GENERAL_DATA_BIT_WIDTH-17:GENERAL_DATA_BIT_WIDTH-20],
                                DOING_LINE_1_LOAD);

wire  [CHIPS_PER_RANK-1:0] MEM_PAGE_OFFSET_DUMMY;

mux2_16$ mux2_16$_MEM_PAGE_OFFSET (MEM_PAGE_OFFSET_DUMMY, {4'd0, to_mem_ld_addr_aligned[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0},
                                                          {4'd0, to_mem_ld_addr_next_line_aligned[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0}, 
                                                          DOING_LINE_1_LOAD);

assign MEM_PAGE_OFFSET = MEM_PAGE_OFFSET_DUMMY[PAGE_BIT_WIDTH-1:0];

/* STORES */

wire  [GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE] to_mem_st_addr_next_line_aligned_top;
wire  [GENERAL_DATA_BIT_WIDTH-1:0] to_mem_st_addr_aligned, to_mem_st_addr_next_line_aligned;

assign to_mem_st_addr_aligned = {to_mem_st_addr[GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE], 4'd0};
assign to_mem_st_addr_next_line_aligned = {to_mem_st_addr_next_line_aligned_top, 4'd0};

big_increment #(
  .WIDTH(GENERAL_DATA_BIT_WIDTH-RANK_BURST_SIZE)
) big_increment_to_mem_st_addr_next_line_aligned_top (
  .a(to_mem_st_addr[GENERAL_DATA_BIT_WIDTH-1:RANK_BURST_SIZE]),
  .s(to_mem_st_addr_next_line_aligned_top)
);

assign D_WR0_TLB_VPN = to_mem_st_addr_aligned[GENERAL_DATA_BIT_WIDTH-1:GENERAL_DATA_BIT_WIDTH-VPN_BIT_WIDTH];
assign D_WR1_TLB_VPN = to_mem_st_addr_next_line_aligned[GENERAL_DATA_BIT_WIDTH-1:GENERAL_DATA_BIT_WIDTH-VPN_BIT_WIDTH];

/*** TLB OUTPUTS and MEM_VALID_LOAD_INST and EXCEPTIONS ***/

wire  D_RD_TLB_PAGE_FAULT_OUT_BAR, LOAD_EXCEPTION;
inv1$   inv1$_D_RD_TLB_PAGE_FAULT_OUT_BAR(D_RD_TLB_PAGE_FAULT_OUT_BAR, D_RD_TLB_PAGE_FAULT_OUT);
and3$   and3$_LOAD_EXCEPTION(LOAD_EXCEPTION, D_RD_TLB_PAGE_FAULT_OUT, rw_buf16[1], to_mem_valid_buf16);

wire  [1:0] LOAD_EXCEPTION_MASK;
assign  LOAD_EXCEPTION_MASK = {1'b0, LOAD_EXCEPTION};

/* LIMIT CHECKING */

wire  ld_slim_violation, st_slim_violation, eip_slim_violation;

cmp_gt_32b cmp_gt_32b_ld_slim_violation (
  .in0(to_mem_ld_offset[SLIM_BIT_WIDTH-1:0]), .in1(to_mem_ld_slim),
	.gt(ld_slim_violation)
);

cmp_gt_32b cmp_gt_32b_st_slim_violation (
  .in0(to_mem_st_offset[SLIM_BIT_WIDTH-1:0]), .in1(to_mem_st_slim),
	.gt(st_slim_violation)
);

wire  [VA_BIT_WIDTH-1:0]  maximum_eip_accessed;

big_decrement #(
  .WIDTH(VA_BIT_WIDTH)
) big_decrement_maximum_eip_accessed (
  .a(to_mem_ieip),
  .s(maximum_eip_accessed)
);

cmp_gt_32b cmp_gt_32b_eip_slim_violation (
  .in0(maximum_eip_accessed), .in1(from_rr_code_segment_limit),
	.gt(eip_slim_violation)
);

/* Other case: Cross Segment Boundary if addr[19] = 1 and offset[19] = 0 */

wire  ld_seg_boundary_violation, st_seg_boundary_violation, eip_seg_boundary_violation;

wire  to_mem_ld_addr_bit_19_BAR;
inv1$   inv1$_to_mem_ld_addr_bit_19_BAR(to_mem_ld_addr_bit_19_BAR, to_mem_ld_addr[19]);
nor2$   nor2$_ld_seg_boundary_violation(ld_seg_boundary_violation, to_mem_ld_addr_bit_19_BAR, to_mem_ld_offset[19]);

wire  to_mem_st_addr_bit_19_BAR;
inv1$   inv1$_to_mem_st_addr_bit_19_BAR(to_mem_st_addr_bit_19_BAR, to_mem_st_addr[19]);
nor2$   nor2$_st_seg_boundary_violation(st_seg_boundary_violation, to_mem_st_addr_bit_19_BAR, to_mem_st_offset[19]);

wire  maximum_eip_accessed_bit_19_BAR;
inv1$   inv1$_maximum_eip_accessed_bit_19_BAR(maximum_eip_accessed_bit_19_BAR, maximum_eip_accessed[19]);
nor2$   nor2$_eip_seg_boundary_violation(eip_seg_boundary_violation, maximum_eip_accessed_bit_19_BAR, to_mem_oeip[19]);

/* Combine limit violations */

wire  ld_gen_limit_violation, st_gen_limit_violation, eip_gen_limit_violation;

or2$  or2$_ld_gen_limit_violation(ld_gen_limit_violation, ld_slim_violation, ld_seg_boundary_violation);
or2$  or2$_st_gen_limit_violation(st_gen_limit_violation, st_slim_violation, st_seg_boundary_violation);
or2$  or2$_eip_gen_limit_violation(eip_gen_limit_violation, eip_slim_violation, eip_seg_boundary_violation);

wire  [1:0]   ld_slim_exception_mask, st_slim_exception_mask, eip_slim_exception_mask, combined_slim_exception_mask;

assign ld_slim_exception_mask[0] = 1'b0;
assign st_slim_exception_mask[0] = 1'b0;
assign eip_slim_exception_mask[0] = 1'b0;

and3$   and3$_ld_slim_exception_mask(ld_slim_exception_mask[1], ld_gen_limit_violation, rw_buf16[1], to_mem_valid_buf16);
and3$   and3$_st_slim_exception_mask(st_slim_exception_mask[1], st_gen_limit_violation, rw_buf16[0], to_mem_valid_buf16);
and2$   and2$_eip_slim_exception_mask(eip_slim_exception_mask[1], eip_gen_limit_violation, to_mem_valid_buf16);

or3$    or3$_combined_slim_exception_mask[1:0](combined_slim_exception_mask, ld_slim_exception_mask, st_slim_exception_mask, eip_slim_exception_mask);

or4$    or4$_from_mem_exception[1:0](from_mem_exception, LOAD_EXCEPTION_MASK, STORE_EXCEPTION_MASK, combined_slim_exception_mask, to_mem_exception);

wire  no_mem_exception, no_mem_exception_buf16;
nor2$   nor2$_no_mem_exception(no_mem_exception, from_mem_exception[0], from_mem_exception[1]);
bufferH16$    bufferH16$_no_mem_exception_buf16(no_mem_exception_buf16, no_mem_exception);
and2$   and2$_MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST, rw_buf16[1], to_mem_valid_buf16);


/*** STORE PIPELINE REGISTERS ***/

wire  D_WR0_TLB_CACHE_ENABLE_OUT_BAR;
inv1$   inv1$_D_WR0_TLB_CACHE_ENABLE_OUT_BAR(D_WR0_TLB_CACHE_ENABLE_OUT_BAR, D_WR0_TLB_CACHE_ENABLE_OUT);
and4$   and4$_from_mem_store_is_io_line_0(from_mem_store_is_io_line_0, D_WR0_TLB_CACHE_ENABLE_OUT_BAR, to_mem_valid_buf16, no_mem_exception_buf16, rw_buf16[0]);
and4$   and4$_from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0, D_WR0_TLB_CACHE_ENABLE_OUT, to_mem_valid_buf16, no_mem_exception_buf16, rw_buf16[0]);

wire  from_mem_store_queue_alloc_line_1_int;
and4$   and4$_from_mem_store_queue_alloc_line_1_int(from_mem_store_queue_alloc_line_1_int, D_WR1_TLB_CACHE_ENABLE_OUT, to_mem_valid_buf16, no_mem_exception_buf16, rw_buf16[0]);
and2$   and2$_from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1, from_mem_store_queue_alloc_line_1_int, NEEDS_LINE_1_STORE);

and3$   and3$_from_mem_valid_store_inst(from_mem_valid_store_inst, to_mem_valid_buf16, no_mem_exception_buf16, rw_buf16[0]);

assign from_mem_store_addr_line_0 = {D_WR0_TLB_PFN_OUT, to_mem_st_addr_aligned[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE]};
assign from_mem_store_addr_line_1 = {D_WR1_TLB_PFN_OUT, to_mem_st_addr_next_line_aligned[PAGE_BIT_WIDTH-1:RANK_BURST_SIZE]};

wire    [MULTI_WRITE_AMT*CHIPS_PER_RANK-1:0]  concat_store_mask_buf64, shifted_combined_store_mask, final_combined_store_mask;
wire    [STORE_DATA_BYTE_WIDTH-1:0]           starting_combined_store_mask;

mux4_8$   mux4_8$_starting_combined_store_mask( starting_combined_store_mask,
                                                8'h01,
                                                8'h03,
                                                8'h0F,
                                                8'hFF,
                                                mem_ds[0],
                                                mem_ds[1]);

bufferH64$    bufferH64$_concat_store_mask_buf64[MULTI_WRITE_AMT*CHIPS_PER_RANK-1:0](concat_store_mask_buf64, {24'd0, starting_combined_store_mask});

lshf_var_32b lshf_var_32b_shifted_combined_store_mask (
  .in(concat_store_mask_buf64),
  .shf_amt({1'b0, to_mem_st_addr[3:0]}),
  .out(shifted_combined_store_mask)
);

/* Turn into active-low write mask */
inv1$   inv1$_final_combined_store_mask[MULTI_WRITE_AMT*CHIPS_PER_RANK-1:0](final_combined_store_mask, shifted_combined_store_mask);

assign from_mem_store_mask_line_0 = final_combined_store_mask[CHIPS_PER_RANK-1:0];
assign from_mem_store_mask_line_1 = final_combined_store_mask[MULTI_WRITE_AMT*CHIPS_PER_RANK-1:CHIPS_PER_RANK];

/* This counts the number of BYTES to shift. See stage_wb.v implementation, lshf_bytes_var_256b */
assign from_mem_store_data_shf_amt = {1'b0, to_mem_st_addr[3:0]};

/*** SHIFTING / SAVING LOAD DATA LOGIC ***/

wire  [STORE_DATA_BIT_WIDTH-1:0]  SAVED_LINE_0_LOAD_DATA, SAVED_LINE_0_LOAD_DATA_buf16, LOAD_RESULT_REGULAR, LOAD_RESULT_CROSS;
wire  [RANK_BIT_WIDTH-1:0]        FULL_LOAD_RESULT_REGULAR, FULL_LOAD_RESULT_CROSS;

assign LOAD_RESULT_REGULAR = FULL_LOAD_RESULT_REGULAR[STORE_DATA_BIT_WIDTH-1:0];
assign LOAD_RESULT_CROSS = FULL_LOAD_RESULT_CROSS[STORE_DATA_BIT_WIDTH-1:0];

wire  [RANK_BIT_WIDTH-1:0] DCACHE_HIT_DATA_buf64;
bufferH64$    bufferH64$_DCACHE_HIT_DATA_buf64[RANK_BIT_WIDTH-1:0](DCACHE_HIT_DATA_buf64, DCACHE_HIT_DATA);

bufferH16$    bufferH16$_SAVED_LINE_0_LOAD_DATA_buf16[STORE_DATA_BIT_WIDTH-1:0](SAVED_LINE_0_LOAD_DATA_buf16, SAVED_LINE_0_LOAD_DATA);

reg64e$ reg64e$_SAVED_LINE_0_LOAD_DATA(
  .CLK(clk), 
  .Din(DCACHE_HIT_DATA_buf64[RANK_BIT_WIDTH-1:STORE_DATA_BIT_WIDTH]), 
  .Q(SAVED_LINE_0_LOAD_DATA), 
  .QBAR(), 
  .CLR(rst_n), 
  .PRE(1'b1),
  .en(LINE_0_LOAD_DONE)
);

wire  [3:0]   to_mem_ld_addr_line_offset_adjusted;

PA_4b PA_4b_to_mem_ld_addr_line_offset_adjusted (
  .in0(to_mem_ld_addr[3:0]), .in1(4'b1000),
	.s(to_mem_ld_addr_line_offset_adjusted)
);

rshf_bytes_var_128b rshf_bytes_var_128b_FULL_LOAD_RESULT_REGULAR (
  .in(DCACHE_HIT_DATA_buf64),
  .shf_amt(to_mem_ld_addr[3:0]),
  .out(FULL_LOAD_RESULT_REGULAR)
);

rshf_bytes_var_128b rshf_bytes_var_128b_FULL_LOAD_RESULT_CROSS (
  .in({DCACHE_HIT_DATA_buf64[STORE_DATA_BIT_WIDTH-1:0], SAVED_LINE_0_LOAD_DATA_buf16}),
  .shf_amt(to_mem_ld_addr_line_offset_adjusted),
  .out(FULL_LOAD_RESULT_CROSS)
);

genvar i;
generate
  for (i = 0; i < STORE_DATA_BIT_WIDTH / 16; i = i + 1) begin : mux2_16_load_result_gen
    mux2_16$    mux2_16$_from_mem_load_result(
      from_mem_load_result[i*16 +: 16],
      LOAD_RESULT_REGULAR[i*16 +: 16],
      LOAD_RESULT_CROSS[i*16 +: 16],
      DOING_LINE_1_LOAD
    );
  end
endgenerate

/*** VALID AND STALL ***/

and2$   and2$_from_mem_valid(from_mem_valid, from_mem_stall_bar, to_mem_valid_buf16);

wire  STALL_REASON_0, STALL_REASON_1;

and2$   and2$_STALL_REASON_0(STALL_REASON_0, MEM_VALID_LOAD_INST, DCACHE_STALL);
and3$   and3$_STALL_REASON_1(STALL_REASON_1, MEM_VALID_LOAD_INST, NEEDS_LINE_1_LOAD, DOING_LINE_1_LOAD_BAR);

or2$    or2$_from_mem_stall(from_mem_stall, STALL_REASON_0, STALL_REASON_1);

/*** EASY ASSIGN STATEMENTS ***/

assign from_mem_dstidA      = to_mem_dstidA   ;  
assign from_mem_dstidB      = to_mem_dstidB   ;  
assign from_mem_srcregA     = to_mem_srcregA  ;    
assign from_mem_srcregB     = to_mem_srcregB  ;    
assign from_mem_srcregC     = to_mem_srcregC  ;    
assign from_mem_srcSREG     = to_mem_srcSREG  ;    
assign from_mem_MMA         = to_mem_MMA      ;
assign from_mem_MMB         = to_mem_MMB      ;
assign from_mem_target_cs   = to_mem_target_cs;      

assign from_mem_inc_esp     = to_mem_inc_esp ;     
assign from_mem_dec_esp     = to_mem_dec_esp ;     
assign from_mem_imm         = to_mem_imm     ; 
assign from_mem_rel_eip     = to_mem_rel_eip ;     
assign from_mem_cs          = to_mem_cs      ; 
assign from_mem_oeip        = to_mem_oeip    ;   
assign from_mem_ieip        = to_mem_ieip    ;   
assign from_mem_pred_eip    = to_mem_pred_eip;

endmodule