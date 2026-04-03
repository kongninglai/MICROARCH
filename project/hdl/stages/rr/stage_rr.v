module stage_rr(
    input [5:0] to_rr_prefix,
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
    input [1:0]  to_rr_exception,
    input to_rr_valid,

    input from_ag_stall,
    input from_dep_unit_data_dep,
    output from_rr_we_pipe_reg,

    output [7:0]  to_regunit_opcode,
    output [5:0]  to_regunit_modrm,
    output [5:0]  to_regunit_sib,
    output        to_regunit_has_sib,
    output [1:0]  to_regunit_sig_gprd0_mux,
    output        to_regunit_sig_gprd1_mux,
    output [1:0]  to_regunit_sig_gprd2_mux,
    output        to_regunit_sig_srcregA_mux,
    output        to_regunit_sig_srcregB_mux,
    output [1:0]  to_regunit_sig_ds,

    input [31:0] from_regunit_srcregA,
    input [31:0] from_regunit_srcregB,
    input [31:0] from_regunit_srcregC,
    input [31:0] from_regunit_basereg1,
    input [31:0] from_regunit_indexreg1,
    input [31:0] from_regunit_basereg2,

    output  to_regunit_sig_srcsreg_mux,
    output  to_regunit_sig_segrd0_mux,
    output  to_regunit_sig_segrd1_mux,
    output [2:0] to_regunit_seg_prefix,

    input [15:0] from_regunit_srcSREG,
    input [15:0] from_regunit_SREG1,
    input [15:0] from_regunit_SREG2,
    input [31:0] from_regunit_SLIM1,
    input [31:0] from_regunit_SLIM2,
    input [15:0] from_regunit_CS,

    input [63:0] from_regunit_MMA,
    input [63:0] from_regunit_MMB,

    output [10:0] to_dep_needREGS,

    output [64:0] from_rr_control_sigs,
    output [2:0] from_rr_dstidA,
    output [2:0] from_rr_dstidB,
    output [31:0] from_rr_srcregA,
    output [31:0] from_rr_srcregB,
    output [31:0] from_rr_srcregC,
    output [15:0] from_rr_srcSREG,
    output [63:0] from_rr_MMA,
    output [63:0] from_rr_MMB,
    output [31:0] from_rr_imm,
    output [15:0] from_rr_sreg1,
    output [31:0] from_rr_slim1,
    output [31:0] from_rr_base1,
    output [31:0] from_rr_index1,
    output [31:0] from_rr_disp,
    output [1:0]  from_rr_scale_mux,
    output [15:0] from_rr_sreg2,
    output [31:0] from_rr_slim2,
    output [31:0] from_rr_base2,
    output [3:0] from_rr_intex_vec,
    output [15:0] from_rr_cs,
    output [31:0] from_rr_oeip,
    output [31:0] from_rr_ieip,
    output [31:0] from_rr_pred_eip,
    output [1:0] from_rr_exception,
    output from_rr_valid,

    output from_rr_stall
); 
    wire [95:0] ucode_sig;
    ucode_controller uctlr (.ucode_sig(ucode_sig), 
                            .opcode(to_rr_opcode), 
                            .ext_opcode(to_rr_prefix[0]),
                            .modrm(to_rr_modrm[7:6]),
                            .has_modrm(to_rr_addr_mode[0])
                           );

    wire [1:0] ldAB, dstidB_mux, gprd0_mux, gprd2_mux, shf_srcb_mux, cs_mux, mm_dst_mux, rw, ds, mem_ds, imm_mux, addr_mux;
    wire [2:0] dstidA_mux, ldREGS, eflags_mux, eip_mux, gp_dstb_mux;
    wire gprd1_mux, srcregA_mux, srcregB_mux, ldEFLAGS, alu_srcb_mux, ldEIP, ldCS, seg_dst_mux, srcsreg_mux, segrd0_mux, segrd1_mux, rm;
    wire [10:0] needREGS;
    wire [3:0] gp_dsta_mux, store_data_mux;

    rr_sig rr_sig_dut(
    .ucode_sig(ucode_sig), .ldAB(ldAB), .dstidA_mux(dstidA_mux), .dstidB_mux(dstidB_mux),
    .srcregA_mux(srcregA_mux), .srcregB_mux(srcregB_mux), .gprd0_mux(gprd0_mux), .gprd1_mux(gprd1_mux), .gprd2_mux(gprd2_mux), .srcsreg_mux(srcsreg_mux), .segrd0_mux(segrd0_mux), .segrd1_mux(segrd1_mux),
    .ldREGS(ldREGS), .needREGS(needREGS), .ldEFLAGS(ldEFLAGS),
    .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux),
    .ldEIP(ldEIP), .ldCS(ldCS), .eflags_mux(eflags_mux), .eip_mux(eip_mux), .cs_mux(cs_mux),
    .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
    .store_data_mux(store_data_mux), .rw(rw), .ds(ds), .mem_ds(mem_ds), .imm_mux(imm_mux), .addr_mux(addr_mux), .rm(rm)
    );
    
    wire [1:0] ds_with_override, mem_ds_override_16;
    wire ds1_inv, ds_is_32, set_ds_16;
    inv1$ inv_ds1(ds1_inv, ds[1]);
    nor2$ nor2_ds32(ds_is_32, ds1_inv, ds[0]);
    and2$ and_ds16(set_ds_16, ds_is_32, to_rr_prefix[4]);
    mux2$ mux_ds_override[1:0](ds_with_override, ds, 2'b01, set_ds_16);
    mux2$ mux_mem_ds_override16[1:0](mem_ds_override_16, mem_ds, 2'b01, set_ds_16);

    wire mem_ds_is_64, set_mem_ds_32;
    wire [1:0] mem_ds_with_override;
    and2$ and_mem_ds_64(mem_ds_is_64, mem_ds[1], mem_ds[0]);
    and2$ and_ds32(set_mem_ds_32, mem_ds_is_64, to_rr_prefix[4]);
    mux2$ mux_mem_ds_override[1:0](mem_ds_with_override, mem_ds_override_16, 2'b10, set_mem_ds_32);

    wire intex, stack_push;

    assign intex = 1'b0; // TODO: FIX intex
    
    wire gp_dstb_mux1_inv, gp_dstb_mux_is_010;
    inv1$ inv_gp_dstb_mux(gp_dstb_mux1_inv, gp_dstb_mux[1]);
    nor3$ nor_gp_dstb_mux_is_010(gp_dstb_mux_is_010, gp_dstb_mux[0], gp_dstb_mux1_inv, gp_dstb_mux[2]);

    assign stack_push = gp_dstb_mux_is_010;

    assign to_regunit_opcode = to_rr_opcode;          
    assign to_regunit_modrm = to_rr_modrm[5:0];
    assign to_regunit_sib = to_rr_sib[5:0];
    assign to_regunit_has_sib = to_rr_addr_mode[1];
    assign to_regunit_sig_gprd0_mux = gprd0_mux;
    assign to_regunit_sig_gprd1_mux = gprd1_mux;
    assign to_regunit_sig_gprd2_mux = gprd2_mux;
    assign to_regunit_sig_srcregA_mux = srcregA_mux;
    assign to_regunit_sig_srcregB_mux = srcregB_mux;
    assign to_regunit_sig_ds = ds_with_override;
    assign to_regunit_sig_srcsreg_mux = srcsreg_mux;
    assign to_regunit_sig_segrd0_mux = segrd0_mux;
    assign to_regunit_sig_segrd1_mux = segrd1_mux;

    wire [1:0] dstA_size, dstB_size;
    wire [1:0] mmx_op, con_jmp;
    wire [2:0] alu_op;
    wire shf_op, cmps, cmpxchg, cmovc, palu_size;
    
    // dstA_size = 32 if dstidA_mux=101/110(ESI/ECX) else ds
    // dstB_size = ds if dstidB_mux=01/10(regr/EAX) else 32
    wire dstidA_xor_10, dstidA_size_32, dstidB_0_inv, dstidB_size_ds;
    xor2$ xor_dstidA10(dstidA_xor_10, dstidA_mux[1], dstidA_mux[0]);
    and2$ and_dstidA_size_32(dstidA_size_32, dstidA_xor_10, dstidA_mux[2]);
    mux2$ mux2_dstA_size[1:0](dstA_size, ds_with_override, 2'b10, dstidA_size_32);

    xor2$ xor_dstidB_size_ds(dstidB_size_ds, dstidB_mux[1], dstidB_mux[0]);
    mux2$ mux2_dstB_size[1:0](dstB_size, 2'b10, ds_with_override, dstidB_size_ds);


    wire [3:0] ff_store_data_mux, from_rr_store_data_mux;
    wire [1:0] ff_from_rr_rw, from_rr_rw;
    wire ff_from_rr_ldEIP, from_rr_ldEIP;
    wire ff_ldB, ff_from_rr_ldB;
    wire opcode_ff;
    big_and #(.WIDTH(8)) and_opcode_ff(opcode_ff, to_rr_opcode);
    mux4$ mux4_store_data_mux[3:0](ff_store_data_mux, 4'bx, 4'b0001, 4'bx, 4'b1010, to_rr_modrm[4], to_rr_modrm[5]);
    mux4$ mux4_rw[1:0](ff_from_rr_rw, 2'bx, 2'b11, 2'b10, 2'b11, to_rr_modrm[4], to_rr_modrm[5]);
    mux4$ mux4_ff_ldB(ff_ldB, 1'bx, 1'b1, 1'b0, 1'b1, to_rr_modrm[4], to_rr_modrm[5]);
    mux4$ mux4_ldEIP(ff_from_rr_ldEIP, 1'bx, 1'b1, 1'b1, 1'b0, to_rr_modrm[4], to_rr_modrm[5]);

    mux2$ mux2_store_data_mux[3:0](from_rr_store_data_mux, store_data_mux, ff_store_data_mux, opcode_ff);
    mux2$ mux2_rw[1:0](from_rr_rw, rw, ff_from_rr_rw, opcode_ff);
    mux2$ mux2_ldEIP(from_rr_ldEIP, ldEIP, ff_from_rr_ldEIP, opcode_ff);
    mux2$ mux2_ldB(ff_from_rr_ldB, ldAB[0], ff_ldB, opcode_ff);
    wire ret_with_imm;
    big_eq #(.WIDTH(7)) eq_ret_with_imm(.eq(ret_with_imm), .in0({to_rr_opcode[7:4], to_rr_opcode[2:0]}), .in1(7'h62));
    assign from_rr_control_sigs={{ldAB[1], ff_from_rr_ldB}, dstA_size, dstB_size, ldREGS, ldEFLAGS,
                     from_rr_ldEIP, ldCS, alu_srcb_mux, shf_srcb_mux, eflags_mux, eip_mux, cs_mux,
                     mmx_op, alu_op, shf_op, cmps, con_jmp, cmpxchg, cmovc,
                     gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux, from_rr_store_data_mux, from_rr_rw, ds_with_override, 
                     mem_ds_with_override, imm_mux, addr_mux, stack_push, intex, ret_with_imm, rm, to_rr_prefix[4], palu_size};

    assign mmx_op = {to_rr_opcode[7], to_rr_opcode[2]};
    wire pack_size, padd_size, pavg_size;
    assign pack_size = to_rr_opcode[3];
    assign padd_size = to_rr_opcode[1];
    assign pavg_size = to_rr_opcode[0];
    mux4$ mux4_palu_size(palu_size, pack_size, 1'bx, pavg_size, padd_size, mmx_op[0], mmx_op[1]);
    assign shf_op = to_rr_modrm[4];
    assign cmps = 1'b0; // TODO: FIX CMPS

    mux2$ mux2_aluop[2:0](alu_op, to_rr_opcode[5:3], to_rr_modrm[5:3], to_rr_opcode[7]);
    wire opcode_77, opcode_87, opcode_75, opcode_85, opcode_jnbe, opcode_jne;
    big_eq #(.WIDTH(8)) eq_77(.eq(opcode_77), .in0(to_rr_opcode), .in1(8'h77));
    big_eq #(.WIDTH(8)) eq_87(.eq(opcode_87), .in0(to_rr_opcode), .in1(8'h87));
    big_eq #(.WIDTH(8)) eq_75(.eq(opcode_75), .in0(to_rr_opcode), .in1(8'h75));
    big_eq #(.WIDTH(8)) eq_85(.eq(opcode_85), .in0(to_rr_opcode), .in1(8'h85));

    or2$ or_opcode_jnbe(opcode_jnbe, opcode_77, opcode_87);
    or2$ or_opcode_jne(opcode_jne, opcode_75, opcode_85);
    assign con_jmp = {opcode_jnbe, opcode_jne};

    wire opcode_B0;
    big_eq #(.WIDTH(5)) eq_B0(.eq(opcode_B0), .in0(to_rr_opcode[7:3]), .in1(5'b10110));
    and2$ and_cmpxchg(cmpxchg, to_rr_prefix[0], opcode_B0);

    wire opcode_42;
    big_eq #(.WIDTH(8)) eq_42(.eq(opcode_42), .in0(to_rr_opcode), .in1(8'h42));
    and2$ and_cmovc(cmovc, to_rr_prefix[0], opcode_42);
    
    mux8 mux8_dstidA[2:0](from_rr_dstidA, 3'b000, to_rr_modrm[2:0], to_rr_modrm[5:3], to_rr_opcode[2:0], to_rr_opcode[5:3], 3'b110, 3'b001, , dstidA_mux[0], dstidA_mux[1], dstidA_mux[2]);
    mux4$ mux4_dstidB[2:0](from_rr_dstidB, 3'b100, to_rr_modrm[5:3], 3'b000, 3'b111, dstidB_mux[0], dstidB_mux[1]);

    assign from_rr_srcregA=from_regunit_srcregA;
    assign from_rr_srcregB=from_regunit_srcregB;
    assign from_rr_srcregC=from_regunit_srcregC;
    assign from_rr_srcSREG=from_regunit_srcSREG;
    assign from_rr_MMA=from_regunit_MMA;
    assign from_rr_MMB=from_regunit_MMB;
    assign from_rr_imm=to_rr_imm[31:0];
    assign from_rr_sreg1=from_regunit_SREG1;
    assign to_regunit_seg_prefix=to_rr_prefix[3:1];
    // assign from_rr_slim1=from_regunit_SLIM1;

    wire mod_00, rm1_inv, rm_101, base_none;
    wire index2_inv, index_100_inv, index_none;
    nor2$ nor_mod00(mod_00, to_rr_modrm[7], to_rr_modrm[6]);
    inv1$ inv_rm1(rm1_inv, to_rr_modrm[1]);
    and3$ and_rm101(rm_101, to_rr_modrm[2], rm1_inv, to_rr_modrm[0]);
    and2$ and_base_none(base_none, rm_101, mod_00);

    inv1$ inv_index2(index2_inv, to_rr_sib[2]);
    or3$ or_index100(index_100_inv, index2_inv, to_rr_sib[1], to_rr_sib[0]);
    nand2$ and_index_none(index_none, to_rr_addr_mode[1], index_100_inv);

    mux2$ mux2_basereg1[31:0](from_rr_base1, from_regunit_basereg1, 32'b0, base_none);
    mux2$ mux2_index1[31:0](from_rr_index1, from_regunit_indexreg1, 32'b0, index_none);
    
    wire need_bs1, need_idx;
    mux2$ mux2_need_bs1(need_bs1, needREGS[7], 1'b0, base_none);
    mux2$ mux2_need_idx(need_idx, needREGS[5], 1'b0, index_none);
    
    wire [31:0] disp8_se, disp_normal, disp_ptr;
    se se_disp(.out(disp8_se), .in(to_rr_disp[7:0]));
    mux3_32 mux3_disp(.out(disp_normal), .in0(32'b0), .in1(disp8_se), .in2(to_rr_disp), .s0(to_rr_dispsize[0]), .s1(to_rr_dispsize[1]));
    mux2_32 mux2_disp_ptr(.out(disp_ptr), .in0({16'b0, to_rr_imm[47:32]}), .in1({16'b0, to_rr_imm[31:16]}), .s0(to_rr_prefix[4])) ;

    wire disp_is_ptr; // opcode=9A/EA
    wire opcode_9a, opcode_ea;
    big_eq #(.WIDTH(8)) eq_9a(.eq(opcode_9a), .in0(to_rr_opcode), .in1(8'h9A));
    big_eq #(.WIDTH(8)) eq_ea(.eq(opcode_ea), .in0(to_rr_opcode), .in1(8'hEA));
    or2$ or_is_ptr(disp_is_ptr, opcode_9a, opcode_ea);
    // and2$ and_immsize48(disp_is_ptr, to_rr_imm_size[2], to_rr_imm_size[1]);
    mux2_32 mux2_disp_value(.out(from_rr_disp), .in0(disp_normal), .in1(disp_ptr), .s0(disp_is_ptr));

    mux2$ mux2_scale[1:0](from_rr_scale_mux, 2'b00, to_rr_sib[7:6], to_rr_addr_mode[1]);

    assign from_rr_slim1 = from_regunit_SLIM1;
    assign from_rr_slim2 = from_regunit_SLIM2;

    assign from_rr_sreg2=from_regunit_SREG2;
    // assign from_rr_slim2=from_regunit_SLIM2;
    assign from_rr_base2=from_regunit_basereg2;
    assign from_rr_intex_vec=4'b0; // TODO: ASSIGN intex
    assign from_rr_oeip=to_rr_oeip;
    assign from_rr_ieip=to_rr_ieip;
    assign from_rr_cs = from_regunit_CS;
    
    assign from_rr_pred_eip = to_rr_pred_eip;
    assign from_rr_exception = to_rr_exception;

    // if data_dep: bubble -> valid = 0
    // from_rr_valid = to_rr_valid & ~data_dep
    wire no_dep;
    inv1$ inv_dep(no_dep, from_dep_unit_data_dep);
    and2$ and_valid(from_rr_valid, no_dep, to_rr_valid);

    /* TODO: ADD STALL LOGIC */
    or2$ or_from_rr_stall(from_rr_stall, from_ag_stall, from_dep_unit_data_dep);

    assign to_dep_needREGS = {needREGS[10:8], need_bs1, needREGS[6], need_idx, needREGS[4:0]};
    inv1$  inv1$_from_rr_we_pipe_reg(from_rr_we_pipe_reg, from_ag_stall);
endmodule