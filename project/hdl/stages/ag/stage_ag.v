module stage_ag(
    input [61:0]    from_rr_control_sigs,
    input [2:0]     from_rr_dstidA,
    input [2:0]     from_rr_dstidB,
    input [31:0]    from_rr_srcregA,
    input [31:0]    from_rr_srcregB,
    input [31:0]    from_rr_srcregC,
    input [15:0]    from_rr_srcSREG,
    input [63:0]    from_rr_MMA,
    input [63:0]    from_rr_MMB,
    input [31:0]    from_rr_imm,
    input [15:0]    from_rr_sreg1,
    input [31:0]    from_rr_slim1,
    input [31:0]    from_rr_base1,
    input [31:0]    from_rr_index1,
    input [31:0]    from_rr_disp,
    input [1:0]     from_rr_scale_mux,
    input [15:0]    from_rr_sreg2,
    input [31:0]    from_rr_slim2,
    input [31:0]    from_rr_base2,
    input [3:0]     from_rr_intex_vec,
    input [15:0]    from_rr_cs,
    input [31:0]    from_rr_oeip,
    input [31:0]    from_rr_ieip,
    input           from_rr_valid,

    output [53:0]    to_mem_control_sigs,
    output [2:0]     to_mem_dstidA,
    output [2:0]     to_mem_dstidB,
    output [31:0]    to_mem_srcregA,
    output [31:0]    to_mem_srcregB,
    output [31:0]    to_mem_srcregC,
    output [15:0]    to_mem_srcSREG,
    output [63:0]    to_mem_MMA,
    output [63:0]    to_mem_MMB,

    output [15:0]    to_mem_target_cs,
    output [31:0]    to_mem_ld_addr,
    output [31:0]    to_mem_ld_offset,
    output [31:0]    to_mem_ld_slim,
    output [31:0]    to_mem_st_addr,
    output [31:0]    to_mem_st_offset,
    output [31:0]    to_mem_st_slim,
    output [31:0]    to_mem_inc_esp,
    output [31:0]    to_mem_dec_esp,
    output [31:0]    to_mem_imm,
    output [31:0]    to_mem_rel_eip,

    output [15:0]    to_mem_cs,
    output [31:0]    to_mem_oeip,
    output [31:0]    to_mem_ieip,
    output           to_mem_valid
);

    wire ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, stack_push, intex, seg_dst_mux, ret_with_imm;
    wire [1:0] ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux, mem_ds, imm_mux, addr_mux;
    wire [2:0] ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux;
    wire [3:0] gp_dsta_mux, store_data_mux;

    wire store_addr_mux, load_addr_mux;

    assign {load_addr_mux, store_addr_mux} = addr_mux;

    assign to_mem_control_sigs = {
        ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, seg_dst_mux,
        ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux, mem_ds,
        ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux,
        gp_dsta_mux, store_data_mux
    };
    
    assign to_mem_dstidA = from_rr_dstidA;
    assign to_mem_dstidB = from_rr_dstidB;
    assign to_mem_srcregA = from_rr_srcregA;
    assign to_mem_srcregB = from_rr_srcregB;
    assign to_mem_srcregC = from_rr_srcregC;
    assign to_mem_srcSREG = from_rr_srcSREG;
    assign to_mem_MMA = from_rr_MMA;
    assign to_mem_MMB = from_rr_MMB;
    assign to_mem_target_cs = from_rr_disp[15:0];
    assign to_mem_intex_vec = from_rr_intex_vec;
    assign to_mem_cs = from_rr_cs;
    assign to_mem_oeip = from_rr_oeip;
    assign to_mem_ieip = from_rr_ieip;
    assign to_mem_valid = from_rr_valid;


    // TODO: Add control signals into the ag_sig module
    ag_sig dut_sig (
        .ucode_sig(from_rr_control_sigs),
        .ldAB(ldAB), .dstA_size(dstA_size), .dstB_size(dstB_size), .ldREGS(ldREGS),
        .ldEFLAGS(ldEFLAGS), .ldEIP(ldEIP), .ldCS(ldCS),
        .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux), .eflags_mux(eflags_mux),
        .eip_mux(eip_mux), .cs_mux(cs_mux),
        .mmx_op(mmx_op), .alu_op(alu_op), .shf_op(shf_op), .cmps(cmps), .con_jmp(con_jmp),
        .cmpxchg(cmpxchg), .cmovc(cmovc),
        .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
        .store_data_mux(store_data_mux), .rw(rw),
        .ds(ds), .mem_ds(mem_ds), .imm_mux(imm_mux), .addr_mux(addr_mux), .stack_push(stack_push), .intex(intex), .ret_with_imm(ret_with_imm)
    );


    // ========= REL EIP LOGIC ===========
    wire [31:0] imm_se8, imm_se16, imm_ze16, imm_final;
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_imm8(.in(from_rr_imm[7:0]), .out(imm_se8));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_imm16(.in(from_rr_imm[15:0]), .out(imm_se16));
    ze #(.INP_WIDTH(16), .OUT_WIDTH(32)) ze_imm16(.in(from_rr_imm[15:0]), .out(imm_ze16));

    mux4_32 mux_imm(imm_final, imm_se8, imm_se16, imm_ze16, from_rr_imm, imm_mux[0], imm_mux[1]);
    PA_32b PA_rel_eip(.s(to_mem_rel_eip), .in0(from_rr_ieip), .in1(imm_final));
    
    assign to_mem_imm = imm_final;

    // ========= MEM ADDR LOGIC ===========
    wire [31:0] addr1, offset1, addr2, offset2, inc_esp, dec_esp;
    address_adder address_adder_inst (
        .scale_mux1(from_rr_scale_mux), .sreg1(from_rr_sreg1), .index1(from_rr_index1), .base1(from_rr_base1), .disp1(from_rr_disp),
        .stack_push(stack_push), .ret_with_imm(ret_with_imm), .imm(imm_final), .sreg2(from_rr_sreg2), .base2(from_rr_base2),
        .size_mux(ds),
        .addr1(addr1), .offset1(offset1),
        .addr2(addr2), .offset2(offset2), .inc_esp(inc_esp), .dec_esp(dec_esp)
    );

    assign to_mem_inc_esp = inc_esp;
    assign to_mem_dec_esp = dec_esp;

    wire [31:0] ze32_intex_vec, shifted_intex_vec, addr_intex_idtr;
    ze #(.INP_WIDTH(4), .OUT_WIDTH(32)) ze_intex_vec(.in(from_rr_intex_vec), .out(ze32_intex_vec));

    lshf_const #(.WIDTH(32), .SHF_AMT(3)) lshf3_intex_vec(.in(ze32_intex_vec), .out(shifted_intex_vec));
    PA_32b PA_intex_idtr(.s(addr_intex_idtr), .in0(32'h02000000), .in1(shifted_intex_vec));

    wire [31:0] ld_addr1_or_2;
    mux2_32 mux_ld_addr(ld_addr1_or_2, addr1, addr2, load_addr_mux);
    mux2_32 mux_ld_addr_with_intex(to_mem_ld_addr, ld_addr1_or_2, addr_intex_idtr, intex);
    mux2_32 mux_ld_offset(to_mem_ld_offset, offset1, offset2, load_addr_mux);
    mux2_32 mux_ld_slim(to_mem_ld_slim, from_rr_slim1, from_rr_slim2, load_addr_mux);

    mux2_32 mux_st_addr(to_mem_st_addr, addr1, addr2, store_addr_mux);
    mux2_32 mux_st_offset(to_mem_st_offset, offset1, offset2, store_addr_mux);
    mux2_32 mux_st_slim(to_mem_st_slim, from_rr_slim1, from_rr_slim2, store_addr_mux);
    
    
endmodule