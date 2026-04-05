module backend_top #(
  parameter CYCLE_TIME_X10=98,
  parameter TRUE_LRU=1
) (
    input clk,
    input rst_n,

    input [6:0] to_rr_prefix,
    input [7:0] to_rr_opcode,
    input [7:0] to_rr_modrm,
    input [7:0] to_rr_sib,
    input [31:0] to_rr_disp,
    input [1:0] to_rr_dispsize,
    input [47:0] to_rr_imm,
    input [2:0] to_rr_imm_size,
    input [1:0] to_rr_addr_mode,
    input [31:0] to_rr_oeip,
    input [31:0] to_rr_ieip,
    input [31:0] to_rr_pred_eip,
    input [1:0] to_rr_exception,
    input to_rr_valid,

    /*** To FRONTEND ***/
    output from_rr_stall,
    output [31:0] from_regunit_cs_limit,
    output from_ex_flush,
    output from_ex_br_t_nt,
    output from_ex_br_valid,
    output [31:0] from_ex_eip_target,

    output from_wb_flush,

    /*** TO/FROM TLB AND FULL CACHE ***/
    /* D$ Control */
    input           DCACHE_STALL,
    input   [127:0] DCACHE_HIT_DATA,
    input           DCACHE_HIT,
    input           WBE_BUSY,

    /* DMA Interrupt */
    input           DMA_INT,

    /* Outputs to D$ to help with lookup */
    output  [11:0]  MEM_PAGE_OFFSET,
    output          MEM_VALID_LOAD_INST,

    /* Outputs for I/O stores which bypass cache */
    output  [14:4]  WB_PR_ST_ADDR_L0,
    output  [15:0]  WB_PR_ST_MASK_L0,
    output  [127:0] WB_SHF_ST_DATA_L0,
    output          WB_VALID_IO_STORE_INST,

    /* Outputs to D$ to help with stores */
    output          STOREQ_STORING,
    output          STOREQ_LAST_ENTRY,
    output  [127:0] STOREQ_DATA,
    output  [15:0]  STOREQ_DATA_WR_MASK,
    output  [14:4]  STOREQ_PHYS_ADDR,

    /* I/Os to TLB for load address translations */
    output  [19:0]  D_RD_TLB_VPN,
    input   [2:0]   D_RD_TLB_PFN_OUT,
    input           D_RD_TLB_CACHE_ENABLE_OUT,
    input           D_RD_TLB_PAGE_FAULT_OUT,

    /*  I/Os to TLB for store address translations
        stores can cross cache lines */
    output  [19:0]  D_WR0_TLB_VPN,
    input   [2:0]   D_WR0_TLB_PFN_OUT,
    input           D_WR0_TLB_WRITE_DISABLE_OUT,
    input           D_WR0_TLB_CACHE_ENABLE_OUT,
    input           D_WR0_TLB_PAGE_FAULT_OUT,

    output  [19:0]  D_WR1_TLB_VPN,
    input   [2:0]   D_WR1_TLB_PFN_OUT,
    input           D_WR1_TLB_WRITE_DISABLE_OUT,
    input           D_WR1_TLB_CACHE_ENABLE_OUT,
    input           D_WR1_TLB_PAGE_FAULT_OUT
); 
    /*** RR OUTPUT ***/
    wire [7:0]      to_regunit_opcode;
    wire [5:0]      to_regunit_modrm;
    wire [5:0]      to_regunit_sib;
    wire            to_regunit_has_sib;
    wire [1:0]      to_regunit_sig_gprd0_mux;
    wire            to_regunit_sig_gprd1_mux;
    wire [1:0]      to_regunit_sig_gprd2_mux;
    wire            to_regunit_sig_srcregA_mux;
    wire            to_regunit_sig_srcregB_mux;
    wire [1:0]      to_regunit_sig_ds;
    
    wire            to_regunit_sig_srcsreg_mux;
    wire            to_regunit_sig_segrd0_mux;
    wire            to_regunit_sig_segrd1_mux;
    wire [2:0]      to_regunit_seg_prefix;
    wire            to_regunit_has_seg_prefix;
    
    wire [64:0]     from_rr_control_sigs;
    wire [2:0]      from_rr_dstidA;
    wire [2:0]      from_rr_dstidB;
    wire [31:0]     from_rr_srcregA;
    wire [31:0]     from_rr_srcregB;
    wire [31:0]     from_rr_srcregC;
    wire [15:0]     from_rr_srcSREG;
    wire [63:0]     from_rr_MMA;
    wire [63:0]     from_rr_MMB;
    wire [31:0]     from_rr_imm;
    wire [15:0]     from_rr_sreg1;
    wire [31:0]     from_rr_slim1;
    wire [31:0]     from_rr_base1;
    wire [31:0]     from_rr_index1;
    wire [31:0]     from_rr_disp;
    wire [1:0]      from_rr_scale_mux;
    wire [15:0]     from_rr_sreg2;
    wire [31:0]     from_rr_slim2;
    wire [31:0]     from_rr_base2;
    wire [3:0]      from_rr_intex_vec;
    wire [15:0]     from_rr_cs;
    wire [31:0]     from_rr_oeip;
    wire [31:0]     from_rr_ieip;
    wire [31:0]     from_rr_pred_eip;
    wire [1:0]      from_rr_exception;
    wire            from_rr_valid;
    wire            from_rr_we_pipe_reg;
    // wire            from_rr_stall;

    wire [10:0]     to_dep_needREGS;

    /*** REGUNIT OUTPUTS ***/
    wire [15:0]     from_regunit_srcSREG;
    wire [15:0]     from_regunit_SREG1;
    wire [15:0]     from_regunit_SREG2;
    wire [31:0]     from_regunit_SLIM1;
    wire [31:0]     from_regunit_SLIM2;
    wire [15:0]     from_regunit_CS;
    wire [63:0]     from_regunit_MMA;
    wire [63:0]     from_regunit_MMB;
    wire [31:0]     from_regunit_srcregA;
    wire [31:0]     from_regunit_srcregB;
    wire [31:0]     from_regunit_srcregC;
    wire [31:0]     from_regunit_basereg1;
    wire [31:0]     from_regunit_indexreg1;
    wire [31:0]     from_regunit_basereg2;
    // wire [31:0]     from_regunit_cs_limit;

    wire [2:0]      to_dep_srcregA_idx;
    wire [2:0]      to_dep_srcregB_idx;
    wire [2:0]      to_dep_srcregC_idx;
    wire [2:0]      to_dep_basereg1_idx;
    wire [2:0]      to_dep_indexreg1_idx;
    wire [2:0]      to_dep_basereg2_idx;
    wire [2:0]      to_dep_srcSREG_idx;
    wire [2:0]      to_dep_SREG1_idx;
    wire [2:0]      to_dep_SREG2_idx;
    wire [2:0]      to_dep_MMA_idx;
    wire [2:0]      to_dep_MMB_idx;

    wire [1:0]      to_dep_srcA_size;
    wire [1:0]      to_dep_srcB_size;
    wire [1:0]      to_dep_srcC_size;

    /*** RR TO AG ***/
    wire [64:0]     to_ag_control_sigs;
    wire [2:0]      to_ag_dstidA;
    wire [2:0]      to_ag_dstidB;
    wire [31:0]     to_ag_srcregA;
    wire [31:0]     to_ag_srcregB;
    wire [31:0]     to_ag_srcregC;
    wire [15:0]     to_ag_srcSREG;
    wire [63:0]     to_ag_MMA;
    wire [63:0]     to_ag_MMB;
    wire [31:0]     to_ag_imm;
    wire [15:0]     to_ag_sreg1;
    wire [31:0]     to_ag_slim1;
    wire [31:0]     to_ag_base1;
    wire [31:0]     to_ag_index1;
    wire [31:0]     to_ag_disp;
    wire [1:0]      to_ag_scale_mux;
    wire [15:0]     to_ag_sreg2;
    wire [31:0]     to_ag_slim2;
    wire [31:0]     to_ag_base2;
    wire [3:0]      to_ag_intex_vec;
    wire [15:0]     to_ag_cs;
    wire [31:0]     to_ag_oeip;
    wire [31:0]     to_ag_ieip;
    wire [31:0]     to_ag_pred_eip;
    wire [1:0]      to_ag_exception;
    wire            to_ag_valid;

    /*** AG OUTPUTS ***/
    wire [56:0]     from_ag_control_sigs;
    wire [2:0]      from_ag_dstidA;
    wire [2:0]      from_ag_dstidB;
    wire [31:0]     from_ag_srcregA;
    wire [31:0]     from_ag_srcregB;
    wire [31:0]     from_ag_srcregC;
    wire [15:0]     from_ag_srcSREG;
    wire [63:0]     from_ag_MMA;
    wire [63:0]     from_ag_MMB;

    wire [15:0]     from_ag_target_cs;
    wire [31:0]     from_ag_ld_addr;
    wire [31:0]     from_ag_ld_offset;
    wire [31:0]     from_ag_ld_slim;
    wire [31:0]     from_ag_st_addr;
    wire [31:0]     from_ag_st_offset;
    wire [31:0]     from_ag_st_slim;
    wire [31:0]     from_ag_inc_esp;
    wire [31:0]     from_ag_dec_esp;
    wire [31:0]     from_ag_imm;
    wire [31:0]     from_ag_rel_eip;

    wire [15:0]     from_ag_cs;
    wire [31:0]     from_ag_oeip;
    wire [31:0]     from_ag_ieip;
    wire [31:0]     from_ag_pred_eip;
    wire [1:0]      from_ag_exception;
    wire            from_ag_valid;
    wire            from_ag_stall;
    wire            from_ag_we_pipe_reg;

    /* AG TO DEP */
    wire [1:0]     from_ag_dstA_size;
    wire [1:0]     from_ag_dstB_size;
    wire [1:0]     from_ag_ldAB;
    wire [2:0]     from_ag_ldREGS;

    /*** AG TO MEM  ***/
    wire [56:0]     to_mem_control_sigs;
    wire [2:0]      to_mem_dstidA;
    wire [2:0]      to_mem_dstidB;
    wire [31:0]     to_mem_srcregA;
    wire [31:0]     to_mem_srcregB;
    wire [31:0]     to_mem_srcregC;
    wire [15:0]     to_mem_srcSREG;
    wire [63:0]     to_mem_MMA;
    wire [63:0]     to_mem_MMB;

    wire [15:0]     to_mem_target_cs;
    wire [31:0]     to_mem_ld_addr;
    wire [31:0]     to_mem_ld_offset;
    wire [31:0]     to_mem_ld_slim;
    wire [31:0]     to_mem_st_addr;
    wire [31:0]     to_mem_st_offset;
    wire [31:0]     to_mem_st_slim;
    wire [31:0]     to_mem_inc_esp;
    wire [31:0]     to_mem_dec_esp;
    wire [31:0]     to_mem_imm;
    wire [31:0]     to_mem_rel_eip;

    wire [15:0]     to_mem_cs;
    wire [31:0]     to_mem_oeip;
    wire [31:0]     to_mem_ieip;
    wire [31:0]     to_mem_pred_eip;
    wire [1:0]      to_mem_exception;
    wire            to_mem_valid;

    
    
    
    

    /*** MEM OUTPUTS ***/
    wire [54:0]     from_mem_control_sigs;
    wire [2:0]      from_mem_dstidA;
    wire [2:0]      from_mem_dstidB;
    wire [31:0]     from_mem_srcregA;
    wire [31:0]     from_mem_srcregB;
    wire [31:0]     from_mem_srcregC;
    wire [15:0]     from_mem_srcSREG;
    wire [63:0]     from_mem_MMA;
    wire [63:0]     from_mem_MMB;
    wire [15:0]     from_mem_target_cs;
    wire [63:0]     from_mem_load_result;
    wire [31:0]     from_mem_inc_esp;
    wire [31:0]     from_mem_dec_esp;
    wire [31:0]     from_mem_imm;
    wire            from_mem_store_is_io_line_0;
    wire [10:0]     from_mem_store_addr_line_0;
    wire [15:0]     from_mem_store_mask_line_0;
    wire            from_mem_store_queue_alloc_line_0;
    wire [10:0]     from_mem_store_addr_line_1;
    wire [15:0]     from_mem_store_mask_line_1;
    wire            from_mem_store_queue_alloc_line_1;
    wire [4:0]      from_mem_store_data_shf_amt;
    wire [31:0]     from_mem_rel_eip;
    wire [15:0]     from_mem_cs;
    wire [31:0]     from_mem_oeip;
    wire [31:0]     from_mem_ieip;
    wire [31:0]     from_mem_pred_eip;
    wire [1:0]      from_mem_exception;
    wire            from_mem_valid;
    wire            from_mem_stall;
    wire            from_mem_valid_store_inst;

    /* MEM TO DEP */
    wire [1:0]      from_mem_dstA_size;
    wire [1:0]      from_mem_dstB_size;
    wire [1:0]      from_mem_ldAB;
    wire [2:0]      from_mem_ldREGS;

    /*** MEM TO EX ***/
    wire [54:0]     to_ex_control_sigs;
    wire [2:0]      to_ex_dstidA;
    wire [2:0]      to_ex_dstidB;
    wire [31:0]     to_ex_srcregA;
    wire [31:0]     to_ex_srcregB;
    wire [31:0]     to_ex_srcregC;
    wire [15:0]     to_ex_srcSREG;
    wire [63:0]     to_ex_MMA;
    wire [63:0]     to_ex_MMB;
    wire [15:0]     to_ex_target_cs;
    wire [63:0]     to_ex_load_result;
    wire [31:0]     to_ex_inc_esp;
    wire [31:0]     to_ex_dec_esp;
    wire [31:0]     to_ex_imm;
    wire [31:0]     to_ex_rel_eip;
    wire            to_ex_store_is_io_line_0;
    wire [14:4]     to_ex_store_addr_line_0;
    wire [15:0]     to_ex_store_mask_line_0;
    wire            to_ex_store_queue_alloc_line_0;
    wire [14:4]     to_ex_store_addr_line_1;
    wire [15:0]     to_ex_store_mask_line_1;
    wire            to_ex_store_queue_alloc_line_1;
    wire [4:0]      to_ex_store_data_shf_amt;
    wire [15:0]     to_ex_cs;
    wire [31:0]     to_ex_oeip;
    wire [31:0]     to_ex_ieip;
    wire [31:0]     to_ex_pred_eip;
    wire [1:0]      to_ex_exception;
    wire            to_ex_valid;

    /*** EX OUTPUTS ***/
    // wire            from_ex_flush;
    // wire            from_ex_br_t_nt;
    // wire            from_ex_br_valid;
    // wire [31:0]     from_ex_eip_target;
    wire [11:0]     from_ex_control_sigs;
    wire [2:0]      from_ex_dstidA;
    wire [2:0]      from_ex_dstidB;
    wire [31:0]     from_ex_gp_wr_data_1;
    wire [31:0]     from_ex_gp_wr_data_2;
    wire [15:0]     from_ex_seg_wr_data;
    wire [63:0]     from_ex_mmx_wr_data;
    wire [63:0]     from_ex_store_data;
    wire            from_ex_store_is_io_line_0;
    wire [10:0]     from_ex_store_addr_line_0;
    wire [15:0]     from_ex_store_mask_line_0;
    wire            from_ex_store_queue_alloc_line_0;
    wire [10:0]     from_ex_store_addr_line_1;
    wire [15:0]     from_ex_store_mask_line_1;
    wire            from_ex_store_queue_alloc_line_1;
    wire [4:0]      from_ex_store_data_shf_amt;
    wire [15:0]     from_ex_cs;
    wire [31:0]     from_ex_oeip;
    wire            from_ex_valid;
    wire [1:0]      from_ex_exception;

    wire            from_ex_valid_store_inst;

    /* EX TO DEP */
    wire  [1:0]     from_ex_dstA_size;
    wire  [1:0]     from_ex_dstB_size;
    wire            from_ex_ld_gp0;
    wire            from_ex_ld_gp1;
    wire            from_ex_ld_seg;
    wire            from_ex_ld_mmx;

    /*** EX TO WB ***/
    wire [11:0]     to_wb_control_sigs;
    wire [2:0]      to_wb_dstidA;
    wire [2:0]      to_wb_dstidB;
    wire [31:0]     to_wb_gp_wr_data_1;
    wire [31:0]     to_wb_gp_wr_data_2;
    wire [15:0]     to_wb_seg_wr_data;
    wire [63:0]     to_wb_mmx_wr_data;
    wire [63:0]     to_wb_store_data;
    wire            to_wb_store_is_io_line_0;
    wire [10:0]     to_wb_store_addr_line_0;
    wire [15:0]     to_wb_store_mask_line_0;
    wire            to_wb_store_queue_alloc_line_0;
    wire [10:0]     to_wb_store_addr_line_1;
    wire [15:0]     to_wb_store_mask_line_1;
    wire            to_wb_store_queue_alloc_line_1;
    wire [4:0]      to_wb_store_data_shf_amt;
    wire [15:0]     to_wb_cs;
    wire [31:0]     to_wb_oeip;
    wire            to_wb_valid;
    wire [1:0]      to_wb_exception;

    /*** WB OUTPUTS ***/
    wire [2:0]      from_wb_gpwr0_idx;
    wire [31:0]     from_wb_gpwr0_data;
    wire [1:0]      from_wb_gpwr0_size;
    wire            from_wb_gpwr0_en;
    wire [2:0]      from_wb_gpwr1_idx;
    wire [31:0]     from_wb_gpwr1_data;
    wire [1:0]      from_wb_gpwr1_size;
    wire            from_wb_gpwr1_en;
    wire [2:0]      from_wb_segwr_idx;
    wire [15:0]     from_wb_segwr_data;
    wire            from_wb_segwr_en;
    wire [15:0]     from_ex_cs_target;
    wire            from_ex_ld_cs;
    wire [2:0]      from_wb_mmxwr_idx;
    wire [63:0]     from_wb_mmxwr_data;
    wire            from_wb_mmxwr_en;

    wire [31:0]     from_wb_temp_eip;
    wire [15:0]     from_wb_temp_cs;
    wire [1:0]      from_wb_temp_exception;

    wire            from_wb_stall_if_mem_en;
    wire            from_wb_valid_store_inst;

    /*** TEMP CMPS REGS ***/
    wire [31:0] to_ex_CMPS0;
    wire [31:0] to_ex_CMPS1;

    // TODO: FIX ME
    assign to_ex_CMPS0 = 32'b0;
    assign to_ex_CMPS1 = 32'b0;

    /*** TEMP EXCEPTION REGS ***/
    wire [31:0] to_ex_tempEIP;
    wire [15:0] to_ex_tempCS;

    /*** DEP UNIT ***/
    wire from_dep_unit_data_dep;

    dep_unit dut (
        .from_ag_dstidA(from_ag_dstidA),
        .from_ag_dstidB(from_ag_dstidB),
        .from_ag_dstA_size(from_ag_dstA_size),
        .from_ag_dstB_size(from_ag_dstB_size),
        .from_ag_ldAB(from_ag_ldAB),
        .from_ag_ldREGS(from_ag_ldREGS),
        .from_ag_valid(from_ag_valid),
        .from_mem_dstidA(from_mem_dstidA),
        .from_mem_dstidB(from_mem_dstidB),
        .from_mem_dstA_size(from_mem_dstA_size),
        .from_mem_dstB_size(from_mem_dstB_size),
        .from_mem_ldAB(from_mem_ldAB),
        .from_mem_ldREGS(from_mem_ldREGS),
        .from_mem_valid(from_mem_valid),
        .from_ex_dstidA(from_ex_dstidA),
        .from_ex_dstidB(from_ex_dstidB),
        .from_ex_dstA_size(from_ex_dstA_size),
        .from_ex_dstB_size(from_ex_dstB_size),
        .from_ex_ld_gp0(from_ex_ld_gp0),
        .from_ex_ld_gp1(from_ex_ld_gp1),
        .from_ex_ld_seg(from_ex_ld_seg),
        .from_ex_ld_mmx(from_ex_ld_mmx),
        .from_ex_valid(from_ex_valid),
        .from_regunit_srcA_id(to_dep_srcregA_idx),
        .from_regunit_srcA_size(to_dep_srcA_size),
        .from_regunit_srcB_id(to_dep_srcregB_idx),
        .from_regunit_srcB_size(to_dep_srcB_size),
        .from_regunit_srcC_id(to_dep_srcregC_idx),
        .from_regunit_srcC_size(to_dep_srcC_size),
        .from_regunit_srcBS1_id(to_dep_basereg1_idx),
        .from_regunit_srcBS2_id(to_dep_basereg2_idx),
        .from_regunit_srcIDX_id(to_dep_indexreg1_idx),
        .from_regunit_srcSREG_id(to_dep_srcSREG_idx),
        .from_regunit_srcSR1_id(to_dep_SREG1_idx),
        .from_regunit_srcSR2_id(to_dep_SREG2_idx),
        .from_regunit_srcMMA_id(to_dep_MMA_idx),
        .from_regunit_srcMMB_id(to_dep_MMB_idx),
        .from_rr_src_needREGS(to_dep_needREGS),
        .rr_valid(to_rr_valid),
        .data_dep(from_dep_unit_data_dep)
    );
    
    stage_rr inst_rr (
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
        .from_ag_stall(from_ag_stall),
        .to_regunit_opcode(to_regunit_opcode),
        .to_regunit_modrm(to_regunit_modrm),
        .to_regunit_sib(to_regunit_sib),
        .to_regunit_has_sib(to_regunit_has_sib),
        .to_regunit_sig_gprd0_mux(to_regunit_sig_gprd0_mux),
        .to_regunit_sig_gprd1_mux(to_regunit_sig_gprd1_mux),
        .to_regunit_sig_gprd2_mux(to_regunit_sig_gprd2_mux),
        .to_regunit_sig_srcregA_mux(to_regunit_sig_srcregA_mux),
        .to_regunit_sig_srcregB_mux(to_regunit_sig_srcregB_mux),
        .to_regunit_sig_ds(to_regunit_sig_ds),
        .from_regunit_srcregA(from_regunit_srcregA),
        .from_regunit_srcregB(from_regunit_srcregB),
        .from_regunit_srcregC(from_regunit_srcregC),
        .from_regunit_basereg1(from_regunit_basereg1),
        .from_regunit_indexreg1(from_regunit_indexreg1),
        .from_regunit_basereg2(from_regunit_basereg2),
        .to_regunit_sig_srcsreg_mux(to_regunit_sig_srcsreg_mux),
        .to_regunit_sig_segrd0_mux(to_regunit_sig_segrd0_mux),
        .to_regunit_sig_segrd1_mux(to_regunit_sig_segrd1_mux),
        .to_regunit_seg_prefix(to_regunit_seg_prefix),
        .to_regunit_has_seg_prefix(to_regunit_has_seg_prefix),
        .from_regunit_srcSREG(from_regunit_srcSREG),
        .from_regunit_SREG1(from_regunit_SREG1),
        .from_regunit_SREG2(from_regunit_SREG2),
        .from_regunit_SLIM1(from_regunit_SLIM1),
        .from_regunit_SLIM2(from_regunit_SLIM2),
        .from_regunit_CS(from_regunit_CS),
        .from_regunit_MMA(from_regunit_MMA),
        .from_regunit_MMB(from_regunit_MMB),
        .from_rr_control_sigs(from_rr_control_sigs),
        .from_rr_dstidA(from_rr_dstidA),
        .from_rr_dstidB(from_rr_dstidB),
        .from_rr_srcregA(from_rr_srcregA),
        .from_rr_srcregB(from_rr_srcregB),
        .from_rr_srcregC(from_rr_srcregC),
        .from_rr_srcSREG(from_rr_srcSREG),
        .from_rr_MMA(from_rr_MMA),
        .from_rr_MMB(from_rr_MMB),
        .from_rr_imm(from_rr_imm),
        .from_rr_sreg1(from_rr_sreg1),
        .from_rr_slim1(from_rr_slim1),
        .from_rr_base1(from_rr_base1),
        .from_rr_index1(from_rr_index1),
        .from_rr_disp(from_rr_disp),
        .from_rr_scale_mux(from_rr_scale_mux),
        .from_rr_sreg2(from_rr_sreg2),
        .from_rr_slim2(from_rr_slim2),
        .from_rr_base2(from_rr_base2),
        .from_rr_intex_vec(from_rr_intex_vec),
        .from_rr_cs(from_rr_cs),
        .from_rr_oeip(from_rr_oeip),
        .from_rr_ieip(from_rr_ieip),
        .from_rr_pred_eip(from_rr_pred_eip),
        .from_rr_exception(from_rr_exception),
        .from_rr_valid(from_rr_valid),
        .from_rr_stall(from_rr_stall),
        .to_dep_needREGS(to_dep_needREGS),
        .from_dep_unit_data_dep(from_dep_unit_data_dep),
        .from_rr_we_pipe_reg(from_rr_we_pipe_reg)
    );

    rr_to_ag inst_rr_to_ag (
        .clk(clk),
        .rst_n(rst_n),
        .we(from_rr_we_pipe_reg),
        .from_rr_control_sigs(from_rr_control_sigs),
        .from_rr_dstidA(from_rr_dstidA),
        .from_rr_dstidB(from_rr_dstidB),
        .from_rr_srcregA(from_rr_srcregA),
        .from_rr_srcregB(from_rr_srcregB),
        .from_rr_srcregC(from_rr_srcregC),
        .from_rr_srcSREG(from_rr_srcSREG),
        .from_rr_MMA(from_rr_MMA),
        .from_rr_MMB(from_rr_MMB),
        .from_rr_imm(from_rr_imm),
        .from_rr_sreg1(from_rr_sreg1),
        .from_rr_slim1(from_rr_slim1),
        .from_rr_base1(from_rr_base1),
        .from_rr_index1(from_rr_index1),
        .from_rr_disp(from_rr_disp),
        .from_rr_scale_mux(from_rr_scale_mux),
        .from_rr_sreg2(from_rr_sreg2),
        .from_rr_slim2(from_rr_slim2),
        .from_rr_base2(from_rr_base2),
        .from_rr_intex_vec(from_rr_intex_vec),
        .from_rr_cs(from_rr_cs),
        .from_rr_oeip(from_rr_oeip),
        .from_rr_ieip(from_rr_ieip),
        .from_rr_pred_eip(from_rr_pred_eip),
        .from_rr_exception(from_rr_exception),
        .from_rr_valid(from_rr_valid),
        .to_ag_control_sigs(to_ag_control_sigs),
        .to_ag_dstidA(to_ag_dstidA),
        .to_ag_dstidB(to_ag_dstidB),
        .to_ag_srcregA(to_ag_srcregA),
        .to_ag_srcregB(to_ag_srcregB),
        .to_ag_srcregC(to_ag_srcregC),
        .to_ag_srcSREG(to_ag_srcSREG),
        .to_ag_MMA(to_ag_MMA),
        .to_ag_MMB(to_ag_MMB),
        .to_ag_imm(to_ag_imm),
        .to_ag_sreg1(to_ag_sreg1),
        .to_ag_slim1(to_ag_slim1),
        .to_ag_base1(to_ag_base1),
        .to_ag_index1(to_ag_index1),
        .to_ag_disp(to_ag_disp),
        .to_ag_scale_mux(to_ag_scale_mux),
        .to_ag_sreg2(to_ag_sreg2),
        .to_ag_slim2(to_ag_slim2),
        .to_ag_base2(to_ag_base2),
        .to_ag_intex_vec(to_ag_intex_vec),
        .to_ag_cs(to_ag_cs),
        .to_ag_oeip(to_ag_oeip),
        .to_ag_ieip(to_ag_ieip),
        .to_ag_pred_eip(to_ag_pred_eip),
        .to_ag_exception(to_ag_exception),
        .to_ag_valid(to_ag_valid)
    );

    regunit inst_regunit (
        .clk(clk),
        .rst_n(rst_n),
        .from_rr_opcode(to_regunit_opcode),
        .from_rr_modrm(to_regunit_modrm),
        .from_rr_sib(to_regunit_sib),
        .from_rr_has_sib(to_regunit_has_sib),
        .from_rr_sig_gprd0_mux(to_regunit_sig_gprd0_mux),
        .from_rr_sig_gprd1_mux(to_regunit_sig_gprd1_mux),
        .from_rr_sig_gprd2_mux(to_regunit_sig_gprd2_mux),
        .from_rr_sig_srcregA_mux(to_regunit_sig_srcregA_mux),
        .from_rr_sig_srcregB_mux(to_regunit_sig_srcregB_mux),
        .from_rr_sig_ds(to_regunit_sig_ds),
        .to_rr_srcregA(from_regunit_srcregA),
        .to_rr_srcregB(from_regunit_srcregB),
        .to_rr_srcregC(from_regunit_srcregC),
        .to_rr_basereg1(from_regunit_basereg1),
        .to_rr_indexreg1(from_regunit_indexreg1),
        .to_rr_basereg2(from_regunit_basereg2),
        .to_dep_srcregA_idx(to_dep_srcregA_idx),
        .to_dep_srcA_size(to_dep_srcA_size),
        .to_dep_srcregB_idx(to_dep_srcregB_idx),
        .to_dep_srcB_size(to_dep_srcB_size),
        .to_dep_srcregC_idx(to_dep_srcregC_idx),
        .to_dep_srcC_size(to_dep_srcC_size),
        .to_dep_basereg1_idx(to_dep_basereg1_idx),
        .to_dep_indexreg1_idx(to_dep_indexreg1_idx),
        .to_dep_basereg2_idx(to_dep_basereg2_idx),
        .from_rr_sig_srcsreg_mux(to_regunit_sig_srcsreg_mux),
        .from_rr_sig_segrd0_mux(to_regunit_sig_segrd0_mux),
        .from_rr_sig_segrd1_mux(to_regunit_sig_segrd1_mux),
        .from_rr_seg_prefix(to_regunit_seg_prefix),
        .from_rr_has_seg_prefix(to_regunit_has_seg_prefix),
        .to_rr_srcSREG(from_regunit_srcSREG),
        .to_rr_SREG1(from_regunit_SREG1),
        .to_rr_SREG2(from_regunit_SREG2),
        .to_rr_SLIM1(from_regunit_SLIM1),
        .to_rr_SLIM2(from_regunit_SLIM2),
        .CS(from_regunit_CS),
        .CS_LIMIT(from_regunit_cs_limit),
        .to_dep_srcSREG_idx(to_dep_srcSREG_idx),
        .to_dep_SREG1_idx(to_dep_SREG1_idx),
        .to_dep_SREG2_idx(to_dep_SREG2_idx),
        .to_rr_MMA(from_regunit_MMA),
        .to_rr_MMB(from_regunit_MMB),
        .to_dep_MMA_idx(to_dep_MMA_idx),
        .to_dep_MMB_idx(to_dep_MMB_idx),
        .from_wb_gpwr0_idx(from_wb_gpwr0_idx),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx(from_wb_gpwr1_idx),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .from_wb_segwr_idx(from_wb_segwr_idx),
        .from_wb_segwr_data(from_wb_segwr_data),
        .from_wb_segwr_en(from_wb_segwr_en),
        .from_ex_cs_wr_data(from_ex_cs_target),
        .from_ex_cs_wr_en(from_ex_ld_cs),
        .from_wb_mmxwr_idx(from_wb_mmxwr_idx),
        .from_wb_mmxwr_data(from_wb_mmxwr_data),
        .from_wb_mmxwr_en(from_wb_mmxwr_en)
    );

    stage_ag inst_ag(
        .to_ag_control_sigs(to_ag_control_sigs),
        .to_ag_dstidA(to_ag_dstidA),
        .to_ag_dstidB(to_ag_dstidB),
        .to_ag_srcregA(to_ag_srcregA),
        .to_ag_srcregB(to_ag_srcregB),
        .to_ag_srcregC(to_ag_srcregC),
        .to_ag_srcSREG(to_ag_srcSREG),
        .to_ag_MMA(to_ag_MMA),
        .to_ag_MMB(to_ag_MMB),
        .to_ag_imm(to_ag_imm),
        .to_ag_sreg1(to_ag_sreg1),
        .to_ag_slim1(to_ag_slim1),
        .to_ag_base1(to_ag_base1),
        .to_ag_index1(to_ag_index1),
        .to_ag_disp(to_ag_disp),
        .to_ag_scale_mux(to_ag_scale_mux),
        .to_ag_sreg2(to_ag_sreg2),
        .to_ag_slim2(to_ag_slim2),
        .to_ag_base2(to_ag_base2),
        .to_ag_intex_vec(to_ag_intex_vec),
        .to_ag_cs(to_ag_cs),
        .to_ag_oeip(to_ag_oeip),
        .to_ag_ieip(to_ag_ieip),
        .to_ag_pred_eip(to_ag_pred_eip),
        .to_ag_exception(to_ag_exception),
        .to_ag_valid(to_ag_valid),

        .from_mem_stall(from_mem_stall),
        .from_mem_valid_store_inst(from_mem_valid_store_inst),
        .from_ex_valid_store_inst(from_ex_valid_store_inst),
        .from_wb_stall_if_mem_en(from_wb_stall_if_mem_en),
        .from_wb_valid_store_inst(from_wb_valid_store_inst),

        .from_ag_control_sigs(from_ag_control_sigs),
        .from_ag_dstidA(from_ag_dstidA),
        .from_ag_dstidB(from_ag_dstidB),
        .from_ag_srcregA(from_ag_srcregA),
        .from_ag_srcregB(from_ag_srcregB),
        .from_ag_srcregC(from_ag_srcregC),
        .from_ag_srcSREG(from_ag_srcSREG),
        .from_ag_MMA(from_ag_MMA),
        .from_ag_MMB(from_ag_MMB),

        .from_ag_target_cs(from_ag_target_cs),
        .from_ag_ld_addr(from_ag_ld_addr),
        .from_ag_ld_offset(from_ag_ld_offset),
        .from_ag_ld_slim(from_ag_ld_slim),
        .from_ag_st_addr(from_ag_st_addr),
        .from_ag_st_offset(from_ag_st_offset),
        .from_ag_st_slim(from_ag_st_slim),
        .from_ag_inc_esp(from_ag_inc_esp),
        .from_ag_dec_esp(from_ag_dec_esp),
        .from_ag_imm(from_ag_imm),
        .from_ag_rel_eip(from_ag_rel_eip),

        .from_ag_cs(from_ag_cs),
        .from_ag_oeip(from_ag_oeip),
        .from_ag_ieip(from_ag_ieip),
        .from_ag_pred_eip(from_ag_pred_eip),
        .from_ag_exception(from_ag_exception),
        .from_ag_valid(from_ag_valid),

        .from_ag_stall(from_ag_stall),
        .from_ag_we_pipe_reg(from_ag_we_pipe_reg),

        .from_ag_dstA_size(from_ag_dstA_size),
        .from_ag_dstB_size(from_ag_dstB_size),
        .from_ag_ldAB(from_ag_ldAB),
        .from_ag_ldREGS(from_ag_ldREGS)
    );

    ag_to_mem inst_ag_to_mem (
        .clk(clk),
        .rst_n(rst_n),
        .we(from_ag_we_pipe_reg),
        .from_ag_control_sigs(from_ag_control_sigs),
        .from_ag_dstidA(from_ag_dstidA),
        .from_ag_dstidB(from_ag_dstidB),
        .from_ag_srcregA(from_ag_srcregA),
        .from_ag_srcregB(from_ag_srcregB),
        .from_ag_srcregC(from_ag_srcregC),
        .from_ag_srcSREG(from_ag_srcSREG),
        .from_ag_MMA(from_ag_MMA),
        .from_ag_MMB(from_ag_MMB),
        .from_ag_target_cs(from_ag_target_cs),
        .from_ag_ld_addr(from_ag_ld_addr),
        .from_ag_ld_offset(from_ag_ld_offset),
        .from_ag_ld_slim(from_ag_ld_slim),
        .from_ag_st_addr(from_ag_st_addr),
        .from_ag_st_offset(from_ag_st_offset),
        .from_ag_st_slim(from_ag_st_slim),
        .from_ag_inc_esp(from_ag_inc_esp),
        .from_ag_dec_esp(from_ag_dec_esp),
        .from_ag_imm(from_ag_imm),
        .from_ag_rel_eip(from_ag_rel_eip),
        .from_ag_cs(from_ag_cs),
        .from_ag_oeip(from_ag_oeip),
        .from_ag_ieip(from_ag_ieip),
        .from_ag_pred_eip(from_ag_pred_eip),
        .from_ag_exception(from_ag_exception),
        .from_ag_valid(from_ag_valid),
        .to_mem_control_sigs(to_mem_control_sigs),
        .to_mem_dstidA(to_mem_dstidA),
        .to_mem_dstidB(to_mem_dstidB),
        .to_mem_srcregA(to_mem_srcregA),
        .to_mem_srcregB(to_mem_srcregB),
        .to_mem_srcregC(to_mem_srcregC),
        .to_mem_srcSREG(to_mem_srcSREG),
        .to_mem_MMA(to_mem_MMA),
        .to_mem_MMB(to_mem_MMB),
        .to_mem_target_cs(to_mem_target_cs),
        .to_mem_ld_addr(to_mem_ld_addr),
        .to_mem_ld_offset(to_mem_ld_offset),
        .to_mem_ld_slim(to_mem_ld_slim),
        .to_mem_st_addr(to_mem_st_addr),
        .to_mem_st_offset(to_mem_st_offset),
        .to_mem_st_slim(to_mem_st_slim),
        .to_mem_inc_esp(to_mem_inc_esp),
        .to_mem_dec_esp(to_mem_dec_esp),
        .to_mem_imm(to_mem_imm),
        .to_mem_rel_eip(to_mem_rel_eip),
        .to_mem_cs(to_mem_cs),
        .to_mem_oeip(to_mem_oeip),
        .to_mem_ieip(to_mem_ieip),
        .to_mem_pred_eip(to_mem_pred_eip),
        .to_mem_exception(to_mem_exception),
        .to_mem_valid(to_mem_valid)
    );

    stage_mem inst_stage_mem (
      .clk(clk),
      .rst_n(rst_n),

      .to_mem_control_sigs(to_mem_control_sigs),
      .to_mem_dstidA(to_mem_dstidA),
      .to_mem_dstidB(to_mem_dstidB),
      .to_mem_srcregA(to_mem_srcregA),
      .to_mem_srcregB(to_mem_srcregB),
      .to_mem_srcregC(to_mem_srcregC),
      .to_mem_srcSREG(to_mem_srcSREG),
      .to_mem_MMA(to_mem_MMA),
      .to_mem_MMB(to_mem_MMB),
      .to_mem_target_cs(to_mem_target_cs),
      .to_mem_ld_addr(to_mem_ld_addr),
      .to_mem_ld_offset(to_mem_ld_offset),
      .to_mem_ld_slim(to_mem_ld_slim),
      .to_mem_st_addr(to_mem_st_addr),
      .to_mem_st_offset(to_mem_st_offset),
      .to_mem_st_slim(to_mem_st_slim),
      .to_mem_inc_esp(to_mem_inc_esp),
      .to_mem_dec_esp(to_mem_dec_esp),
      .to_mem_imm(to_mem_imm),
      .to_mem_rel_eip(to_mem_rel_eip),
      .to_mem_cs(to_mem_cs),
      .to_mem_oeip(to_mem_oeip),
      .to_mem_ieip(to_mem_ieip),
      .to_mem_pred_eip(to_mem_pred_eip),
      .to_mem_exception(to_mem_exception),
      .to_mem_valid(to_mem_valid),

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
      .from_mem_inc_esp(from_mem_inc_esp),
      .from_mem_dec_esp(from_mem_dec_esp),
      .from_mem_imm(from_mem_imm),
      .from_mem_rel_eip(from_mem_rel_eip),
      .from_mem_cs(from_mem_cs),
      .from_mem_oeip(from_mem_oeip),
      .from_mem_ieip(from_mem_ieip),
      .from_mem_pred_eip(from_mem_pred_eip),
      .from_mem_exception(from_mem_exception),
      .from_mem_valid(from_mem_valid),
      .from_mem_stall(from_mem_stall),
      .from_mem_valid_store_inst(from_mem_valid_store_inst),
      .from_mem_dstA_size(from_mem_dstA_size),
      .from_mem_dstB_size(from_mem_dstB_size),
      .from_mem_ldAB(from_mem_ldAB),
      .from_mem_ldREGS(from_mem_ldREGS),

      .DCACHE_STALL(DCACHE_STALL),
      .DCACHE_HIT_DATA(DCACHE_HIT_DATA),

      .from_rr_code_segment_limit(from_regunit_cs_limit),
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
      .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST)
    );

    mem_to_ex inst_mem_to_ex (
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
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
        .from_mem_inc_esp(from_mem_inc_esp),
        .from_mem_dec_esp(from_mem_dec_esp),
        .from_mem_imm(from_mem_imm),
        .from_mem_rel_eip(from_mem_rel_eip),
        .from_mem_store_is_io_line_0(from_mem_store_is_io_line_0),
        .from_mem_store_addr_line_0(from_mem_store_addr_line_0),
        .from_mem_store_mask_line_0(from_mem_store_mask_line_0),
        .from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0),
        .from_mem_store_addr_line_1(from_mem_store_addr_line_1),
        .from_mem_store_mask_line_1(from_mem_store_mask_line_1),
        .from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1),
        .from_mem_store_data_shf_amt(from_mem_store_data_shf_amt),
        .from_mem_cs(from_mem_cs),
        .from_mem_oeip(from_mem_oeip),
        .from_mem_ieip(from_mem_ieip),
        .from_mem_pred_eip(from_mem_pred_eip),
        .from_mem_exception(from_mem_exception),
        .from_mem_valid(from_mem_valid),
        .to_ex_control_sigs(to_ex_control_sigs),
        .to_ex_dstidA(to_ex_dstidA),
        .to_ex_dstidB(to_ex_dstidB),
        .to_ex_srcregA(to_ex_srcregA),
        .to_ex_srcregB(to_ex_srcregB),
        .to_ex_srcregC(to_ex_srcregC),
        .to_ex_srcSREG(to_ex_srcSREG),
        .to_ex_MMA(to_ex_MMA),
        .to_ex_MMB(to_ex_MMB),
        .to_ex_target_cs(to_ex_target_cs),
        .to_ex_load_result(to_ex_load_result),
        .to_ex_inc_esp(to_ex_inc_esp),
        .to_ex_dec_esp(to_ex_dec_esp),
        .to_ex_imm(to_ex_imm),
        .to_ex_rel_eip(to_ex_rel_eip),
        .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
        .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
        .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
        .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
        .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
        .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
        .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
        .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),
        .to_ex_cs(to_ex_cs),
        .to_ex_oeip(to_ex_oeip),
        .to_ex_ieip(to_ex_ieip),
        .to_ex_pred_eip(to_ex_pred_eip),
        .to_ex_exception(to_ex_exception),
        .to_ex_valid(to_ex_valid)
    );

    stage_ex inst_stage_ex (
        .clk(clk),
        .rst_n(rst_n),
        .to_ex_control_sigs(to_ex_control_sigs),
        .to_ex_dstidA(to_ex_dstidA),
        .to_ex_dstidB(to_ex_dstidB),
        .to_ex_srcregA(to_ex_srcregA),
        .to_ex_srcregB(to_ex_srcregB),
        .to_ex_srcregC(to_ex_srcregC),
        .to_ex_srcSREG(to_ex_srcSREG),
        .to_ex_MMA(to_ex_MMA),
        .to_ex_MMB(to_ex_MMB),
        .to_ex_target_cs(to_ex_target_cs),
        .to_ex_load_result(to_ex_load_result),
        .to_ex_inc_esp(to_ex_inc_esp),
        .to_ex_dec_esp(to_ex_dec_esp),
        .to_ex_imm(to_ex_imm),
        .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
        .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
        .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
        .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
        .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
        .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
        .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
        .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),
        .to_ex_rel_eip(to_ex_rel_eip),
        .to_ex_cs(to_ex_cs),
        .to_ex_oeip(to_ex_oeip),
        .to_ex_ieip(to_ex_ieip),
        .to_ex_pred_eip(to_ex_pred_eip),
        .to_ex_exception(to_ex_exception),
        .to_ex_valid(to_ex_valid),
        .to_ex_CMPS0(to_ex_CMPS0),
        .to_ex_CMPS1(to_ex_CMPS1),
        .to_ex_tempEIP(to_ex_tempEIP),
        .to_ex_tempCS(to_ex_tempCS),
        .to_ex_cs_limit(from_regunit_cs_limit),
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_cs_target(from_ex_cs_target),
        .from_ex_eip_target(from_ex_eip_target),
        .from_ex_control_sigs(from_ex_control_sigs),
        .from_ex_dstidA(from_ex_dstidA),
        .from_ex_dstidB(from_ex_dstidB),
        .from_ex_gp_wr_data_1(from_ex_gp_wr_data_1),
        .from_ex_gp_wr_data_2(from_ex_gp_wr_data_2),
        .from_ex_seg_wr_data(from_ex_seg_wr_data),
        .from_ex_mmx_wr_data(from_ex_mmx_wr_data),
        .from_ex_store_data(from_ex_store_data),
        .from_ex_store_is_io_line_0(from_ex_store_is_io_line_0),
        .from_ex_store_addr_line_0(from_ex_store_addr_line_0),
        .from_ex_store_mask_line_0(from_ex_store_mask_line_0),
        .from_ex_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0),
        .from_ex_store_addr_line_1(from_ex_store_addr_line_1),
        .from_ex_store_mask_line_1(from_ex_store_mask_line_1),
        .from_ex_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1),
        .from_ex_store_data_shf_amt(from_ex_store_data_shf_amt),
        .from_ex_cs(from_ex_cs),
        .from_ex_oeip(from_ex_oeip),
        .from_ex_valid_store_inst(from_ex_valid_store_inst),
        .from_ex_valid(from_ex_valid),
        .from_ex_exception(from_ex_exception),
        .from_ex_dstA_size(from_ex_dstA_size),
        .from_ex_dstB_size(from_ex_dstB_size),
        .from_ex_ld_gp0(from_ex_ld_gp0),
        .from_ex_ld_gp1(from_ex_ld_gp1),
        .from_ex_ld_seg(from_ex_ld_seg),
        .from_ex_ld_mmx(from_ex_ld_mmx)
    );

    ex_to_wb inst_ex_to_wb (
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
        .from_ex_control_sigs(from_ex_control_sigs),
        .from_ex_dstidA(from_ex_dstidA),
        .from_ex_dstidB(from_ex_dstidB),
        .from_ex_gp_wr_data_1(from_ex_gp_wr_data_1),
        .from_ex_gp_wr_data_2(from_ex_gp_wr_data_2),
        .from_ex_seg_wr_data(from_ex_seg_wr_data),
        .from_ex_mmx_wr_data(from_ex_mmx_wr_data),
        .from_ex_store_data(from_ex_store_data),
        .from_ex_store_is_io_line_0(from_ex_store_is_io_line_0),
        .from_ex_store_addr_line_0(from_ex_store_addr_line_0),
        .from_ex_store_mask_line_0(from_ex_store_mask_line_0),
        .from_ex_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0),
        .from_ex_store_addr_line_1(from_ex_store_addr_line_1),
        .from_ex_store_mask_line_1(from_ex_store_mask_line_1),
        .from_ex_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1),
        .from_ex_store_data_shf_amt(from_ex_store_data_shf_amt),
        .from_ex_cs(from_ex_cs),
        .from_ex_oeip(from_ex_oeip),
        .from_ex_valid(from_ex_valid),
        .from_ex_exception(from_ex_exception),
        .to_wb_control_sigs(to_wb_control_sigs),
        .to_wb_dstidA(to_wb_dstidA),
        .to_wb_dstidB(to_wb_dstidB),
        .to_wb_gp_wr_data_1(to_wb_gp_wr_data_1),
        .to_wb_gp_wr_data_2(to_wb_gp_wr_data_2),
        .to_wb_seg_wr_data(to_wb_seg_wr_data),
        .to_wb_mmx_wr_data(to_wb_mmx_wr_data),
        .to_wb_store_data(to_wb_store_data),
        .to_wb_store_is_io_line_0(to_wb_store_is_io_line_0),
        .to_wb_store_addr_line_0(to_wb_store_addr_line_0),
        .to_wb_store_mask_line_0(to_wb_store_mask_line_0),
        .to_wb_store_queue_alloc_line_0(to_wb_store_queue_alloc_line_0),
        .to_wb_store_addr_line_1(to_wb_store_addr_line_1),
        .to_wb_store_mask_line_1(to_wb_store_mask_line_1),
        .to_wb_store_queue_alloc_line_1(to_wb_store_queue_alloc_line_1),
        .to_wb_store_data_shf_amt(to_wb_store_data_shf_amt),
        .to_wb_cs(to_wb_cs),
        .to_wb_oeip(to_wb_oeip),
        .to_wb_valid(to_wb_valid),
        .to_wb_exception(to_wb_exception)
    );

    stage_wb inst_stage_wb (
        .clk(clk),
        .rst_n(rst_n),

        .to_wb_control_sigs(to_wb_control_sigs),
        .to_wb_dstidA(to_wb_dstidA), 
        .to_wb_dstidB(to_wb_dstidB),
        .to_wb_gp_wr_data_1(to_wb_gp_wr_data_1),
        .to_wb_gp_wr_data_2(to_wb_gp_wr_data_2),
        .to_wb_seg_wr_data(to_wb_seg_wr_data),
        .to_wb_mmx_wr_data(to_wb_mmx_wr_data),
        .to_wb_oeip(to_wb_oeip),
        .to_wb_cs(to_wb_cs),

        .from_wb_gpwr0_idx(from_wb_gpwr0_idx),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx(from_wb_gpwr1_idx),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .from_wb_segwr_idx(from_wb_segwr_idx),
        .from_wb_segwr_data(from_wb_segwr_data),
        .from_wb_segwr_en(from_wb_segwr_en),
        .from_wb_mmxwr_idx(from_wb_mmxwr_idx),
        .from_wb_mmxwr_data(from_wb_mmxwr_data),
        .from_wb_mmxwr_en(from_wb_mmxwr_en),

        .from_wb_temp_cs(from_wb_temp_cs),
        .from_wb_temp_eip(from_wb_temp_eip),
        .from_wb_temp_exception(from_wb_temp_exception),


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

        .WBE_BUSY(WBE_BUSY),
        .DCACHE_HIT(DCACHE_HIT),
        .DCACHE_STALL(DCACHE_STALL),

        .STOREQ_STORING(STOREQ_STORING),
        .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
        .STOREQ_DATA(STOREQ_DATA),
        .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
        .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

        .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
        .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
        .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
        .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

        .from_wb_stall_if_mem_en(from_wb_stall_if_mem_en),
        .from_wb_valid_store_inst(from_wb_valid_store_inst),
        .from_wb_flush(from_wb_flush)
    );

    temp_exception_regs inst_temp_exception_regs(
        .clk(clk),
        .rst_n(rst_n),
        .from_wb_temp_cs(from_wb_temp_cs),
        .from_wb_temp_eip(from_wb_temp_eip),
        .from_wb_temp_exception(from_wb_temp_exception),
        .from_wb_flush(from_wb_flush),
        .to_ex_tempCS(to_ex_tempCS),
        .to_ex_tempEIP(to_ex_tempEIP)
    ); 


endmodule