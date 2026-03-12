module stage_rr(
    input [4:0] from_de_prefix,
    input from_de_ext_opcode,
    input [7:0] from_de_opcode,
    input [7:0] from_de_modrm,
    input [7:0] from_de_sib,
    input [31:0] from_de_disp,
    input [1:0] from_de_dispsize,
    input [47:0] from_de_imm,
    input [1:0] from_de_imm_size,
    input [1:0] from_de_addr_mode,
    input [31:0] from_de_oeip,
    input [31:0] from_de_ieip,
    input from_de_valid,

    output [7:0]  to_regunit_opcode,
    output [5:0]  to_regunit_modrm,
    output [5:0]  to_regunit_sib,
    output        to_regunit_has_sib,
    output [2:0]  to_regunit_sig_gprd0_mux,
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
    input [19:0] from_regunit_SLIM1,
    input [19:0] from_regunit_SLIM2,
    input [15:0] from_regunit_CS,

    input [63:0] from_regunit_MMA,
    input [63:0] from_regunit_MMB,

    output [10:0] to_dep_needREGS,

    output [52:0] to_ag_control_sigs,
    output [2:0] to_ag_dstidA,
    output [2:0] to_ag_dstidB,
    output [31:0] to_ag_srcregA,
    output [31:0] to_ag_srcregB,
    output [31:0] to_ag_srcregC,
    output [15:0] to_ag_srcSREG,
    output [63:0] to_ag_MMA,
    output [63:0] to_ag_MMB,
    output [31:0] to_ag_imm,
    output [15:0] to_ag_sreg1,
    output [31:0] to_ag_slim1,
    output [31:0] to_ag_base1,
    output [31:0] to_ag_index1,
    output [31:0] to_ag_disp,
    output [1:0]  to_ag_scale_mux,
    output [15:0] to_ag_sreg2,
    output [31:0] to_ag_slim2,
    output [31:0] to_ag_base2,
    output to_ag_intex_vec,
    output [15:0] to_ag_cs,
    output [31:0] to_ag_oeip,
    output [31:0] to_ag_ieip,
    output to_ag_valid
); 
    wire [63:0] ucode_sig;
    ucode_controller uctlr (.ucode_sig(ucode_sig), 
                            .opcode(from_de_opcode), 
                            .ext_opcode(from_de_ext_opcode),
                            .modrm(from_de_modrm[7:6]),
                            .has_modrm(from_de_addr_mode[0])
                           );

    wire [1:0] ldAB, dstidB_mux, gprd2_mux, shf_srcb_mux, cs_mux, mm_dst_mux, rw, ds;
    wire [2:0] dstidA_mux, gprd0_mux, ldREGS, eflags_mux, eip_mux, gp_dstb_mux;
    wire srcregA_mux, srcregB_mux, ldEFLAGS, alu_srcb_mux, ldEIP, ldCS, seg_dst_mux, srcsreg_mux, segrd0_mux, segrd1_mux;
    wire [10:0] needREGS;
    wire [3:0] gp_dsta_mux, store_data_mux;
    
    rr_sig rr_sig_dut(
    .ucode_sig(ucode_sig), .ldAB(ldAB), .dstidA_mux(dstidA_mux), .dstidB_mux(dstidB_mux),
    .srcregA_mux(srcregA_mux), .srcregB_mux(srcregB_mux), .gprd0_mux(gprd0_mux), .gprd2_mux(gprd2_mux), .srcsreg_mux(srcsreg_mux), .segrd0_mux(segrd0_mux), .segrd1_mux(segrd1_mux),
    .ldREGS(ldREGS), .needREGS(needREGS), .ldEFLAGS(ldEFLAGS),
    .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux),
    .ldEIP(ldEIP), .ldCS(ldCS), .eflags_mux(eflags_mux), .eip_mux(eip_mux), .cs_mux(cs_mux),
    .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
    .store_data_mux(store_data_mux), .rw(rw), .ds(ds)
    );
    
    wire [1:0] ds_with_override;
    wire ds1_inv, ds_is_32, set_ds_16;
    inv1$ inv_ds1(ds1_inv, ds[1]);
    nor2$ nor2_ds32(ds_is_32, ds1_inv, ds[0]);
    and2$ and_ds16(set_ds_16, ds_is_32, from_de_prefix[3]);
    mux2$ mux_ds_override[1:0](ds_with_override, ds, 2'b01, set_ds_16);

    assign to_regunit_opcode = from_de_opcode;          
    assign to_regunit_modrm = from_de_modrm[5:0];
    assign to_regunit_sib = from_de_sib[5:0];
    assign to_regunit_has_sib = from_de_addr_mode[1];
    assign to_regunit_sig_gprd0_mux = gprd0_mux;
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
    wire shf_op, cmps, cmpxchg, cmovc;
    
    // dstA_size = 32 if dstidA_mux=101/110(ESI/ECX) else ds
    // dstB_size = ds if dstidB_mux=01(regr) else 32
    wire dstidA_xor_10, dstidA_size_32, dstidB_0_inv, dstidB_size_ds;
    xor2$ xor_dstidA10(dstidA_xor_10, dstidA_mux[1], dstidA_mux[0]);
    and2$ and_dstidA_size_32(dstidA_size_32, dstidA_xor_10, dstidA_mux[2]);
    mux2$ mux2_dstA_size[1:0](dstA_size, ds_with_override, 2'b10, dstidA_size_32);

    inv1$ inv_dstidB0(dstidB_0_inv, dstidB_mux[0]);
    nor2$ nor_dstidB_size_ds(dstidB_size_ds, dstidB_mux[1], dstidB_0_inv);
    mux2$ mux2_dstB_size[1:0](dstB_size, 2'b10, ds_with_override, dstidB_size_ds);


    wire [3:0] ff_store_data_mux, to_ag_store_data_mux;
    wire [1:0] ff_to_ag_rw, to_ag_rw;
    wire ff_to_ag_ldEIP, to_ag_ldEIP;

    wire opcode_ff;
    big_and #(.WIDTH(8)) and_opcode_ff(opcode_ff, from_de_opcode);
    mux4$ mux4_store_data_mux[3:0](ff_store_data_mux, 4'bx, 4'b0001, 4'bx, 4'b1010, from_de_modrm[4], from_de_modrm[5]);
    mux4$ mux4_rw[1:0](ff_to_ag_rw, 2'bx, 2'b11, 2'b10, 2'b11, from_de_modrm[4], from_de_modrm[5]);
    mux4$ mux4_ldEIP(ff_to_ag_ldEIP, 1'bx, 1'b1, 1'b1, 1'b0, from_de_modrm[4], from_de_modrm[5]);

    mux2$ mux2_store_data_mux[3:0](to_ag_store_data_mux, store_data_mux, ff_store_data_mux, opcode_ff);
    mux2$ mux2_rw[1:0](to_ag_rw, rw, ff_to_ag_rw, opcode_ff);
    mux2$ mux2_ldEIP(to_ag_ldEIP, ldEIP, ff_to_ag_ldEIP, opcode_ff);

    assign to_ag_control_sigs={ldAB, dstA_size, dstB_size, ldREGS, ldEFLAGS,
                     to_ag_ldEIP, ldCS, alu_srcb_mux, shf_srcb_mux, eflags_mux, eip_mux, cs_mux,
                     mmx_op, alu_op, shf_op, cmps, con_jmp, cmpxchg, cmovc,
                     gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux, to_ag_store_data_mux, to_ag_rw, ds_with_override};

    assign mmx_op = {from_de_opcode[7], from_de_opcode[2]};
    assign shf_op = from_de_modrm[5];
    assign cmps = 1'b0; // TODO: FIX CMPS

    mux2$ mux2_aluop[2:0](alu_op, from_de_opcode[5:3], from_de_modrm[5:3], from_de_opcode[7]);
    wire opcode_77, opcode_87, opcode_75, opcode_85, opcode_jnbe, opcode_jne;
    big_eq #(.WIDTH(8)) eq_77(.eq(opcode_77), .in0(from_de_opcode), .in1(8'h77));
    big_eq #(.WIDTH(8)) eq_87(.eq(opcode_87), .in0(from_de_opcode), .in1(8'h87));
    big_eq #(.WIDTH(8)) eq_75(.eq(opcode_75), .in0(from_de_opcode), .in1(8'h75));
    big_eq #(.WIDTH(8)) eq_85(.eq(opcode_85), .in0(from_de_opcode), .in1(8'h85));

    or2$ or_opcode_jnbe(opcode_jnbe, opcode_77, opcode_87);
    or2$ or_opcode_jne(opcode_jne, opcode_75, opcode_85);
    assign con_jmp = {opcode_jnbe, opcode_jne};

    wire opcode_B0;
    big_eq #(.WIDTH(5)) eq_B0(.eq(opcode_B0), .in0(from_de_opcode[7:3]), .in1(5'b10110));
    and2$ and_cmpxchg(cmpxchg, from_de_ext_opcode, opcode_B0);

    wire opcode_42;
    big_eq #(.WIDTH(8)) eq_42(.eq(opcode_42), .in0(from_de_opcode), .in1(8'h42));
    and2$ and_cmovc(cmovc, from_de_ext_opcode, opcode_42);
    
    mux8 mux8_dstidA[2:0](to_ag_dstidA, 3'b000, from_de_modrm[2:0], from_de_modrm[5:3], from_de_opcode[2:0], from_de_opcode[5:3], 3'b110, 3'b001, , dstidA_mux[0], dstidA_mux[1], dstidA_mux[2]);
    mux4$ mux4_dstidB[2:0](to_ag_dstidB, 3'b100, from_de_modrm[5:3], 3'b000, 3'b111, dstidB_mux[0], dstidB_mux[1]);

    assign to_ag_srcregA=from_regunit_srcregA;
    assign to_ag_srcregB=from_regunit_srcregB;
    assign to_ag_srcregC=from_regunit_srcregC;
    assign to_ag_srcSREG=from_regunit_srcSREG;
    assign to_ag_MMA=from_regunit_MMA;
    assign to_ag_MMB=from_regunit_MMB;
    assign to_ag_imm=from_de_imm[31:0];
    assign to_ag_sreg1=from_regunit_SREG1;
    assign to_regunit_seg_prefix=from_de_prefix[2:0];
    // assign to_ag_slim1=from_regunit_SLIM1;

    wire mod_00, rm1_inv, rm_101, base_none;
    wire index2_inv, index_100_inv, index_none;
    nor2$ nor_mod00(mod_00, from_de_modrm[7], from_de_modrm[6]);
    inv1$ inv_rm1(rm1_inv, from_de_modrm[1]);
    and3$ and_rm101(rm_101, from_de_modrm[2], rm1_inv, from_de_modrm[0]);
    and2$ and_base_none(base_none, rm_101, mod_00);

    inv1$ inv_index2(index2_inv, from_de_sib[2]);
    or3$ or_index100(index_100_inv, index2_inv, from_de_sib[1], from_de_sib[0]);
    nand2$ and_index_none(index_none, from_de_addr_mode[1], index_100_inv);

    mux2$ mux2_basereg1[31:0](to_ag_base1, from_regunit_basereg1, 32'b0, base_none);
    mux2$ mux2_index1[31:0](to_ag_index1, from_regunit_indexreg1, 32'b0, index_none);
    
    wire need_bs1, need_idx;
    mux2$ mux2_need_bs1(need_bs1, needREGS[7], 1'b0, base_none);
    mux2$ mux2_need_idx(need_idx, needREGS[5], 1'b0, index_none);
    
    wire [31:0] disp8_se, disp_normal, disp_ptr;
    se se_disp(.out(disp8_se), .in(from_de_disp[7:0]));
    mux3_32 mux3_disp(.out(disp_normal), .in0(32'b0), .in1(disp8_se), .in2(from_de_disp), .s0(from_de_dispsize[0]), .s1(from_de_dispsize[1]));
    mux2_32 mux2_disp_ptr(.out(disp_ptr), .in0({16'b0, from_de_imm[47:32]}), .in1({16'b0, from_de_imm[31:16]}), .s0(from_de_prefix[3])) ;

    wire disp_is_ptr;
    and2$ and_immsize48(disp_is_ptr, from_de_imm_size[1], from_de_imm_size[0]);
    mux2_32 mux2_disp_value(.out(to_ag_disp), .in0(disp_normal), .in1(disp_ptr), .s0(disp_is_ptr));

    mux2$ mux2_scale[1:0](to_ag_scale_mux, 2'b00, from_de_sib[7:6], from_de_addr_mode[1]);

    ze #(.INP_WIDTH(20),.OUT_WIDTH(32)) ze_slim1(.in(from_regunit_SLIM1), .out(to_ag_slim1));
    ze #(.INP_WIDTH(20),.OUT_WIDTH(32)) ze_slim2(.in(from_regunit_SLIM2), .out(to_ag_slim2));
    assign to_ag_sreg2=from_regunit_SREG2;
    // assign to_ag_slim2=from_regunit_SLIM2;
    assign to_ag_base2=from_regunit_basereg2;
    assign to_ag_intex_vec=1'b0; // TODO: ASSIGN intex
    assign to_ag_oeip=from_de_oeip;
    assign to_ag_ieip=from_de_ieip;
    assign to_ag_cs = from_regunit_CS;
    assign to_ag_valid=from_de_valid; // TODO: bubble unit
    
    assign to_dep_needREGS = {needREGS[10:8], need_bs1, needREGS[6], need_idx, needREGS[4:0]};
    
endmodule