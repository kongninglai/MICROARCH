module single_stage_dep(
    input   [2:0]   dstA_id,
    input   [2:0]   dstB_id,
    input   [1:0]   dstA_size,
    input   [1:0]   dstB_size,
    input           ld_gp0,
    input           ld_gp1,
    input           ld_seg,
    input           ld_mmx,
    input           dst_valid,

    input   [2:0]   srcA_id,
    input   [1:0]   srcA_size,
    input   [2:0]   srcB_id,
    input   [1:0]   srcB_size,
    input   [2:0]   srcC_id,
    input   [1:0]   srcC_size,
    input   [2:0]   srcBS1_id, // size=10
    input   [2:0]   srcBS2_id, // size=10
    input   [2:0]   srcIDX_id, // size=10
    input   [2:0]   srcSREG_id,
    input   [2:0]   srcSR1_id,
    input   [2:0]   srcSR2_id,
    input   [2:0]   srcMMA_id,
    input   [2:0]   srcMMB_id,
    input   [10:0]  src_needREGS,

    output          dep,

    output          addr_src_dep,
    output  [1:0]   fw_mux_A,
    output  [1:0]   fw_mux_B,
    output  [1:0]   fw_mux_C,
    output          fw_SREG,
    output          fw_MMA,
    output          fw_MMB
); 
    wire depA, depB, depC, depBS1, depBS2, depIDX, depSREG, depSR1, depSR2, depMMA, depMMB;

    gp_dep gp_depA (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcA_id),
        .src_size  (srcA_size),
        .ld_src    (src_needREGS[10]),
        .dep       (depA),
        .fw_mux    (fw_muxA)
    );

    gp_dep gp_depB (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcB_id),
        .src_size  (srcB_size),
        .ld_src    (src_needREGS[9]),
        .dep       (depB),
        .fw_mux    (fw_muxB)
    );

    gp_dep gp_depC (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcC_id),
        .src_size  (srcC_size),
        .ld_src    (src_needREGS[8]),
        .dep       (depC),
        .fw_mux    (fw_muxC)
    );

    gp_dep gp_depBS1 (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcBS1_id),
        .src_size  (2'b10),
        .ld_src    (src_needREGS[7]),
        .dep       (depBS1),
        .fw_mux    ()
    );

    gp_dep gp_depBS2 (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcBS2_id),
        .src_size  (2'b10),
        .ld_src    (src_needREGS[6]),
        .dep       (depBS2),
        .fw_mux    ()
    );

    gp_dep gp_depIDX (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_gp0),
        .ld_dstB   (ld_gp1),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (srcIDX_id),
        .src_size  (2'b10),
        .ld_src    (src_needREGS[5]),
        .dep       (depIDX),
        .fw_mux    ()
    );

    check_dep check_depSREG(
        .src_id(srcSREG_id),
        .dst_id(dstA_id),
        .ld_dst(ld_seg),
        .ld_src(src_needREGS[4]),
        .dep(depSREG)
    );

    check_dep check_depSR1(
        .src_id(srcSR1_id),
        .dst_id(dstA_id),
        .ld_dst(ld_seg),
        .ld_src(src_needREGS[3]),
        .dep(depSR1)
    );

    check_dep check_depSR2(
        .src_id(srcSR2_id),
        .dst_id(dstA_id),
        .ld_dst(ld_seg),
        .ld_src(src_needREGS[2]),
        .dep(depSR2)
    );

    check_dep check_depMMA(
        .src_id(srcMMA_id),
        .dst_id(dstA_id),
        .ld_dst(ld_mmx),
        .ld_src(src_needREGS[1]),
        .dep(depMMA)
    );

    check_dep check_depMMB(
        .src_id(srcMMB_id),
        .dst_id(dstA_id),
        .ld_dst(ld_mmx),
        .ld_src(src_needREGS[0]),
        .dep(depMMB)
    );

    assign fw_SREG  = depSREG;
    assign fw_MMA   = depMMA;
    assign fw_MMB   = depMMB;
    
    wire any_dep, addr_src_dep_without_valid;

    big_or #(
      .WIDTH(5)
    ) or_addr_src_dep_without_valid (
      .out(addr_src_dep_without_valid),
      .in({depBS1, depBS2, depIDX, depSR1, depSR2})
    );

    big_or #(
      .WIDTH(11)
    ) or_any_dep (
      .out(any_dep),
      .in({depA, depB, depC, depBS1, depBS2, depIDX,
           depSREG, depSR1, depSR2,
           depMMA, depMMB})
    );

    and2$ and_valid_dep(dep, dst_valid, any_dep);
    and2$ and_valid_addr_src_dep(addr_src_dep, addr_src_dep_without_valid, dst_valid);
endmodule