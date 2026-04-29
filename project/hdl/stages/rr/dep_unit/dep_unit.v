module dep_unit #(
    parameter FORWARD_EN = 1'b1
)(
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
    input   [1:0]   from_rr_rw,
    input           from_rr_rep,

    input           from_ag_valid_mem_inst,
    input           from_mem_valid_mem_inst,

    output          data_dep,
    output  [11:0]   AG_FW_CONTROL_SIGS,
    output  [11:0]   MEM_FW_CONTROL_SIGS,
    output  [11:0]   EX_FW_CONTROL_SIGS
);
    wire [2:0] AG_FW_A, AG_FW_B, AG_FW_C, MEM_FW_A, MEM_FW_B, MEM_FW_C, EX_FW_A, EX_FW_B, EX_FW_C;
    wire AG_FW_SREG, AG_FW_MMA, AG_FW_MMB, MEM_FW_SREG, MEM_FW_MMA, MEM_FW_MMB, EX_FW_SREG, EX_FW_MMA, EX_FW_MMB;
    wire from_ag_ld_gp0, from_ag_ld_gp1, from_ag_ld_seg, from_ag_ld_mmx;
    wire from_mem_ld_gp0, from_mem_ld_gp1, from_mem_ld_seg, from_mem_ld_mmx;

    wire from_ag_inv_ldSEG_out, from_mem_inv_ldSEG_out;
    inv1$ inv_from_ag_ldSEG(from_ag_inv_ldSEG_out, from_ag_ldREGS[1]);
    inv1$ inv_from_mem_ldSEG(from_mem_inv_ldSEG_out, from_mem_ldREGS[1]);

    wire from_ag_ld_gp0_bar, from_ag_ld_gp1_bar, from_mem_ld_gp0_bar, from_mem_ld_gp1_bar;

    bufferHInv16$ bufferHInv16$_from_ag_ld_gp0(from_ag_ld_gp0, from_ag_ld_gp0_bar);
    bufferHInv16$ bufferHInv16$_from_ag_ld_gp1(from_ag_ld_gp1, from_ag_ld_gp1_bar);
    bufferHInv16$ bufferHInv16$_from_mem_ld_gp0(from_mem_ld_gp0, from_mem_ld_gp0_bar);
    bufferHInv16$ bufferHInv16$_from_mem_ld_gp1(from_mem_ld_gp1, from_mem_ld_gp1_bar);

    nand3$ nand_from_ag_ld_gp0_bar(from_ag_ld_gp0_bar, from_ag_ldAB[1], from_ag_ldREGS[2], from_ag_inv_ldSEG_out);
    nand2$ nand_from_ag_ld_gp1_bar(from_ag_ld_gp1_bar, from_ag_ldAB[0], from_ag_ldREGS[2]);
    and2$ and_from_ag_ld_seg(from_ag_ld_seg, from_ag_ldAB[1], from_ag_ldREGS[1]);
    and2$ and_from_ag_ld_mmx(from_ag_ld_mmx, from_ag_ldAB[1], from_ag_ldREGS[0]);

    nand3$ nand_from_mem_ld_gp0_bar(from_mem_ld_gp0_bar, from_mem_ldAB[1], from_mem_ldREGS[2], from_mem_inv_ldSEG_out);
    nand2$ nand_from_mem_ld_gp1_bar(from_mem_ld_gp1_bar, from_mem_ldAB[0], from_mem_ldREGS[2]);
    and2$ and_from_mem_ld_seg(from_mem_ld_seg, from_mem_ldAB[1], from_mem_ldREGS[1]);
    and2$ and_from_mem_ld_mmx(from_mem_ld_mmx, from_mem_ldAB[1], from_mem_ldREGS[0]);

    wire dep_ag_bar, dep_mem_bar, dep_ex_bar;

    wire addr_src_dep_bar_ag, addr_src_dep_bar_mem, addr_src_dep_bar_ex;
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
        .dep_bar(dep_ag_bar),
        .addr_src_dep_bar(addr_src_dep_bar_ag),
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
        .dep_bar(dep_mem_bar),
        .addr_src_dep_bar(addr_src_dep_bar_mem),
        .fw_mux_A(MEM_FW_A),
        .fw_mux_B(MEM_FW_B),
        .fw_mux_C(MEM_FW_C),
        .fw_SREG(MEM_FW_SREG),
        .fw_MMA(MEM_FW_MMA),
        .fw_MMB(MEM_FW_MMB)
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
        .dep_bar(dep_ex_bar),
        .addr_src_dep_bar(addr_src_dep_bar_ex),
        .fw_mux_A(EX_FW_A),
        .fw_mux_B(EX_FW_B),
        .fw_mux_C(EX_FW_C),
        .fw_SREG(EX_FW_SREG),
        .fw_MMA(EX_FW_MMA),
        .fw_MMB(EX_FW_MMB)
    ); 

    wire load_en_or_rep, dep_and_load_en_bar, buffered_dep_and_load_en;
    wire any_dep;
    nand3$ nand3_any_dep(any_dep, dep_ag_bar, dep_mem_bar, dep_ex_bar);

    generate 
        if (FORWARD_EN) begin 
            big_or #(
            .WIDTH(5)
            ) big_or_load_en_or_rep (
            .out(load_en_or_rep),
            .in({from_rr_rw[1], from_rr_rw[0], from_rr_rep, from_ag_valid_mem_inst, from_mem_valid_mem_inst})
            );
            nand2$ nand2_dep_and_load_en_bar(dep_and_load_en_bar, any_dep, load_en_or_rep);
            wire addr_dep_or_mem_dep;
            nand4$ nand4_addr_dep_or_mem_dep(addr_dep_or_mem_dep, addr_src_dep_bar_ag, addr_src_dep_bar_mem, addr_src_dep_bar_ex, dep_and_load_en_bar);
            assign data_dep = addr_dep_or_mem_dep;
            wire inv_buffered_dep_and_load_en, mem_fw_en, ex_fw_en, ag_fw_en;
            nand2$ nand_mem_fw_en(mem_fw_en, from_mem_valid, dep_and_load_en_bar);
            nand2$ nand_ex_fw_en(ex_fw_en, from_ex_valid, dep_and_load_en_bar);
            nand2$ nand_ag_fw_en(ag_fw_en, from_ag_valid, dep_and_load_en_bar);

            wire [6:0] MEM_FW_CONTROL_SIGS_DUMMY, AG_FW_CONTROL_SIGS_DUMMY, EX_FW_CONTROL_SIGS_DUMMY;

            mux2_16$ mux2_16_mem_fw_A({ MEM_FW_CONTROL_SIGS_DUMMY, MEM_FW_CONTROL_SIGS[10:9], MEM_FW_CONTROL_SIGS[7:6], MEM_FW_CONTROL_SIGS[4:0]}, {7'd0, MEM_FW_A[1:0], MEM_FW_B[1:0], MEM_FW_C[1:0], MEM_FW_SREG, MEM_FW_MMA, MEM_FW_MMB}, 16'd0, mem_fw_en);
            mux2_16$ mux2_16_ag_fw_A ({ AG_FW_CONTROL_SIGS_DUMMY,  AG_FW_CONTROL_SIGS[10:9], AG_FW_CONTROL_SIGS[7:6], AG_FW_CONTROL_SIGS[4:0]}, {7'd0, EX_FW_A[1:0], EX_FW_B[1:0], EX_FW_C[1:0], EX_FW_SREG, EX_FW_MMA, EX_FW_MMB},       16'd0, ex_fw_en);
            mux2_16$ mux2_16_ex_fw_A ({ EX_FW_CONTROL_SIGS_DUMMY,  EX_FW_CONTROL_SIGS[10:9], EX_FW_CONTROL_SIGS[7:6], EX_FW_CONTROL_SIGS[4:0]}, {7'd0, AG_FW_A[1:0], AG_FW_B[1:0], AG_FW_C[1:0], AG_FW_SREG, AG_FW_MMA, AG_FW_MMB},       16'd0, ag_fw_en);
            assign {MEM_FW_CONTROL_SIGS[11], MEM_FW_CONTROL_SIGS[8], MEM_FW_CONTROL_SIGS[5]} = {MEM_FW_A[2], MEM_FW_B[2], MEM_FW_C[2]};
            assign {AG_FW_CONTROL_SIGS[11], AG_FW_CONTROL_SIGS[8], AG_FW_CONTROL_SIGS[5]} = {EX_FW_A[2], EX_FW_B[2], EX_FW_C[2]};
            assign {EX_FW_CONTROL_SIGS[11], EX_FW_CONTROL_SIGS[8], EX_FW_CONTROL_SIGS[5]} = {AG_FW_A[2], AG_FW_B[2], AG_FW_C[2]};
        end else begin 
            assign data_dep = any_dep;
            assign {MEM_FW_CONTROL_SIGS[10:9], MEM_FW_CONTROL_SIGS[7:6], MEM_FW_CONTROL_SIGS[4:0]} = 9'b0;
            assign {AG_FW_CONTROL_SIGS[10:9], AG_FW_CONTROL_SIGS[7:6], AG_FW_CONTROL_SIGS[4:0]} = 9'b0;
            assign {EX_FW_CONTROL_SIGS[10:9], EX_FW_CONTROL_SIGS[7:6], EX_FW_CONTROL_SIGS[4:0]} = 9'b0;
            assign {MEM_FW_CONTROL_SIGS[11], MEM_FW_CONTROL_SIGS[8], MEM_FW_CONTROL_SIGS[5]} = {MEM_FW_A[2], MEM_FW_B[2], MEM_FW_C[2]};
            assign {AG_FW_CONTROL_SIGS[11], AG_FW_CONTROL_SIGS[8], AG_FW_CONTROL_SIGS[5]} = {EX_FW_A[2], EX_FW_B[2], EX_FW_C[2]};
            assign {EX_FW_CONTROL_SIGS[11], EX_FW_CONTROL_SIGS[8], EX_FW_CONTROL_SIGS[5]} = {AG_FW_A[2], AG_FW_B[2], AG_FW_C[2]};
        end
    endgenerate

    
endmodule