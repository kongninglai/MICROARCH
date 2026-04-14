module dep_unit(
    /* FROM AG */
    input   [2:0]   from_ag_dstidA,
    input   [2:0]   from_ag_dstidB,
    input   [1:0]   from_ag_dstA_size,
    input   [1:0]   from_ag_dstB_size,
    input   [1:0]   from_ag_ldAB,
    input   [2:0]   from_ag_ldREGS,
    input           from_ag_valid,

    /* FROM MEM */
    input   [2:0]   from_mem_dstidA,
    input   [2:0]   from_mem_dstidB,
    input   [1:0]   from_mem_dstA_size,
    input   [1:0]   from_mem_dstB_size,
    input   [1:0]   from_mem_ldAB,
    input   [2:0]   from_mem_ldREGS,
    input           from_mem_valid,

    /* FROM EX */
    input   [2:0]   from_ex_dstidA,
    input   [2:0]   from_ex_dstidB,
    input   [1:0]   from_ex_dstA_size,
    input   [1:0]   from_ex_dstB_size,
    input           from_ex_ld_gp0,
    input           from_ex_ld_gp1,
    input           from_ex_ld_seg,
    input           from_ex_ld_mmx,
    input           from_ex_valid,

    /* FROM RR */
    input   [2:0]   from_regunit_srcA_id,
    input   [1:0]   from_regunit_srcA_size,
    input   [2:0]   from_regunit_srcB_id,
    input   [1:0]   from_regunit_srcB_size,
    input   [2:0]   from_regunit_srcC_id,
    input   [1:0]   from_regunit_srcC_size,
    input   [2:0]   from_regunit_srcBS1_id,
    input   [2:0]   from_regunit_srcBS2_id,
    input   [2:0]   from_regunit_srcIDX_id,
    input   [2:0]   from_regunit_srcSREG_id,
    input   [2:0]   from_regunit_srcSR1_id,
    input   [2:0]   from_regunit_srcSR2_id,
    input   [2:0]   from_regunit_srcMMA_id,
    input   [2:0]   from_regunit_srcMMB_id,
    input   [10:0]  from_rr_src_needREGS,
    input           rr_valid,
    input           from_rr_load_en,

    output          data_dep,
    output  [8:0]   AG_FW_CONTROL_SIGS,
    output  [8:0]   MEM_FW_CONTROL_SIGS,
    output  [8:0]   EX_FW_CONTROL_SIGS
    output  [1:0]   AG_FW_A,
    output  [1:0]   AG_FW_B,
    output  [1:0]   AG_FW_C,
    output          AG_FW_SREG,
    output          AG_FW_MMA,
    output          AG_FW_MMB,

    output  [1:0]   MEM_FW_A,
    output  [1:0]   MEM_FW_B,
    output  [1:0]   MEM_FW_C,
    output          MEM_FW_SREG,
    output          MEM_FW_MMA,
    output          MEM_FW_MMB,

    output  [1:0]   EX_FW_A,
    output  [1:0]   EX_FW_B,
    output  [1:0]   EX_FW_C,
    output          EX_FW_SREG,
    output          EX_FW_MMA,
    output          EX_FW_MMB
);
    wire [1:0] AG_FW_A, AG_FW_B, AG_FW_C, MEM_FW_A, MEM_FW_B, MEM_FW_C, EX_FW_A, EX_FW_B, EX_FW_C;
    wire AG_FW_SREG, AG_FW_MMA, AG_FW_MMB, MEM_FW_SREG, MEM_FW_MMA, MEM_FW_MMB, EX_FW_SREG, EX_FW_MMA, EX_FW_MMB
    wire from_ag_ld_gp0, from_ag_ld_gp1, from_ag_ld_seg, from_ag_ld_mmx;
    wire from_mem_ld_gp0, from_mem_ld_gp1, from_mem_ld_seg, from_mem_ld_mmx;

    wire from_ag_inv_ldSEG_out, from_mem_inv_ldSEG_out;
    inv1$ inv_from_ag_ldSEG(from_ag_inv_ldSEG_out, from_ag_ldREGS[1]);
    inv1$ inv_from_mem_ldSEG(from_mem_inv_ldSEG_out, from_mem_ldREGS[1]);

    and3$ and_from_ag_ld_gp0(from_ag_ld_gp0, from_ag_ldAB[1], from_ag_ldREGS[2], from_ag_inv_ldSEG_out);
    and2$ and_from_ag_ld_gp1(from_ag_ld_gp1, from_ag_ldAB[0], from_ag_ldREGS[2]);
    and2$ and_from_ag_ld_seg(from_ag_ld_seg, from_ag_ldAB[1], from_ag_ldREGS[1]);
    and2$ and_from_ag_ld_mmx(from_ag_ld_mmx, from_ag_ldAB[1], from_ag_ldREGS[0]);

    and3$ and_from_mem_ld_gp0(from_mem_ld_gp0, from_mem_ldAB[1], from_mem_ldREGS[2], from_mem_inv_ldSEG_out);
    and2$ and_from_mem_ld_gp1(from_mem_ld_gp1, from_mem_ldAB[0], from_mem_ldREGS[2]);
    and2$ and_from_mem_ld_seg(from_mem_ld_seg, from_mem_ldAB[1], from_mem_ldREGS[1]);
    and2$ and_from_mem_ld_mmx(from_mem_ld_mmx, from_mem_ldAB[1], from_mem_ldREGS[0]);

    wire dep_ag, dep_mem, dep_ex;

    wire addr_src_dep_ag, addr_src_dep_mem, addr_src_dep_ex;
    wire [1:0] mem_fw_A_temp, mem_fw_B_temp, mem_fw_C_temp;
    wire mem_fw_SREG_temp, mem_fw_MMA_temp, mem_fw_MMB_temp;

    single_stage_dep check_dep_from_ag(
        .dstA_id(from_ag_dstidA),
        .dstB_id(from_ag_dstidB),
        .dstA_size(from_ag_dstA_size),
        .dstB_size(from_ag_dstB_size),
        .ld_gp0(from_ag_ld_gp0),
        .ld_gp1(from_ag_ld_gp1),
        .ld_seg(from_ag_ld_seg),
        .ld_mmx(from_ag_ld_mmx),
        .dst_valid(from_ag_valid),

        .srcA_id(from_regunit_srcA_id),
        .srcA_size(from_regunit_srcA_size),
        .srcB_id(from_regunit_srcB_id),
        .srcB_size(from_regunit_srcB_size),
        .srcC_id(from_regunit_srcC_id),
        .srcC_size(from_regunit_srcC_size),
        .srcBS1_id(from_regunit_srcBS1_id), // size=10
        .srcBS2_id(from_regunit_srcBS2_id), // size=10
        .srcIDX_id(from_regunit_srcIDX_id), // size=10
        .srcSREG_id(from_regunit_srcSREG_id),
        .srcSR1_id(from_regunit_srcSR1_id),
        .srcSR2_id(from_regunit_srcSR2_id),
        .srcMMA_id(from_regunit_srcMMA_id),
        .srcMMB_id(from_regunit_srcMMB_id),
        .src_needREGS(from_rr_src_needREGS),
        .dep(dep_ag),
        .addr_src_dep(addr_src_dep_ag),
        .fw_mux_A(AG_FW_A),
        .fw_mux_B(AG_FW_B),
        .fw_mux_C(AG_FW_C),
        .fw_SREG(AG_FW_SREG),
        .fw_MMA(AG_FW_MMA),
        .fw_MMB(AG_FW_MMB)
    ); 

    single_stage_dep check_dep_from_mem(
        .dstA_id(from_mem_dstidA),
        .dstB_id(from_mem_dstidB),
        .dstA_size(from_mem_dstA_size),
        .dstB_size(from_mem_dstB_size),
        .ld_gp0(from_mem_ld_gp0),
        .ld_gp1(from_mem_ld_gp1),
        .ld_seg(from_mem_ld_seg),
        .ld_mmx(from_mem_ld_mmx),
        .dst_valid(from_mem_valid),

        .srcA_id(from_regunit_srcA_id),
        .srcA_size(from_regunit_srcA_size),
        .srcB_id(from_regunit_srcB_id),
        .srcB_size(from_regunit_srcB_size),
        .srcC_id(from_regunit_srcC_id),
        .srcC_size(from_regunit_srcC_size),
        .srcBS1_id(from_regunit_srcBS1_id), // size=10
        .srcBS2_id(from_regunit_srcBS2_id), // size=10
        .srcIDX_id(from_regunit_srcIDX_id), // size=10
        .srcSREG_id(from_regunit_srcSREG_id),
        .srcSR1_id(from_regunit_srcSR1_id),
        .srcSR2_id(from_regunit_srcSR2_id),
        .srcMMA_id(from_regunit_srcMMA_id),
        .srcMMB_id(from_regunit_srcMMB_id),
        .src_needREGS(from_rr_src_needREGS),
        .dep(dep_mem),
        .addr_src_dep(addr_src_dep_mem),
        .fw_mux_A(mem_fw_A_temp),
        .fw_mux_B(mem_fw_B_temp),
        .fw_mux_C(mem_fw_C_temp),
        .fw_SREG(mem_fw_SREG_temp),
        .fw_MMA(mem_fw_MMA_temp),
        .fw_MMB(mem_fw_MMB_temp)
    ); 

    single_stage_dep check_dep_from_ex(
        .dstA_id(from_ex_dstidA),
        .dstB_id(from_ex_dstidB),
        .dstA_size(from_ex_dstA_size),
        .dstB_size(from_ex_dstB_size),
        .ld_gp0(from_ex_ld_gp0),
        .ld_gp1(from_ex_ld_gp1),
        .ld_seg(from_ex_ld_seg),
        .ld_mmx(from_ex_ld_mmx),
        .dst_valid(from_ex_valid),

        .srcA_id(from_regunit_srcA_id),
        .srcA_size(from_regunit_srcA_size),
        .srcB_id(from_regunit_srcB_id),
        .srcB_size(from_regunit_srcB_size),
        .srcC_id(from_regunit_srcC_id),
        .srcC_size(from_regunit_srcC_size),
        .srcBS1_id(from_regunit_srcBS1_id), // size=10
        .srcBS2_id(from_regunit_srcBS2_id), // size=10
        .srcIDX_id(from_regunit_srcIDX_id), // size=10
        .srcSREG_id(from_regunit_srcSREG_id),
        .srcSR1_id(from_regunit_srcSR1_id),
        .srcSR2_id(from_regunit_srcSR2_id),
        .srcMMA_id(from_regunit_srcMMA_id),
        .srcMMB_id(from_regunit_srcMMB_id),
        .src_needREGS(from_rr_src_needREGS),
        .dep(dep_ex),
        .addr_src_dep(addr_src_dep_ex),
        .fw_mux_A(EX_FW_A),
        .fw_mux_B(EX_FW_B),
        .fw_mux_C(EX_FW_C),
        .fw_SREG(EX_FW_SREG),
        .fw_MMA(EX_FW_MMA),
        .fw_MMB(EX_FW_MMB)
    ); 

    wire dep_with_mem_and_load_en, buffered_dep_with_mem_and_load_en;
    
    and2$ and2_dep_with_mem_and_load_en(dep_with_mem_and_load_en, dep_mem, from_rr_load_en);
    bufferH16$ buffer_dep_with_mem_and_load_en(buffered_dep_with_mem_and_load_en, dep_with_mem_and_load_en);
    wire addr_dep_or_mem_dep;
    or4$ or3_addr_dep_or_mem_dep(addr_dep_or_mem_dep, addr_src_dep_ag, addr_src_dep_mem, addr_src_dep_ex, buffered_dep_with_mem_and_load_en);
    and2$ and2_dep_stall(data_dep, addr_dep_or_mem_dep, rr_valid);

    mux2$ mux2_mem_fw_A[8:0](MEM_FW_CONTROL_SIGS, {MEM_FW_A, MEM_FW_B, MEM_FW_C, MEM_FW_SREG, MEM_FW_MMA, MEM_FW_MMB}, 9'b0, buffered_dep_with_mem_and_load_en);
    
    assign AG_FW_CONTROL_SIGS = {AG_FW_A, AG_FW_B, AG_FW_C, AG_FW_SREG, AG_FW_MMA, AG_FW_MMB};
    assign EX_FW_CONTROL_SIGS = {EX_FW_A, EX_FW_B, EX_FW_C, EX_FW_SREG, EX_FW_MMA, EX_FW_MMB};
endmodule