module stage_ag(
    input [64:0]    to_ag_control_sigs,
    input [2:0]     to_ag_dstidA,
    input [2:0]     to_ag_dstidB,
    input [31:0]    to_ag_srcregA,
    input [31:0]    to_ag_srcregB,
    input [31:0]    to_ag_srcregC,
    input [15:0]    to_ag_srcSREG,
    input [63:0]    to_ag_MMA,
    input [63:0]    to_ag_MMB,
    input [31:0]    to_ag_imm,
    input [15:0]    to_ag_sreg1,
    input [31:0]    to_ag_slim1,
    input [31:0]    to_ag_base1,
    input [31:0]    to_ag_index1,
    input [31:0]    to_ag_disp,
    input [1:0]     to_ag_scale_mux,
    input [15:0]    to_ag_sreg2,
    input [31:0]    to_ag_slim2,
    input [31:0]    to_ag_base2,
    input [3:0]     to_ag_intex_vec,
    input [15:0]    to_ag_cs,
    input [31:0]    to_ag_oeip,
    input [31:0]    to_ag_ieip,
    input [31:0]    to_ag_pred_eip,
    input [1:0]     to_ag_exception,
    input           to_ag_valid,

    input           from_mem_stall,
    input           from_mem_valid_store_inst,
    input           from_ex_valid_store_inst,
    input           from_wb_stall_if_mem_en,
    input           from_wb_valid_store_inst,

    output [56:0]    from_ag_control_sigs,
    output [2:0]     from_ag_dstidA,
    output [2:0]     from_ag_dstidB,
    output [31:0]    from_ag_srcregA,
    output [31:0]    from_ag_srcregB,
    output [31:0]    from_ag_srcregC,
    output [15:0]    from_ag_srcSREG,
    output [63:0]    from_ag_MMA,
    output [63:0]    from_ag_MMB,

    output [15:0]    from_ag_target_cs,
    output [31:0]    from_ag_ld_addr,
    output [31:0]    from_ag_ld_offset,
    output [31:0]    from_ag_ld_slim,
    output [31:0]    from_ag_st_addr,
    output [31:0]    from_ag_st_offset,
    output [31:0]    from_ag_st_slim,
    output [31:0]    from_ag_inc_esp,
    output [31:0]    from_ag_dec_esp,
    output [31:0]    from_ag_imm,
    output [31:0]    from_ag_rel_eip,

    output [15:0]    from_ag_cs,
    output [31:0]    from_ag_oeip,
    output [31:0]    from_ag_ieip,
    output [31:0]    from_ag_pred_eip,
    output [1:0]     from_ag_exception,
    output           from_ag_valid,

    output           from_ag_stall,
    output           from_ag_we_pipe_reg
);

    wire ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, stack_push, intex, seg_dst_mux, ret_with_imm, rm, op_ovr, palu_size;
    wire [1:0] ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux, mem_ds, imm_mux, addr_mux;
    wire [2:0] ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux;
    wire [3:0] gp_dsta_mux, store_data_mux;

    wire store_addr_mux, load_addr_mux;

    assign {load_addr_mux, store_addr_mux} = addr_mux;

    assign from_ag_control_sigs = {
        ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, seg_dst_mux,
        ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux, mem_ds,
        ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux,
        gp_dsta_mux, store_data_mux, rm, op_ovr, palu_size
    };
    
    assign from_ag_dstidA = to_ag_dstidA;
    assign from_ag_dstidB = to_ag_dstidB;
    assign from_ag_srcregA = to_ag_srcregA;
    assign from_ag_srcregB = to_ag_srcregB;
    assign from_ag_srcregC = to_ag_srcregC;
    assign from_ag_srcSREG = to_ag_srcSREG;
    assign from_ag_MMA = to_ag_MMA;
    assign from_ag_MMB = to_ag_MMB;
    assign from_ag_target_cs = to_ag_disp[15:0];
    assign from_ag_intex_vec = to_ag_intex_vec;
    assign from_ag_cs = to_ag_cs;
    assign from_ag_oeip = to_ag_oeip;
    assign from_ag_ieip = to_ag_ieip;
    assign from_ag_pred_eip = to_ag_pred_eip;
    assign from_ag_exception = to_ag_exception;
    /* NOTE: moved from_ag_valid logic below. -VR, 3/31/2026 */

    wire is_mem_inst, stall_if_mem_inst, mem_inst_needs_stall;
    or2$    or2$_is_mem_inst(is_mem_inst, rw[1], rw[0]);
    or4$    or4$_stall_if_mem_inst(stall_if_mem_inst, from_mem_valid_store_inst, from_ex_valid_store_inst, from_wb_stall_if_mem_en, from_wb_valid_store_inst);
    and2$   and2$_mem_inst_needs_stall(mem_inst_needs_stall, is_mem_inst, stall_if_mem_inst);
    or2$    or2$_from_ag_stall(from_ag_stall, from_mem_stall, mem_inst_needs_stall);
    inv1$   inv1$_from_ag_we_pipe_reg(from_ag_we_pipe_reg, from_mem_stall);

    /* Insert bubbles if mem_inst_needs_stall and NOT from_mem_stall */
    wire from_ag_valid_gate, from_mem_stall_bar;
    inv1$   inv1$_from_mem_stall_bar(from_mem_stall_bar, from_mem_stall);
    nand2$  nand2$_from_ag_valid_gate(from_ag_valid_gate, from_mem_stall_bar, mem_inst_needs_stall);
    and2$   and2$_from_ag_valid(from_ag_valid, to_ag_valid, from_ag_valid_gate);

    // TODO: Add control signals into the ag_sig module
    ag_sig dut_sig (
        .ucode_sig(to_ag_control_sigs),
        .ldAB(ldAB), .dstA_size(dstA_size), .dstB_size(dstB_size), .ldREGS(ldREGS),
        .ldEFLAGS(ldEFLAGS), .ldEIP(ldEIP), .ldCS(ldCS),
        .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux), .eflags_mux(eflags_mux),
        .eip_mux(eip_mux), .cs_mux(cs_mux),
        .mmx_op(mmx_op), .alu_op(alu_op), .shf_op(shf_op), .cmps(cmps), .con_jmp(con_jmp),
        .cmpxchg(cmpxchg), .cmovc(cmovc),
        .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
        .store_data_mux(store_data_mux), .rw(rw),
        .ds(ds), .mem_ds(mem_ds), .imm_mux(imm_mux), .addr_mux(addr_mux), .stack_push(stack_push), .intex(intex), .ret_with_imm(ret_with_imm),
        .rm(rm), .op_ovr(op_ovr), .palu_size(palu_size)
    );


    // ========= REL EIP LOGIC ===========
    wire [31:0] imm_se8, imm_se16, imm_ze16, imm_final;
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_imm8(.in(to_ag_imm[7:0]), .out(imm_se8));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_imm16(.in(to_ag_imm[15:0]), .out(imm_se16));
    ze #(.INP_WIDTH(16), .OUT_WIDTH(32)) ze_imm16(.in(to_ag_imm[15:0]), .out(imm_ze16));

    mux4_32 mux_imm(imm_final, imm_se8, imm_se16, imm_ze16, to_ag_imm, imm_mux[0], imm_mux[1]);
    PA_32b PA_rel_eip(.s(from_ag_rel_eip), .in0(to_ag_ieip), .in1(imm_final));
    
    assign from_ag_imm = imm_final;

    // ========= MEM ADDR LOGIC ===========
    wire [31:0] addr1, offset1, addr2, offset2, inc_esp, dec_esp;
    address_adder address_adder_inst (
        .scale_mux1(to_ag_scale_mux), .sreg1(to_ag_sreg1), .index1(to_ag_index1), .base1(to_ag_base1), .disp1(to_ag_disp),
        .stack_push(stack_push), .ret_with_imm(ret_with_imm), .imm(imm_final), .sreg2(to_ag_sreg2), .base2(to_ag_base2),
        .size_mux(mem_ds),
        .addr1(addr1), .offset1(offset1),
        .addr2(addr2), .offset2(offset2), .inc_esp(inc_esp), .dec_esp(dec_esp)
    );

    assign from_ag_inc_esp = inc_esp;
    assign from_ag_dec_esp = dec_esp;

    wire [31:0] ze32_intex_vec, shifted_intex_vec, addr_intex_idtr;
    ze #(.INP_WIDTH(4), .OUT_WIDTH(32)) ze_intex_vec(.in(to_ag_intex_vec), .out(ze32_intex_vec));

    lshf_const #(.WIDTH(32), .SHF_AMT(3)) lshf3_intex_vec(.in(ze32_intex_vec), .out(shifted_intex_vec));
    PA_32b PA_intex_idtr(.s(addr_intex_idtr), .in0(32'h02000000), .in1(shifted_intex_vec));

    wire [31:0] ld_addr1_or_2, ld_slim1_or_2;
    mux2_32 mux_ld_addr(ld_addr1_or_2, addr1, addr2, load_addr_mux);
    mux2_32 mux_ld_addr_with_intex(from_ag_ld_addr, ld_addr1_or_2, addr_intex_idtr, intex);
    mux2_32 mux_ld_offset(from_ag_ld_offset, offset1, offset2, load_addr_mux);
    mux2_32 mux_ld_slim(ld_slim1_or_2, to_ag_slim1, to_ag_slim2, load_addr_mux);
    mux2_32 mux_ld_slim_with_intex(from_ag_ld_slim, ld_slim1_or_2, 32'hffff_ffff, intex);

    mux2_32 mux_st_addr(from_ag_st_addr, addr1, addr2, store_addr_mux);
    mux2_32 mux_st_offset(from_ag_st_offset, offset1, offset2, store_addr_mux);
    mux2_32 mux_st_slim(from_ag_st_slim, to_ag_slim1, to_ag_slim2, store_addr_mux);
    
    
endmodule