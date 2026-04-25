module stage_rr #(
  parameter AG_CONTROL_SIGS_WIDTH=69
)(
    input       clk,
    input       rst_n,

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
    input [1:0]  to_rr_exception,
    input [95:0] to_rr_ucode_sigs,
    input to_rr_valid,

    input from_ag_stall_bar,
    input from_dep_unit_data_dep,
    input [8:0] from_dep_ag_fw_control_sigs,
    input [8:0] from_dep_mem_fw_control_sigs,
    input [8:0] from_dep_ex_fw_control_sigs,

    input from_ex_flush,
    input from_wb_flush,
    input from_ex_cmps_found,
    input interrupt,
    input [1:0] temp_exception,
    input [31:0] temp_eip,
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
    output  to_regunit_has_seg_prefix,

    input [15:0] from_regunit_srcSREG,
    input [15:0] from_regunit_SREG1,
    input [15:0] from_regunit_SREG2,
    input [31:0] from_regunit_SLIM1,
    input [31:0] from_regunit_SLIM2,
    input [15:0] from_regunit_CS,

    input [63:0] from_regunit_MMA,
    input [63:0] from_regunit_MMB,

    output [10:0] to_dep_needREGS,
    output [1:0]  from_rr_rw,
    output        from_rr_rep,

    output [AG_CONTROL_SIGS_WIDTH-1:0] from_rr_control_sigs,
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
    output from_rr_ucode_valid,
    output from_rr_stall
); 
    wire clear_int;
    // wire clear_int, pending_int;
    // pending_int pending_int_inst(
    //     .clk(clk),
    //     .rst_n(rst_n),
    //     .set_int(interrupt),
    //     .clear_int(clear_int),
    //     .pending_int(pending_int)
    // ); 

    wire [95:0] ucode_sig;

    wire movs_8, movs_32, movs, cmps, iret;
    big_eq #(.WIDTH(8)) eq_a4(.eq(movs_8), .in0(to_regunit_opcode), .in1(8'ha4));
    big_eq #(.WIDTH(8)) eq_a5(.eq(movs_32), .in0(to_regunit_opcode), .in1(8'ha5));
    or2$ or_movs(movs, movs_8, movs_32);
    big_eq #(.WIDTH(8)) eq_a7(.eq(cmps), .in0(to_regunit_opcode), .in1(8'ha7));
    big_eq #(.WIDTH(8)) eq_cf(.eq(iret), .in0(to_regunit_opcode), .in1(8'hcf));
    
    wire        ucode_stall_bar;

    wire movs0, movs1, cmps0, cmps1, cmps2;
    wire iret0;
    wire fsm_stall, intex, handling_intex;
    wire not_intex_or_iret;
    wire no_dep;
    nand2$ nand2_fsm_stall(fsm_stall, from_ag_stall_bar, no_dep);
    wire to_rr_prefix_0_buf16, to_rr_addr_mode_0_buf16;
    bufferH16$  bufferH16$_to_rr_prefix_0_buf16(to_rr_prefix_0_buf16, to_rr_prefix[0]);
    bufferH16$  bufferH16$_to_rr_addr_mode_0_buf16(to_rr_addr_mode_0_buf16, to_rr_addr_mode[0]);

    wire to_rr_valid_bar, rr_valid_and_not_flush;
    inv1$ inv1_to_rr_valid(to_rr_valid_bar, to_rr_valid);
    nor2$ nor2_rr_valid_and_not_flush(rr_valid_and_not_flush, to_rr_valid_bar, from_ex_flush);
    ucode_fsm ucode_fsm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .to_rr_ucode_sigs(to_rr_ucode_sigs),
        .to_rr_valid(rr_valid_and_not_flush),
        .rep(from_rr_rep),
        .stall(fsm_stall),
        .interrupt(1'b0),
        .exception(from_wb_flush),
        .movs(movs),
        .cmps(cmps),
        .iret(iret),
        .cmps_found(from_ex_cmps_found),
        .opcode(to_regunit_opcode),
        .ext_opcode(to_rr_prefix_0_buf16),
        .modrm(to_rr_modrm[7:6]),
        .has_modrm(to_rr_addr_mode_0_buf16),
        .reg_ecx(from_regunit_srcregA),
        .movs0(movs0),
        .movs1(movs1),
        .cmps0(cmps0),
        .cmps1(cmps1),
        .cmps2(cmps2),
        .iret0(iret0),
        .clear_int(clear_int),
        .intex(intex),
        .handling_intex(handling_intex),
        .ucode_stall_bar(ucode_stall_bar),
        .ucode_valid(from_rr_ucode_valid),
        .ucode_sig(ucode_sig),
        .not_intex_or_iret(not_intex_or_iret)
    );

    bufferH16$  bufferH16$_from_rr_rep(from_rr_rep, to_rr_prefix[5]);
    
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
    wire to_rr_prefix_4_buf16;
    bufferH16$  bufferH16$_to_rr_prefix_4_buf16(to_rr_prefix_4_buf16, to_rr_prefix[4]);
    and4$ and_ds16(set_ds_16, ds_is_32, to_rr_prefix_4_buf16, to_rr_valid, not_intex_or_iret);
    mux2$ mux_ds_override[1:0](ds_with_override, ds, 2'b01, set_ds_16);

    wire mem_ds1_inv, mem_ds_is_32, set_mem_ds_16;
    inv1$ inv_mem_ds1(mem_ds1_inv, mem_ds[1]);
    nor2$ nor2_mem_ds32(mem_ds_is_32, mem_ds1_inv, mem_ds[0]);
    and4$ and_mem_ds16(set_mem_ds_16, mem_ds_is_32, to_rr_prefix_4_buf16, to_rr_valid, not_intex_or_iret);
    mux2$ mux_mem_ds_override16[1:0](mem_ds_override_16, mem_ds, 2'b01, set_mem_ds_16);

    wire mem_ds_is_64, set_mem_ds_32;
    wire [1:0] mem_ds_with_override;
    and2$ and_mem_ds_64(mem_ds_is_64, mem_ds[1], mem_ds[0]);
    and4$ and_ds32(set_mem_ds_32, mem_ds_is_64, to_rr_prefix_4_buf16, to_rr_valid, not_intex_or_iret);
    mux2$ mux_mem_ds_override[1:0](mem_ds_with_override, mem_ds_override_16, 2'b10, set_mem_ds_32);

    wire stack_push;
    
    wire gp_dstb_mux1_inv, gp_dstb_mux_is_010;
    inv1$ inv_gp_dstb_mux(gp_dstb_mux1_inv, gp_dstb_mux[1]);
    nor3$ nor_gp_dstb_mux_is_010(gp_dstb_mux_is_010, gp_dstb_mux[0], gp_dstb_mux1_inv, gp_dstb_mux[2]);

    assign stack_push = gp_dstb_mux_is_010;

    bufferH64$  bufferH64$_to_regunit_opcode[7:0](to_regunit_opcode, to_rr_opcode); 
    bufferH16$  bufferH16$_to_regunit_modrm[5:0](to_regunit_modrm, to_rr_modrm[5:0]);
    assign to_regunit_sib = to_rr_sib[5:0];
    bufferH16$ bufferH16$_to_regunit_has_sib(to_regunit_has_sib, to_rr_addr_mode[1]);
    assign to_regunit_sig_gprd0_mux = gprd0_mux;
    assign to_regunit_sig_gprd1_mux = gprd1_mux;
    assign to_regunit_sig_gprd2_mux = gprd2_mux;
    assign to_regunit_sig_srcregA_mux = srcregA_mux;
    assign to_regunit_sig_srcregB_mux = srcregB_mux;
    bufferH16$ bufferH16$_to_regunit_sig_ds[1:0](to_regunit_sig_ds, ds_with_override);
    assign to_regunit_sig_srcsreg_mux = srcsreg_mux;
    assign to_regunit_sig_segrd0_mux = segrd0_mux;
    assign to_regunit_sig_segrd1_mux = segrd1_mux;

    wire [1:0] dstA_size, dstB_size;
    wire [1:0] mmx_op, con_jmp;
    wire [2:0] alu_op;
    wire shf_op, cmpxchg, cmovc, palu_size, sbb_dir;
    
    // dstA_size = 32 if dstidA_mux=101/110(ESI/ECX) else ds
    // dstB_size = ds if dstidB_mux=01/10(regr/EAX) else 32
    wire dstidA_xor_10, dstidA_size_32, dstidB_0_inv, dstidB_size_ds;
    xor2$ xor_dstidA10(dstidA_xor_10, dstidA_mux[1], dstidA_mux[0]);
    and2$ and_dstidA_size_32(dstidA_size_32, dstidA_xor_10, dstidA_mux[2]);
    mux2$ mux2_dstA_size[1:0](dstA_size, ds_with_override, 2'b10, dstidA_size_32);

    xor2$ xor_dstidB_size_ds(dstidB_size_ds, dstidB_mux[1], dstidB_mux[0]);
    mux2$ mux2_dstB_size[1:0](dstB_size, 2'b10, ds_with_override, dstidB_size_ds);


    wire [3:0] ff_store_data_mux, from_rr_store_data_mux;
    wire [1:0] ff_from_rr_rw;
    wire ff_from_rr_ldEIP, from_rr_ldEIP;
    wire ff_ldB, ff_from_rr_ldB;
    wire opcode_ff, opcode_ff_low, opcode_ff_high, opcode_ff_bar;
    and4$ and4$_opcode_ff_low(opcode_ff_low, to_regunit_opcode[0], to_regunit_opcode[1], to_regunit_opcode[2], to_regunit_opcode[3]);
    and4$ and4$_opcode_ff_high(opcode_ff_high, to_regunit_opcode[4], to_regunit_opcode[5], to_regunit_opcode[6], to_regunit_opcode[7]);
    nand2$  nand2$_opcode_ff_bar(opcode_ff_bar, opcode_ff_low, opcode_ff_high);
    bufferHInv16$ bufferHInv16$_opcode_ff(opcode_ff, opcode_ff_bar);
    mux4$ mux4_store_data_mux[3:0](ff_store_data_mux, 4'bx, 4'b0001, 4'bx, 4'b1100, to_regunit_modrm[4], to_regunit_modrm[5]);
    mux4$ mux4_rw(ff_from_rr_rw[0], 1'bx, 1'b1, 1'b0, 1'b1, to_regunit_modrm[4], to_regunit_modrm[5]);
    assign ff_from_rr_rw[1] = rm;
    mux4$ mux4_ff_ldB(ff_ldB, 1'bx, 1'b1, 1'b0, 1'b1, to_regunit_modrm[4], to_regunit_modrm[5]);
    mux4$ mux4_ldEIP(ff_from_rr_ldEIP, 1'bx, 1'b1, 1'b1, 1'b0, to_regunit_modrm[4], to_regunit_modrm[5]);

    mux2$ mux2_store_data_mux[3:0](from_rr_store_data_mux, store_data_mux, ff_store_data_mux, opcode_ff);
    mux2$ mux2_rw[1:0](from_rr_rw, rw, ff_from_rr_rw, opcode_ff);
    mux2$ mux2_ldEIP(from_rr_ldEIP, ldEIP, ff_from_rr_ldEIP, opcode_ff);
    mux2$ mux2_ldB(ff_from_rr_ldB, ldAB[0], ff_ldB, opcode_ff);
    wire ret_with_imm;
    big_eq #(.WIDTH(7)) eq_ret_with_imm(.eq(ret_with_imm), .in0({to_regunit_opcode[7:4], to_regunit_opcode[2:0]}), .in1(7'h62));
    assign from_rr_control_sigs={{ldAB[1], ff_from_rr_ldB}, dstA_size, dstB_size, ldREGS, ldEFLAGS,
                     from_rr_ldEIP, ldCS, alu_srcb_mux, shf_srcb_mux, eflags_mux, eip_mux, cs_mux,
                     mmx_op, alu_op, shf_op, movs0, movs1, cmps0, cmps1, cmps2, con_jmp, cmpxchg, cmovc,
                     gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux, from_rr_store_data_mux, from_rr_rw, ds_with_override, 
                     mem_ds_with_override, imm_mux, addr_mux, stack_push, intex, ret_with_imm, rm, to_rr_prefix_4_buf16, palu_size, sbb_dir, iret0,
                     from_dep_ag_fw_control_sigs, from_dep_mem_fw_control_sigs, from_dep_ex_fw_control_sigs};

    assign mmx_op = {to_regunit_opcode[7], to_regunit_opcode[2]};
    wire pack_size, padd_size, pavg_size;
    assign pack_size = to_regunit_opcode[3];
    assign padd_size = to_regunit_opcode[1];
    assign pavg_size = to_regunit_opcode[0];
    mux4$ mux4_palu_size(palu_size, pack_size, 1'bx, pavg_size, padd_size, mmx_op[0], mmx_op[1]);
    assign shf_op = to_regunit_modrm[4];
    big_eq #(.WIDTH(8)) eq_1b(.eq(sbb_dir), .in0(to_regunit_opcode), .in1(8'h1B));

    mux2$ mux2_aluop[2:0](alu_op, to_regunit_opcode[5:3], to_regunit_modrm[5:3], to_regunit_opcode[7]);
    wire opcode_77, opcode_87, opcode_75, opcode_85, opcode_jnbe, opcode_jne;
    big_eq #(.WIDTH(8)) eq_77(.eq(opcode_77), .in0(to_regunit_opcode), .in1(8'h77));
    big_eq #(.WIDTH(8)) eq_87(.eq(opcode_87), .in0(to_regunit_opcode), .in1(8'h87));
    big_eq #(.WIDTH(8)) eq_75(.eq(opcode_75), .in0(to_regunit_opcode), .in1(8'h75));
    big_eq #(.WIDTH(8)) eq_85(.eq(opcode_85), .in0(to_regunit_opcode), .in1(8'h85));

    or2$ or_opcode_jnbe(opcode_jnbe, opcode_77, opcode_87);
    or2$ or_opcode_jne(opcode_jne, opcode_75, opcode_85);
    assign con_jmp = {opcode_jnbe, opcode_jne};

    wire opcode_B0;
    big_eq #(.WIDTH(5)) eq_B0(.eq(opcode_B0), .in0(to_regunit_opcode[7:3]), .in1(5'b10110));
    and2$ and_cmpxchg(cmpxchg, to_rr_prefix[0], opcode_B0);

    wire opcode_42;
    big_eq #(.WIDTH(8)) eq_42(.eq(opcode_42), .in0(to_regunit_opcode), .in1(8'h42));
    and2$ and_cmovc(cmovc, to_rr_prefix[0], opcode_42);
    
    wire [4:0] from_rr_dstidA_dummy;
    mux8_8 mux8_8_dstidA
    (
      {from_rr_dstidA_dummy, from_rr_dstidA}, 
      8'd0, 
      {5'd0, to_regunit_modrm[2:0]}, 
      {5'd0, to_regunit_modrm[5:3]}, 
      {5'd0, to_regunit_opcode[2:0]}, 
      {5'd0, to_regunit_opcode[5:3]}, 
      8'b00000110, 
      8'b00000001, 
      , 
      dstidA_mux[0], 
      dstidA_mux[1], 
      dstidA_mux[2]
    );
    mux4$ mux4_dstidB[2:0](from_rr_dstidB, 3'b100, to_regunit_modrm[5:3], 3'b000, 3'b111, dstidB_mux[0], dstidB_mux[1]);

    assign from_rr_srcregA=from_regunit_srcregA;
    assign from_rr_srcregB=from_regunit_srcregB;
    assign from_rr_srcregC=from_regunit_srcregC;
    assign from_rr_srcSREG=from_regunit_srcSREG;
    assign from_rr_MMA=from_regunit_MMA;
    assign from_rr_MMB=from_regunit_MMB;
    assign from_rr_imm=to_rr_imm[31:0];
    assign from_rr_sreg1=from_regunit_SREG1;
    assign to_regunit_seg_prefix=to_rr_prefix[3:1];
    assign to_regunit_has_seg_prefix=to_rr_prefix[6];
    // assign from_rr_slim1=from_regunit_SLIM1;

    wire mod_00, rm1_inv, rm_101, base_none, base_none_bar;
    wire index2_inv, index_100_inv, index_none, index_none_prebuf;
    nor2$ nor_mod00(mod_00, to_rr_modrm[7], to_rr_modrm[6]);
    inv1$ inv_rm1(rm1_inv, to_regunit_modrm[1]);
    and3$ and_rm101(rm_101, to_regunit_modrm[2], rm1_inv, to_regunit_modrm[0]);
    nand2$ nand_base_none_bar(base_none_bar, rm_101, mod_00);
    bufferHInv64$  bufferHInv64$_base_none(base_none, base_none_bar);

    inv1$ inv_index2(index2_inv, to_rr_sib[2]);
    or3$ or_index100(index_100_inv, index2_inv, to_rr_sib[1], to_rr_sib[0]);
    nand2$ nand_index_none(index_none_prebuf, to_rr_addr_mode[1], index_100_inv);
    bufferH64$  bufferH64$_index_none(index_none, index_none_prebuf);

    mux2$ mux2_basereg1[31:0](from_rr_base1, from_regunit_basereg1, 32'b0, base_none);
    mux2$ mux2_index1[31:0](from_rr_index1, from_regunit_indexreg1, 32'b0, index_none);
    
    wire need_bs1, need_idx;
    mux2$ mux2_need_bs1(need_bs1, needREGS[7], 1'b0, base_none);
    mux2$ mux2_need_idx(need_idx, needREGS[5], 1'b0, index_none);
    
    wire [31:0] disp8_se, disp_normal, disp_ptr;
    se se_disp(.out(disp8_se), .in(to_rr_disp[7:0]));
    mux3_32 mux3_disp(.out(disp_normal), .in0(32'b0), .in1(disp8_se), .in2(to_rr_disp), .s0(to_rr_dispsize[0]), .s1(to_rr_dispsize[1]));
    mux2_32 mux2_disp_ptr(.out(disp_ptr), .in0({16'b0, to_rr_imm[47:32]}), .in1({16'b0, to_rr_imm[31:16]}), .s0(to_rr_prefix_4_buf16)) ;

    wire disp_is_ptr; // opcode=9A/EA
    wire opcode_9a, opcode_ea;
    big_eq #(.WIDTH(8)) eq_9a(.eq(opcode_9a), .in0(to_regunit_opcode), .in1(8'h9A));
    big_eq #(.WIDTH(8)) eq_ea(.eq(opcode_ea), .in0(to_regunit_opcode), .in1(8'hEA));
    or2$ or_is_ptr(disp_is_ptr, opcode_9a, opcode_ea);
    // and2$ and_immsize48(disp_is_ptr, to_rr_imm_size[2], to_rr_imm_size[1]);
    mux2_32 mux2_disp_value(.out(from_rr_disp), .in0(disp_normal), .in1(disp_ptr), .s0(disp_is_ptr));

    mux2$ mux2_scale[1:0](from_rr_scale_mux, 2'b00, to_rr_sib[7:6], to_rr_addr_mode[1]);

    assign from_rr_slim1 = from_regunit_SLIM1;
    assign from_rr_slim2 = from_regunit_SLIM2;

    assign from_rr_sreg2=from_regunit_SREG2;
    // assign from_rr_slim2=from_regunit_SLIM2;
    assign from_rr_base2=from_regunit_basereg2;
    // assign from_rr_intex_vec=4'b0; // TODO: ASSIGN intex

    /*** intex_vec ***/
    wire is_exception;
    or2$ or2_is_exception(is_exception, temp_exception[1], temp_exception[0]);
    wire [3:0] exception_vec;
    mux2$ mux2_exception_vec[3:0](exception_vec, 4'b1110, 4'b1101, temp_exception[1]);
    mux2$ mux2_intex_vec[3:0](from_rr_intex_vec, 4'b0010, exception_vec, is_exception);

    mux2_32 mux2_oeip(from_rr_oeip, to_rr_oeip, temp_eip, handling_intex);
    // assign from_rr_oeip=to_rr_oeip;
    assign from_rr_ieip=to_rr_ieip;
    assign from_rr_cs=from_regunit_CS;
    
    assign from_rr_pred_eip = to_rr_pred_eip;
    // assign from_rr_exception = to_rr_exception;

    mux2$ mux2_from_rr_exception[1:0](from_rr_exception, to_rr_exception, 2'b00, handling_intex);
    // if data_dep: bubble -> valid = 0
    // from_rr_valid = to_rr_valid & ~data_dep
    wire is_hlt, is_hlt_valid_bar, is_not_hlt, valid_dep_bar;
    nand2$ valid_data_dep_bar(valid_dep_bar, from_rr_ucode_valid, from_dep_unit_data_dep);
    inv1$ inv_dep(no_dep, from_dep_unit_data_dep);

    big_eq #(
      .WIDTH(8)
    ) big_eq_is_hlt (
      .in0(to_regunit_opcode), .in1(8'hF4),
      .eq(is_hlt)
    );

    nand2$ nand2$_is_hlt_valid_bar(is_hlt_valid_bar, is_hlt, from_rr_ucode_valid);

    big_neq #(
      .WIDTH(8)
    ) big_neq_is_not_hlt (
      .in0(to_regunit_opcode), .in1(8'hF4),
      .neq(is_not_hlt)
    );

    and2$ and_valid(from_rr_valid, from_rr_ucode_valid, no_dep);

    /* TODO: ADD STALL LOGIC */
    nand4$ nand_from_rr_stall(from_rr_stall, ucode_stall_bar, from_ag_stall_bar, valid_dep_bar, is_hlt_valid_bar);

    bufferH16$  bufferH16$_to_dep_needREGS[10:0](to_dep_needREGS, {needREGS[10:8], need_bs1, needREGS[6], need_idx, needREGS[4:0]});
    assign from_rr_we_pipe_reg = from_ag_stall_bar;
endmodule