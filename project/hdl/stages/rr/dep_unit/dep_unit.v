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

    output          data_dep
);
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
        .dep(dep_ag)
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
        .dep(dep_mem)
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
        .dep(dep_ex)
    ); 

    wire any_dep;
    or3$ or3_any_dep(any_dep, dep_ag, dep_mem, dep_ex);
    assign data_dep = any_dep;
    // and2$ and2_dep_stall(data_dep, any_dep, rr_valid);
endmodule