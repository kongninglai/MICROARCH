module ag_to_mem_tb;

    initial begin
        $vcdplusfile("ag_to_mem_tb.dump.vpd");
        $vcdpluson(0, ag_to_mem_tb); 
    end

    integer i;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    reg clk;
    reg rst_n;

    reg [5:0] to_rr_prefix;
    reg [7:0] to_rr_opcode;
    reg [7:0] to_rr_modrm;
    reg [7:0] to_rr_sib;
    reg [31:0] to_rr_disp;
    reg [1:0] to_rr_dispsize;
    reg [47:0] to_rr_imm;
    reg [2:0] to_rr_imm_size;
    reg [1:0] to_rr_addr_mode;
    reg [31:0] to_rr_oeip;
    reg [31:0] to_rr_ieip;
    reg [31:0] to_rr_pred_eip;
    reg [1:0] to_rr_exception;
    reg to_rr_valid;

    wire from_ag_stall;

    wire [7:0] to_regunit_opcode;
    wire [5:0] to_regunit_modrm;
    wire [5:0] to_regunit_sib;
    wire to_regunit_has_sib;
    wire [1:0] to_regunit_sig_gprd0_mux;
    wire to_regunit_sig_gprd1_mux;
    wire [1:0] to_regunit_sig_gprd2_mux;
    wire to_regunit_sig_srcregA_mux;
    wire to_regunit_sig_srcregB_mux;
    wire [1:0] to_regunit_sig_ds;
    wire [31:0] from_regunit_srcregA;
    wire [31:0] from_regunit_srcregB;
    wire [31:0] from_regunit_srcregC;
    wire [31:0] from_regunit_basereg1;
    wire [31:0] from_regunit_indexreg1;
    wire [31:0] from_regunit_basereg2;
    wire to_regunit_sig_srcsreg_mux;
    wire to_regunit_sig_segrd0_mux;
    wire to_regunit_sig_segrd1_mux;
    wire [2:0] to_regunit_seg_prefix;
    wire [15:0] from_regunit_srcSREG;
    wire [15:0] from_regunit_SREG1;
    wire [15:0] from_regunit_SREG2;
    wire [31:0] from_regunit_SLIM1;
    wire [31:0] from_regunit_SLIM2;
    wire [15:0] from_regunit_CS;
    wire [63:0] from_regunit_MMA;
    wire [63:0] from_regunit_MMB;
    wire [64:0] from_rr_control_sigs;
    wire [2:0] from_rr_dstidA;
    wire [2:0] from_rr_dstidB;
    wire [31:0] from_rr_srcregA;
    wire [31:0] from_rr_srcregB;
    wire [31:0] from_rr_srcregC;
    wire [15:0] from_rr_srcSREG;
    wire [63:0] from_rr_MMA;
    wire [63:0] from_rr_MMB;
    wire [31:0] from_rr_imm;
    wire [15:0] from_rr_sreg1;
    wire [31:0] from_rr_slim1;
    wire [31:0] from_rr_base1;
    wire [31:0] from_rr_index1;
    wire [31:0] from_rr_disp;
    wire [1:0]  from_rr_scale_mux;
    wire [15:0] from_rr_sreg2;
    wire [31:0] from_rr_slim2;
    wire [31:0] from_rr_base2;
    wire [3:0] from_rr_intex_vec;
    wire [15:0] from_rr_cs;
    wire [31:0] from_rr_oeip;
    wire [31:0] from_rr_ieip;
    wire [31:0] from_rr_pred_eip;
    wire [1:0] from_rr_exception;
    wire from_rr_valid;

    wire from_rr_stall;

    wire [10:0] to_dep_needREGS;

    wire [31:0] from_regunit_cs_limit;

    reg [2:0] from_wb_gpwr0_idx;
    reg [31:0] from_wb_gpwr0_data;
    reg [1:0] from_wb_gpwr0_size;
    reg from_wb_gpwr0_en;
    reg [2:0] from_wb_gpwr1_idx;
    reg [31:0] from_wb_gpwr1_data;
    reg [1:0] from_wb_gpwr1_size;
    reg from_wb_gpwr1_en;
    reg [2:0] from_wb_segwr_idx;
    reg [15:0] from_wb_segwr_data;
    reg from_wb_segwr_en;
    reg [15:0] from_ex_cs_wr_data;
    reg from_ex_cs_wr_en;
    reg [2:0] from_wb_mmxwr_idx;
    reg [63:0] from_wb_mmxwr_data;
    reg from_wb_mmxwr_en;

    wire [2:0] to_dep_srcregA_idx;
    wire [2:0] to_dep_srcregB_idx;
    wire [2:0] to_dep_srcregC_idx;
    wire [2:0] to_dep_basereg1_idx;
    wire [2:0] to_dep_indexreg1_idx;
    wire [2:0] to_dep_basereg2_idx;
    wire [2:0] to_dep_srcSREG_idx;
    wire [2:0] to_dep_SREG1_idx;
    wire [2:0] to_dep_SREG2_idx;
    wire [2:0] to_dep_MMA_idx;
    wire [2:0] to_dep_MMB_idx;

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

    stage_rr dut_rr (
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
        .to_dep_needREGS(to_dep_needREGS)
    );

    rr_to_ag dut_rr_to_ag (
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
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
    regunit dut_regunit (
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
        .to_dep_srcregB_idx(to_dep_srcregB_idx),
        .to_dep_srcregC_idx(to_dep_srcregC_idx),
        .to_dep_basereg1_idx(to_dep_basereg1_idx),
        .to_dep_indexreg1_idx(to_dep_indexreg1_idx),
        .to_dep_basereg2_idx(to_dep_basereg2_idx),
        .from_rr_sig_srcsreg_mux(to_regunit_sig_srcsreg_mux),
        .from_rr_sig_segrd0_mux(to_regunit_sig_segrd0_mux),
        .from_rr_sig_segrd1_mux(to_regunit_sig_segrd1_mux),
        .from_rr_seg_prefix(to_regunit_seg_prefix),
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
        .from_ex_cs_wr_data(from_ex_cs_wr_data),
        .from_ex_cs_wr_en(from_ex_cs_wr_en),
        .from_wb_mmxwr_idx(from_wb_mmxwr_idx),
        .from_wb_mmxwr_data(from_wb_mmxwr_data),
        .from_wb_mmxwr_en(from_wb_mmxwr_en)
    );  

    wire [1:0] ldAB;
    wire [1:0] dstA_size;
    wire [1:0] dstB_size;
    wire [2:0] ldREGS;
    wire ldEFLAGS;
    wire ldEIP;
    wire ldCS;
    wire alu_srcb_mux;
    wire [1:0] shf_srcb_mux;
    wire [2:0] eflags_mux;
    wire [2:0] eip_mux;
    wire [1:0] cs_mux;
    wire [1:0] mmx_op;
    wire [2:0] alu_op;
    wire shf_op;
    wire cmps;
    wire [1:0] con_jmp;
    wire cmpxchg;
    wire cmovc;
    wire [3:0] gp_dsta_mux;
    wire [2:0] gp_dstb_mux;
    wire seg_dst_mux;
    wire [1:0] mm_dst_mux;
    wire [3:0] store_data_mux;
    wire [1:0] rw;
    wire [1:0] ds;
    wire [1:0] mem_ds;
    wire [1:0] imm_mux;
    wire [1:0] addr_mux;
    wire stack_push;
    wire intex;
    wire ret_with_imm;
    wire rm, op_ovr, palu_size;

    ag_sig dut_sig (
        .ucode_sig(from_rr_control_sigs),
        .ldAB(ldAB),
        .dstA_size(dstA_size),
        .dstB_size(dstB_size),
        .ldREGS(ldREGS),
        .ldEFLAGS(ldEFLAGS),
        .ldEIP(ldEIP),
        .ldCS(ldCS),
        .alu_srcb_mux(alu_srcb_mux),
        .shf_srcb_mux(shf_srcb_mux),
        .eflags_mux(eflags_mux),
        .eip_mux(eip_mux),
        .cs_mux(cs_mux),
        .mmx_op(mmx_op),
        .alu_op(alu_op),
        .shf_op(shf_op),
        .cmps(cmps),
        .con_jmp(con_jmp),
        .cmpxchg(cmpxchg),
        .cmovc(cmovc),
        .gp_dsta_mux(gp_dsta_mux),
        .gp_dstb_mux(gp_dstb_mux),
        .seg_dst_mux(seg_dst_mux),
        .mm_dst_mux(mm_dst_mux),
        .store_data_mux(store_data_mux),
        .rw(rw),
        .ds(ds),
        .mem_ds(mem_ds),
        .imm_mux(imm_mux),
        .addr_mux(addr_mux),
        .stack_push(stack_push),
        .intex(intex),
        .ret_with_imm(ret_with_imm),
        .rm(rm),
        .op_ovr(op_ovr),
        .palu_size(palu_size)
    );

    reg from_mem_stall;
    reg from_mem_valid_store_inst;
    reg from_ex_valid_store_inst;
    reg from_wb_stall_if_mem_en;
    reg from_wb_valid_store_inst;

    wire [56:0]    from_ag_control_sigs;
    wire [2:0]     from_ag_dstidA;
    wire [2:0]     from_ag_dstidB;
    wire [31:0]    from_ag_srcregA;
    wire [31:0]    from_ag_srcregB;
    wire [31:0]    from_ag_srcregC;
    wire [15:0]    from_ag_srcSREG;
    wire [63:0]    from_ag_MMA;
    wire [63:0]    from_ag_MMB;

    wire [15:0]    from_ag_target_cs;
    wire [31:0]    from_ag_ld_addr;
    wire [31:0]    from_ag_ld_offset;
    wire [31:0]    from_ag_ld_slim;
    wire [31:0]    from_ag_st_addr;
    wire [31:0]    from_ag_st_offset;
    wire [31:0]    from_ag_st_slim;
    wire [31:0]    from_ag_inc_esp;
    wire [31:0]    from_ag_dec_esp;
    wire [31:0]    from_ag_imm;
    wire [31:0]    from_ag_rel_eip;

    wire [15:0]    from_ag_cs;
    wire [31:0]    from_ag_oeip;
    wire [31:0]    from_ag_ieip;
    wire [31:0]    from_ag_pred_eip;
    wire [1:0]     from_ag_exception;
    wire           from_ag_valid;


    stage_ag dut_ag(
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

        .from_ag_stall(from_ag_stall)
    );

    wire [1:0]      from_ag_ldAB;
    wire [1:0]      from_ag_dstA_size;
    wire [1:0]      from_ag_dstB_size;
    wire [2:0]      from_ag_ldREGS;
    wire            from_ag_ldEFLAGS;
    wire            from_ag_ldEIP;
    wire            from_ag_ldCS;
    wire            from_ag_alu_srcb_mux;
    wire [1:0]      from_ag_shf_srcb_mux;
    wire [2:0]      from_ag_eflags_mux;
    wire [2:0]      from_ag_eip_mux;
    wire [1:0]      from_ag_cs_mux;
    wire [1:0]      from_ag_mmx_op;
    wire [2:0]      from_ag_alu_op;
    wire            from_ag_shf_op;
    wire            from_ag_cmps;
    wire [1:0]      from_ag_con_jmp;
    wire            from_ag_cmpxchg;
    wire            from_ag_cmovc;
    wire [3:0]      from_ag_gp_dsta_mux;
    wire [2:0]      from_ag_gp_dstb_mux;
    wire            from_ag_seg_dst_mux;
    wire [1:0]      from_ag_mm_dst_mux;
    wire [3:0]      from_ag_store_data_mux;
    wire [1:0]      from_ag_rw;
    wire [1:0]      from_ag_ds;
    wire [1:0]      from_ag_mem_ds;
    wire            from_ag_rm, from_ag_op_ovr, from_ag_palu_size;
    mem_sig dut_from_ag_sig (
        .ucode_sig(from_ag_control_sigs),
        .ldAB(from_ag_ldAB),
        .dstA_size(from_ag_dstA_size),
        .dstB_size(from_ag_dstB_size),
        .ldREGS(from_ag_ldREGS),
        .ldEFLAGS(from_ag_ldEFLAGS),
        .ldEIP(from_ag_ldEIP),
        .ldCS(from_ag_ldCS),
        .alu_srcb_mux(from_ag_alu_srcb_mux),
        .shf_srcb_mux(from_ag_shf_srcb_mux),
        .eflags_mux(from_ag_eflags_mux),
        .eip_mux(from_ag_eip_mux),
        .cs_mux(from_ag_cs_mux),
        .mmx_op(from_ag_mmx_op),
        .alu_op(from_ag_alu_op),
        .shf_op(from_ag_shf_op),
        .cmps(from_ag_cmps),
        .con_jmp(from_ag_con_jmp),
        .cmpxchg(from_ag_cmpxchg),
        .cmovc(from_ag_cmovc),
        .gp_dsta_mux(from_ag_gp_dsta_mux),
        .gp_dstb_mux(from_ag_gp_dstb_mux),
        .seg_dst_mux(from_ag_seg_dst_mux),
        .mm_dst_mux(from_ag_mm_dst_mux),
        .store_data_mux(from_ag_store_data_mux),
        .rw(from_ag_rw),
        .ds(from_ag_ds),
        .mem_ds(from_ag_mem_ds),
        .rm(from_ag_rm),
        .op_ovr(from_ag_op_ovr),
        .palu_size(from_ag_palu_size)
    );

    wire [56:0]    to_mem_control_sigs;
    wire [2:0]     to_mem_dstidA;
    wire [2:0]     to_mem_dstidB;
    wire [31:0]    to_mem_srcregA;
    wire [31:0]    to_mem_srcregB;
    wire [31:0]    to_mem_srcregC;
    wire [15:0]    to_mem_srcSREG;
    wire [63:0]    to_mem_MMA;
    wire [63:0]    to_mem_MMB;

    wire [15:0]    to_mem_target_cs;
    wire [31:0]    to_mem_ld_addr;
    wire [31:0]    to_mem_ld_offset;
    wire [31:0]    to_mem_ld_slim;
    wire [31:0]    to_mem_st_addr;
    wire [31:0]    to_mem_st_offset;
    wire [31:0]    to_mem_st_slim;
    wire [31:0]    to_mem_inc_esp;
    wire [31:0]    to_mem_dec_esp;
    wire [31:0]    to_mem_imm;
    wire [31:0]    to_mem_rel_eip;

    wire [15:0]    to_mem_cs;
    wire [31:0]    to_mem_oeip;
    wire [31:0]    to_mem_ieip;
    wire [31:0]    to_mem_pred_eip;
    wire [1:0]     to_mem_exception;
    wire           to_mem_valid;

    ag_to_mem dut_ag_to_mem (
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
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

    wire [1:0]      to_mem_ldAB;
    wire [1:0]      to_mem_dstA_size;
    wire [1:0]      to_mem_dstB_size;
    wire [2:0]      to_mem_ldREGS;
    wire            to_mem_ldEFLAGS;
    wire            to_mem_ldEIP;
    wire            to_mem_ldCS;
    wire            to_mem_alu_srcb_mux;
    wire [1:0]      to_mem_shf_srcb_mux;
    wire [2:0]      to_mem_eflags_mux;
    wire [2:0]      to_mem_eip_mux;
    wire [1:0]      to_mem_cs_mux;
    wire [1:0]      to_mem_mmx_op;
    wire [2:0]      to_mem_alu_op;
    wire            to_mem_shf_op;
    wire            to_mem_cmps;
    wire [1:0]      to_mem_con_jmp;
    wire            to_mem_cmpxchg;
    wire            to_mem_cmovc;
    wire [3:0]      to_mem_gp_dsta_mux;
    wire [2:0]      to_mem_gp_dstb_mux;
    wire            to_mem_seg_dst_mux;
    wire [1:0]      to_mem_mm_dst_mux;
    wire [3:0]      to_mem_store_data_mux;
    wire [1:0]      to_mem_rw;
    wire [1:0]      to_mem_ds;
    wire [1:0]      to_mem_mem_ds;
    wire            to_mem_rm, to_mem_op_ovr, to_mem_palu_size;

    mem_sig dut_mem_sig (
        .ucode_sig(to_mem_control_sigs),
        .ldAB(to_mem_ldAB),
        .dstA_size(to_mem_dstA_size),
        .dstB_size(to_mem_dstB_size),
        .ldREGS(to_mem_ldREGS),
        .ldEFLAGS(to_mem_ldEFLAGS),
        .ldEIP(to_mem_ldEIP),
        .ldCS(to_mem_ldCS),
        .alu_srcb_mux(to_mem_alu_srcb_mux),
        .shf_srcb_mux(to_mem_shf_srcb_mux),
        .eflags_mux(to_mem_eflags_mux),
        .eip_mux(to_mem_eip_mux),
        .cs_mux(to_mem_cs_mux),
        .mmx_op(to_mem_mmx_op),
        .alu_op(to_mem_alu_op),
        .shf_op(to_mem_shf_op),
        .cmps(to_mem_cmps),
        .con_jmp(to_mem_con_jmp),
        .cmpxchg(to_mem_cmpxchg),
        .cmovc(to_mem_cmovc),
        .gp_dsta_mux(to_mem_gp_dsta_mux),
        .gp_dstb_mux(to_mem_gp_dstb_mux),
        .seg_dst_mux(to_mem_seg_dst_mux),
        .mm_dst_mux(to_mem_mm_dst_mux),
        .store_data_mux(to_mem_store_data_mux),
        .rw(to_mem_rw),
        .ds(to_mem_ds),
        .mem_ds(to_mem_mem_ds),
        .rm(to_mem_rm),
        .op_ovr(to_mem_op_ovr),
        .palu_size(to_mem_palu_size)
    );
    always #6 clk = ~clk;

    task clear_inputs;
    begin
            to_rr_prefix = 5'd0;
            to_rr_opcode = 8'd0;
            to_rr_modrm = 8'd0;
            to_rr_sib = 8'd0;
            to_rr_disp = 32'd0;
            to_rr_imm = 48'd0;
            to_rr_imm_size = 2'd0;
            to_rr_addr_mode = 2'd0;
            to_rr_oeip = 32'd0;
            to_rr_ieip = 32'd0;
            to_rr_pred_eip = 32'd0;
            to_rr_exception = 32'd0;
            to_rr_valid = 1'b0;

            from_mem_stall = 1'b0;
            from_mem_valid_store_inst = 1'b0;
            from_ex_valid_store_inst = 1'b0;
            from_wb_stall_if_mem_en = 1'b0;
            from_wb_valid_store_inst = 1'b0;

            from_wb_gpwr0_idx   = 'b0;
            from_wb_gpwr0_data  = 'b0;
            from_wb_gpwr0_size  = 'b0;
            from_wb_gpwr0_en    = 'b0;
            from_wb_gpwr1_idx   = 'b0;
            from_wb_gpwr1_data  = 'b0;
            from_wb_gpwr1_size  = 'b0;
            from_wb_gpwr1_en    = 'b0;
            from_wb_segwr_idx   = 'b0;
            from_wb_segwr_data  = 'b0;
            from_wb_segwr_en    = 'b0;
            from_ex_cs_wr_data  = 'b0;
            from_ex_cs_wr_en    = 'b0;
            from_wb_mmxwr_idx   = 'b0;
            from_wb_mmxwr_data  = 'b0;
            from_wb_mmxwr_en    = 'b0;
    end 
    endtask

    task apply_exwb_inputs;
        input [2:0] gpwr0_idx;
        input [31:0] gpwr0_data;
        input [1:0] gpwr0_size;
        input gpwr0_en;
        input [2:0] gpwr1_idx;
        input [31:0] gpwr1_data;
        input [1:0] gpwr1_size;
        input gpwr1_en;
        input [2:0] segwr_idx;
        input [15:0] segwr_data;
        input segwr_en;
        input [15:0] cs_wr_data;
        input cs_wr_en;
        input [2:0] mmxwr_idx;
        input [63:0] mmxwr_data;
        input mmxwr_en;
    begin 
        from_wb_gpwr0_idx   = gpwr0_idx; 
        from_wb_gpwr0_data  = gpwr0_data;
        from_wb_gpwr0_size  = gpwr0_size;
        from_wb_gpwr0_en    = gpwr0_en;  
        from_wb_gpwr1_idx   = gpwr1_idx; 
        from_wb_gpwr1_data  = gpwr1_data;
        from_wb_gpwr1_size  = gpwr1_size;
        from_wb_gpwr1_en    = gpwr1_en;  
        from_wb_segwr_idx   = segwr_idx; 
        from_wb_segwr_data  = segwr_data;
        from_wb_segwr_en    = segwr_en;  
        from_ex_cs_wr_data  = cs_wr_data;
        from_ex_cs_wr_en    = cs_wr_en;  
        from_wb_mmxwr_idx   = mmxwr_idx; 
        from_wb_mmxwr_data  = mmxwr_data;
        from_wb_mmxwr_en    = mmxwr_en;  
    end
    endtask

    task apply_de_inputs;
        input [5:0] prefix;
        input [7:0] opcode;
        input [7:0] modrm;
        input [7:0] sib;
        input [31:0] disp;
        input [1:0] dispsize;
        input [47:0] imm;
        input [2:0] imm_size;
        input [1:0] addr_mode;
        input [31:0] oeip;
        input [31:0] ieip;
        input valid;
    begin 
        to_rr_prefix      = prefix;          
        to_rr_opcode      = opcode;    
        to_rr_modrm       = modrm;     
        to_rr_sib         = sib;       
        to_rr_disp        = disp;      
        to_rr_dispsize    = dispsize;  
        to_rr_imm         = imm;       
        to_rr_imm_size    = imm_size;  
        to_rr_addr_mode   = addr_mode; 
        to_rr_oeip        = oeip;      
        to_rr_ieip        = ieip;      
        to_rr_valid       = valid;     
    end
    endtask

    task print_from_rr_sigs;
    begin 
        $display("----------------------------------------------------------------");
        $display("ldAB=%02b, dstA_size=%02b, dstB_size=%02b", ldAB, dstA_size, dstB_size);
        $display("ldREGS=%03b, ldEFLAGS=%0b, ldEIP=%0b, ldCS=%0b", ldREGS, ldEFLAGS, ldEIP, ldCS);
        $display("alu_srcb_mux=%0b, shf_srcb_mux=%02b", alu_srcb_mux, shf_srcb_mux);
        $display("alu_op=%03b, mmx_op=%02b, shf_op=%0b", alu_op, mmx_op, shf_op);
        $display("eflags_mux=%03b, eip_mux=%03b, cs_mux=%02b", eflags_mux, eip_mux, cs_mux);
        $display("cmps=%0b, con_jmp=%0b, cmpxchg=%0b, cmovc=%0b", cmps, con_jmp, cmpxchg, cmovc);
        $display("gp_dsta_mux=%04b, gp_dstb_mux=%03b, seg_dst_mux=%0b, mm_dst_mux=%02b", gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux);
        $display("store_data_mux=%04b", store_data_mux);
        $display("rw=%02b, ds=%02b", rw, ds);
        $display("mem_ds=%02b, imm_mux=%02b, addr_mux=%02b, stack_push=%0b, intex=%0b", mem_ds, imm_mux, addr_mux, stack_push, intex);
        $display("rm=%0b, op_ovr=%0b, palu_size=%0b", rm, op_ovr, palu_size);
        $display("----------------------------------------------------------------");
    end
    endtask

    task print_from_ag_sigs;
    begin 
        $display("----------------------------------------------------------------");
        $display("ldAB=%02b, dstA_size=%02b, dstB_size=%02b", from_ag_ldAB, from_ag_dstA_size, from_ag_dstB_size);
        $display("ldREGS=%03b, ldEFLAGS=%0b, ldEIP=%0b, ldCS=%0b", from_ag_ldREGS, from_ag_ldEFLAGS, from_ag_ldEIP, from_ag_ldCS);
        $display("alu_srcb_mux=%0b, shf_srcb_mux=%02b", from_ag_alu_srcb_mux, from_ag_shf_srcb_mux);
        $display("alu_op=%03b, mmx_op=%02b, shf_op=%0b", from_ag_alu_op, from_ag_mmx_op, from_ag_shf_op);
        $display("eflags_mux=%03b, eip_mux=%03b, cs_mux=%02b", from_ag_eflags_mux, from_ag_eip_mux, from_ag_cs_mux);
        $display("cmps=%0b, con_jmp=%0b, cmpxchg=%0b, cmovc=%0b", from_ag_cmps, from_ag_con_jmp, from_ag_cmpxchg, from_ag_cmovc);
        $display("gp_dsta_mux=%04b, gp_dstb_mux=%03b, seg_dst_mux=%0b, mm_dst_mux=%02b", from_ag_gp_dsta_mux, from_ag_gp_dstb_mux, from_ag_seg_dst_mux, from_ag_mm_dst_mux);
        $display("store_data_mux=%04b", from_ag_store_data_mux);
        $display("rw=%02b, ds=%02b", from_ag_rw, from_ag_ds);
        $display("mem_ds=%02b", from_ag_mem_ds);
        $display("rm=%0b, op_ovr=%0b, palu_size=%0b", from_ag_rm, from_ag_op_ovr, from_ag_palu_size);
        $display("----------------------------------------------------------------");
    end
    endtask

    task print_rr_outputs;
    begin
        $display("************************************************");
        $display("*               RR TO AG                       *");
        $display("************************************************");
        $display("control signals=%b", from_rr_control_sigs);
        print_from_rr_sigs();
        $display("(%0d)dstidA=%0d, (%0d)dstidB=%0d", ldAB[1], from_rr_dstidA, ldAB[0], from_rr_dstidB);
        $display("(%0d)srcregA=[%0d]%08h, (%0d)srcregB=[%0d]%08h, (%0d)srcregC=[%0d]%08h", to_dep_needREGS[10], to_dep_srcregA_idx, from_rr_srcregA, to_dep_needREGS[9], to_dep_srcregB_idx, from_rr_srcregB, to_dep_needREGS[8], to_dep_srcregC_idx, from_rr_srcregC);
        $display("(%0d)srcSREG=[%0d]%04h, (%0d)MMA=[%0d]%016h, (%0d)MMB=[%0d]%016h", to_dep_needREGS[4], to_dep_srcSREG_idx, from_rr_srcSREG, to_dep_needREGS[1], to_dep_MMA_idx, from_rr_MMA, to_dep_needREGS[0], to_dep_MMB_idx, from_rr_MMB);
        $display("imm=%08h", from_rr_imm);
        $display("(%0d)sreg1=[%0d]%04h, slim1=%08h", to_dep_needREGS[3], to_dep_SREG1_idx, from_rr_sreg1, from_rr_slim1);
        $display("(%0d)base1=[%0d]%08h, (%0d)index1=[%0d]%08h, scale_mux=%02b, disp=%08h", to_dep_needREGS[7], to_dep_basereg1_idx, from_rr_base1, to_dep_needREGS[5], to_dep_indexreg1_idx, from_rr_index1, from_rr_scale_mux, from_rr_disp);
        $display("(%0d)sreg2=[%0d]%04h, slim2=%08h", to_dep_needREGS[2], to_dep_SREG2_idx, from_rr_sreg2, from_rr_slim2);
        $display("(%0d)base2=[%0d]%08h", to_dep_needREGS[6], to_dep_basereg2_idx, from_rr_base2);
        $display("intex_vec=%04b, exception=%02b", from_rr_intex_vec, from_rr_exception);
        $display("oeip=%08h, ieip=%08h, pred_eip=%08h, cs=%04h", from_rr_oeip, from_rr_ieip, from_rr_pred_eip, from_rr_cs);
        $display("valie=%0b", from_rr_valid);
        $display("\n");
    end
    endtask

    task print_ag_outputs;
    begin 
        $display("************************************************");
        $display("*               AG TO MEM                      *");
        $display("************************************************");
        $display("control signals=%b", from_ag_control_sigs);
        print_from_ag_sigs();
        $display("dstidA=%0d, dstidB=%0d", from_ag_dstidA, from_ag_dstidB);
        $display("srcregA=%08h, srcregB=%08h, srcregC=%08h", from_ag_srcregA, from_ag_srcregB, from_ag_srcregC);
        $display("srcSREG=%04h, MMA=%016h, MMB=%016h", from_ag_srcSREG, from_ag_MMA, from_ag_MMB);
        $display("target_cs=%04h", from_ag_target_cs);
        $display("ld_addr=%08h, ld_offset=%08h, ld_slim=%08h", from_ag_ld_addr, from_ag_ld_offset, from_ag_ld_slim);
        $display("st_addr=%08h, st_offset=%08h, st_slim=%08h", from_ag_st_addr, from_ag_st_offset, from_ag_st_slim);
        $display("inc_esp=%08h, dec_esp=%05h", from_ag_inc_esp, from_ag_dec_esp);
        $display("imm=%08h", from_ag_imm);
        $display("exception=%02b", from_ag_exception);
        $display("oeip=%08h, ieip=%08h, pred_eip=%08h, cs=%04h", from_ag_oeip, from_ag_ieip, from_rr_pred_eip, from_ag_cs);
        $display("valid=%0b, stall=%0b", from_ag_valid, from_ag_stall);
    end
    endtask

    task print_mem_inputs;
    begin 
        $display("************************************************");
        $display("*               MEM IN                         *");
        $display("************************************************");
        $display("control signals=%b", to_mem_control_sigs);
        $display("dstidA=%0d, dstidB=%0d", to_mem_dstidA, to_mem_dstidB);
        $display("srcregA=%08h, srcregB=%08h, srcregC=%08h", to_mem_srcregA, to_mem_srcregB, to_mem_srcregC);
        $display("srcSREG=%04h, MMA=%016h, MMB=%016h", to_mem_srcSREG, to_mem_MMA, to_mem_MMB);
        $display("target_cs=%04h", to_mem_target_cs);
        $display("ld_addr=%08h, ld_offset=%08h, ld_slim=%05h", to_mem_ld_addr, to_mem_ld_offset, to_mem_ld_slim);
        $display("st_addr=%08h, st_offset=%08h, st_slim=%05h", to_mem_st_addr, to_mem_st_offset, to_mem_st_slim);
        $display("inc_esp=%08h, dec_esp=%05h", to_mem_inc_esp, to_mem_dec_esp);
        $display("imm=%08h", to_mem_imm);
        $display("exception=%02b", to_mem_exception);
        $display("oeip=%08h, ieip=%08h, pred_eip=%08h, cs=%04h", to_mem_oeip, to_mem_ieip, to_mem_pred_eip, to_mem_cs);
        $display("valid=%0b", to_mem_valid);
        $display("\n");
    end
    endtask

    initial begin 
        clk = 1'b0;
        rst_n = 1'b0;
        clear_inputs();
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        apply_exwb_inputs(3'd0, 32'h0000_0000, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd0, 16'h0000, 1'b1, 16'h1111, 1'b1, 3'd0, 64'h0000_0000_0000_0000, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd1, 32'h1111_1111, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd1, 16'h1111, 1'b0, 16'b0, 1'b0, 3'd1, 64'h1111_1111_1111_1111, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd2, 32'h2222_2222, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd2, 16'h2222, 1'b1, 16'b0, 1'b0, 3'd2, 64'h2222_2222_2222_2222, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd3, 32'h3333_3333, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd3, 16'h3333, 1'b1, 16'b0, 1'b0, 3'd3, 64'h3333_3333_3333_3333, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd4, 32'h4444_4444, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd4, 16'h4444, 1'b1, 16'b0, 1'b0, 3'd4, 64'h4444_4444_4444_4444, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd5, 32'h5555_5555, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd5, 16'h5555, 1'b1, 16'b0, 1'b0, 3'd5, 64'h5555_5555_5555_5555, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd6, 32'h6666_6666, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd6, 16'h6666, 1'b1, 16'b0, 1'b0, 3'd6, 64'h6666_6666_6666_6666, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd7, 32'h7777_7777, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd7, 16'h7777, 1'b1, 16'b0, 1'b0, 3'd7, 64'h7777_7777_7777_7777, 1'b1);
        @(negedge clk);
        clear_inputs();
        $display("======================================");
        $display("General Purpose RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut_regunit.gprf.q[i]);
        end

        $display("======================================");
        $display("Segement RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            if(i==1) begin 
                $display("reg[%0d](CS) = %h", i, dut_regunit.segrf.cs_q);
            end else begin 
                $display("reg[%0d] = %h", i, dut_regunit.segrf.seg_rf.q[i]);
            end
        end

        $display("======================================");
        $display("MMX RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut_regunit.mmxrf.mmx_regs.q[i]);
        end
        $display("\n");

        $display("======================================");
        $display("TEST CASE1: ADD EAX, ECX");
        $display("======================================");
        // 01 C8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h01, 8'hc8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");
        
        $display("======================================");
        $display("TEST CASE2: ADD [EBX], CH");
        $display("======================================");
        // 00 2b=00000000 00101011
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h00, 8'h2b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE3: OR [EBX+ECX*2+0x12345678], CH");
        $display("======================================");
        // 08 ac 4b 78 56 34 12
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h08, 8'hac, 8'h4b, 32'h1234_5678, 2'b10,
                        48'bx, 3'b000, 2'b11, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE4: PUSH CS"); // here we test if cs can be put to the srcreg correctly (because it's not in the regfile)
        $display("======================================");
        // 0e
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(2), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h0e, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE5: POP DS"); // here we test ld sreg & ld esp
        $display("======================================");
        // 1f
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h1f, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE6: PUSH WORD [ECX+EDX*4+0x12345678]"); // here we test ld sreg & ld esp & operand size override
        $display("======================================");
        // 66 ff b4 91 78 56 34 12
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b010110, 8'hff, 8'hb4, 8'h91, 32'h12345678, 2'b10,
                        48'bx, 3'b000, 2'b11, 32'h0, 32'h8, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE7: CMPXCHG [ESP+8*EDX+0x12345678], ESI"); // here we test reading all four registers and esp as base
        $display("======================================");
        // 0f b1 b4 d4 78 56 34 12
        // prefix(5), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000111, 8'hb1, 8'hb4, 8'hd4, 32'h12345678, 2'b10,
                        48'bx, 3'b000, 2'b11, 32'h0, 32'h8, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE8: SAR BL, CL"); // here we test reading BL and CL
        $display("======================================");
        // d2 fb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'hd2, 8'hfb, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE9: XCHG EAX, ESP"); // here we test writing to both general purpose registers
        $display("======================================");
        // d94
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000110, 8'h94, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h2, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE10: MOVQ ES:[ECX], MM7"); // here we test segment override and mmx reading
        $display("======================================");
        // 26 0f 7f 39
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000001, 8'h7f, 8'h39, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h4, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");
        
        $display("======================================");
        $display("TEST CASE11: RET (near) 0x8"); // test ret with imm (increase esp with imm after pop())
        $display("======================================");
        // c2 08 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000000, 8'hc2, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b001, 2'b00, 32'h0, 32'h4, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("TEST CASE12: CALL 0x12:0x3456"); // test call ptr
        $display("======================================");
        //9a 56 34 00 00 12 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        @(posedge clk);
        apply_de_inputs(6'b000000, 8'h9a, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h001200003456, 3'b110, 2'b00, 32'h0, 32'h4, 1'b1);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");




        $display("======================================");
        $display("EXTRA CLOCK1");
        $display("======================================");
        
        @(posedge clk);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("======================================");
        $display("EXTRA CLOCK2");
        $display("======================================");
        
        @(posedge clk);
        #8
        print_rr_outputs();
        print_ag_outputs();
        print_mem_inputs();
        $display("\n");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule