module stage_ex_tb;

    initial begin
        $vcdplusfile("stage_ex_tb.dump.vpd");
        $vcdpluson(0, stage_ex_tb); 
    end

    integer i;
    integer NUM_TESTS = 0;
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

    wire from_mem_stall;
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

    wire [54:0] from_mem_control_sigs;
    wire [2:0] from_mem_dstidA;
    wire [2:0] from_mem_dstidB;
    wire [31:0] from_mem_srcregA;
    wire [31:0] from_mem_srcregB;
    wire [31:0] from_mem_srcregC;
    wire [15:0] from_mem_srcSREG;
    wire [63:0] from_mem_MMA;
    wire [63:0] from_mem_MMB;
    wire [15:0] from_mem_target_cs;
    wire [63:0] from_mem_load_result;
    wire [31:0] from_mem_inc_esp;
    wire [31:0] from_mem_dec_esp;
    wire [31:0] from_mem_imm;
    wire from_mem_store_is_io_line_0;
    wire [10:0] from_mem_store_addr_line_0;
    wire [15:0] from_mem_store_mask_line_0;
    wire from_mem_store_queue_alloc_line_0;
    wire [10:0] from_mem_store_addr_line_1;
    wire [15:0] from_mem_store_mask_line_1;
    wire from_mem_store_queue_alloc_line_1;
    wire [4:0] from_mem_store_data_shf_amt;
    wire [31:0] from_mem_rel_eip;
    wire [15:0] from_mem_cs;
    wire [31:0] from_mem_oeip;
    wire [31:0] from_mem_ieip;
    wire [31:0] from_mem_pred_eip;
    wire [1:0] from_mem_exception;
    wire from_mem_valid;

    dummy_mem dut_dummy_mem(
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
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
        .to_mem_valid(to_mem_valid),
        .from_mem_control_sigs(from_mem_control_sigs),
        .from_mem_dstidA(from_mem_dstidA),
        .from_mem_dstidB(from_mem_dstidB),
        .from_mem_srcregA(from_mem_srcregA),
        .from_mem_srcregB(from_mem_srcregB),
        .from_mem_srcregC(from_mem_srcregC),
        .from_mem_srcSREG(from_mem_srcSREG),
        .from_mem_MMA(from_mem_MMA),
        .from_mem_MMB(from_mem_MMB),
        .from_mem_target_cs(from_mem_target_cs),
        .from_mem_load_result(from_mem_load_result),
        .from_mem_inc_esp(from_mem_inc_esp),
        .from_mem_dec_esp(from_mem_dec_esp),
        .from_mem_imm(from_mem_imm),
        .from_mem_store_is_io_line_0(from_mem_store_is_io_line_0),
        .from_mem_store_addr_line_0(from_mem_store_addr_line_0),
        .from_mem_store_mask_line_0(from_mem_store_mask_line_0),
        .from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0),
        .from_mem_store_addr_line_1(from_mem_store_addr_line_1),
        .from_mem_store_mask_line_1(from_mem_store_mask_line_1),
        .from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1),
        .from_mem_store_data_shf_amt(from_mem_store_data_shf_amt),
        .from_mem_rel_eip(from_mem_rel_eip),
        .from_mem_cs(from_mem_cs),
        .from_mem_oeip(from_mem_oeip),
        .from_mem_ieip(from_mem_ieip),
        .from_mem_pred_eip(from_mem_pred_eip),
        .from_mem_exception(from_mem_exception),
        .from_mem_valid(from_mem_valid),
        .from_mem_stall(from_mem_stall)
    );

    wire [1:0]      from_mem_ldAB;
    wire [1:0]      from_mem_dstA_size;
    wire [1:0]      from_mem_dstB_size;
    wire [2:0]      from_mem_ldREGS;
    wire            from_mem_ldEFLAGS;
    wire            from_mem_ldEIP;
    wire            from_mem_ldCS;
    wire            from_mem_alu_srcb_mux;
    wire [1:0]      from_mem_shf_srcb_mux;
    wire [2:0]      from_mem_eflags_mux;
    wire [2:0]      from_mem_eip_mux;
    wire [1:0]      from_mem_cs_mux;
    wire [1:0]      from_mem_mmx_op;
    wire [2:0]      from_mem_alu_op;
    wire            from_mem_shf_op;
    wire            from_mem_cmps;
    wire [1:0]      from_mem_con_jmp;
    wire            from_mem_cmpxchg;
    wire            from_mem_cmovc;
    wire [3:0]      from_mem_gp_dsta_mux;
    wire [2:0]      from_mem_gp_dstb_mux;
    wire            from_mem_seg_dst_mux;
    wire [1:0]      from_mem_mm_dst_mux;
    wire [3:0]      from_mem_store_data_mux;
    wire [1:0]      from_mem_rw;
    wire [1:0]      from_mem_ds;
    wire            from_mem_rm, from_mem_op_ovr, from_mem_palu_size;

    ex_sig dut_from_mem_sig (
        .ucode_sig(from_mem_control_sigs),
        .ldAB(from_mem_ldAB),
        .dstA_size(from_mem_dstA_size),
        .dstB_size(from_mem_dstB_size),
        .ldREGS(from_mem_ldREGS),
        .ldEFLAGS(from_mem_ldEFLAGS),
        .ldEIP(from_mem_ldEIP),
        .ldCS(from_mem_ldCS),
        .alu_srcb_mux(from_mem_alu_srcb_mux),
        .shf_srcb_mux(from_mem_shf_srcb_mux),
        .eflags_mux(from_mem_eflags_mux),
        .eip_mux(from_mem_eip_mux),
        .cs_mux(from_mem_cs_mux),
        .mmx_op(from_mem_mmx_op),
        .alu_op(from_mem_alu_op),
        .shf_op(from_mem_shf_op),
        .cmps(from_mem_cmps),
        .con_jmp(from_mem_con_jmp),
        .cmpxchg(from_mem_cmpxchg),
        .cmovc(from_mem_cmovc),
        .gp_dsta_mux(from_mem_gp_dsta_mux),
        .gp_dstb_mux(from_mem_gp_dstb_mux),
        .seg_dst_mux(from_mem_seg_dst_mux),
        .mm_dst_mux(from_mem_mm_dst_mux),
        .store_data_mux(from_mem_store_data_mux),
        .rw(from_mem_rw),
        .ds(from_mem_ds),
        .rm(from_mem_rm),
        .op_ovr(from_mem_op_ovr),
        .palu_size(from_mem_palu_size)
    );

    wire [54:0] to_ex_control_sigs;
    wire [2:0] to_ex_dstidA;
    wire [2:0] to_ex_dstidB;
    wire [31:0] to_ex_srcregA;
    wire [31:0] to_ex_srcregB;
    wire [31:0] to_ex_srcregC;
    wire [15:0] to_ex_srcSREG;
    wire [63:0] to_ex_MMA;
    wire [63:0] to_ex_MMB;
    wire [15:0] to_ex_target_cs;
    wire [63:0] to_ex_load_result;
    wire [31:0] to_ex_inc_esp;
    wire [31:0] to_ex_dec_esp;
    wire [31:0] to_ex_imm;
    wire [31:0] to_ex_rel_eip;
    wire to_ex_store_is_io_line_0;
    wire [14:4] to_ex_store_addr_line_0;
    wire [15:0] to_ex_store_mask_line_0;
    wire to_ex_store_queue_alloc_line_0;
    wire [14:4] to_ex_store_addr_line_1;
    wire [15:0] to_ex_store_mask_line_1;
    wire to_ex_store_queue_alloc_line_1;
    wire [4:0] to_ex_store_data_shf_amt;
    wire [15:0] to_ex_cs;
    wire [31:0] to_ex_oeip;
    wire [31:0] to_ex_ieip;
    wire [31:0] to_ex_pred_eip;
    wire [1:0] to_ex_exception;
    wire to_ex_valid;

    mem_to_ex dut_mem_to_ex (
        .clk(clk),
        .rst_n(rst_n),
        .we(1'b1),
        .from_mem_control_sigs(from_mem_control_sigs),
        .from_mem_dstidA(from_mem_dstidA),
        .from_mem_dstidB(from_mem_dstidB),
        .from_mem_srcregA(from_mem_srcregA),
        .from_mem_srcregB(from_mem_srcregB),
        .from_mem_srcregC(from_mem_srcregC),
        .from_mem_srcSREG(from_mem_srcSREG),
        .from_mem_MMA(from_mem_MMA),
        .from_mem_MMB(from_mem_MMB),
        .from_mem_target_cs(from_mem_target_cs),
        .from_mem_load_result(from_mem_load_result),
        .from_mem_inc_esp(from_mem_inc_esp),
        .from_mem_dec_esp(from_mem_dec_esp),
        .from_mem_imm(from_mem_imm),
        .from_mem_rel_eip(from_mem_rel_eip),
        .from_mem_store_is_io_line_0(from_mem_store_is_io_line_0),
        .from_mem_store_addr_line_0(from_mem_store_addr_line_0),
        .from_mem_store_mask_line_0(from_mem_store_mask_line_0),
        .from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0),
        .from_mem_store_addr_line_1(from_mem_store_addr_line_1),
        .from_mem_store_mask_line_1(from_mem_store_mask_line_1),
        .from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1),
        .from_mem_store_data_shf_amt(from_mem_store_data_shf_amt),
        .from_mem_cs(from_mem_cs),
        .from_mem_oeip(from_mem_oeip),
        .from_mem_ieip(from_mem_ieip),
        .from_mem_pred_eip(from_mem_pred_eip),
        .from_mem_exception(from_mem_exception),
        .from_mem_valid(from_mem_valid),
        .to_ex_control_sigs(to_ex_control_sigs),
        .to_ex_dstidA(to_ex_dstidA),
        .to_ex_dstidB(to_ex_dstidB),
        .to_ex_srcregA(to_ex_srcregA),
        .to_ex_srcregB(to_ex_srcregB),
        .to_ex_srcregC(to_ex_srcregC),
        .to_ex_srcSREG(to_ex_srcSREG),
        .to_ex_MMA(to_ex_MMA),
        .to_ex_MMB(to_ex_MMB),
        .to_ex_target_cs(to_ex_target_cs),
        .to_ex_load_result(to_ex_load_result),
        .to_ex_inc_esp(to_ex_inc_esp),
        .to_ex_dec_esp(to_ex_dec_esp),
        .to_ex_imm(to_ex_imm),
        .to_ex_rel_eip(to_ex_rel_eip),
        .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
        .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
        .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
        .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
        .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
        .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
        .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
        .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),
        .to_ex_cs(to_ex_cs),
        .to_ex_oeip(to_ex_oeip),
        .to_ex_ieip(to_ex_ieip),
        .to_ex_pred_eip(to_ex_pred_eip),
        .to_ex_exception(to_ex_exception),
        .to_ex_valid(to_ex_valid)
    );


    reg [31:0] to_ex_CMPS0;
    reg [31:0] to_ex_CMPS1;
    reg [31:0] to_ex_tempEIP;
    reg [15:0] to_ex_tempCS;

    wire from_ex_flush;
    wire from_ex_ld_cs;
    wire from_ex_br_t_nt;
    wire from_ex_br_valid;
    wire [15:0] from_ex_cs_target;
    wire [31:0] from_ex_eip_target;
    wire [12:0] from_ex_control_sigs;
    wire [2:0] from_ex_dstidA;
    wire [2:0] from_ex_dstidB;
    wire [31:0] from_ex_gp_wr_data_1;
    wire [31:0] from_ex_gp_wr_data_2;
    wire [15:0] from_ex_seg_wr_data;
    wire [63:0] from_ex_mmx_wr_data;
    wire [63:0] from_ex_store_data;
    wire from_ex_store_is_io_line_0;
    wire [10:0] from_ex_store_addr_line_0;
    wire [15:0] from_ex_store_mask_line_0;
    wire from_ex_store_queue_alloc_line_0;
    wire [10:0] from_ex_store_addr_line_1;
    wire [15:0] from_ex_store_mask_line_1;
    wire from_ex_store_queue_alloc_line_1;
    wire [4:0] from_ex_store_data_shf_amt;
    wire [15:0] from_ex_cs;
    wire [31:0] from_ex_oeip;
    wire from_ex_valid;
    wire [1:0] from_ex_exception;

    stage_ex dut_stage_ex (
        .clk(clk),
        .rst_n(rst_n),
        .to_ex_control_sigs(to_ex_control_sigs),
        .to_ex_dstidA(to_ex_dstidA),
        .to_ex_dstidB(to_ex_dstidB),
        .to_ex_srcregA(to_ex_srcregA),
        .to_ex_srcregB(to_ex_srcregB),
        .to_ex_srcregC(to_ex_srcregC),
        .to_ex_srcSREG(to_ex_srcSREG),
        .to_ex_MMA(to_ex_MMA),
        .to_ex_MMB(to_ex_MMB),
        .to_ex_target_cs(to_ex_target_cs),
        .to_ex_load_result(to_ex_load_result),
        .to_ex_inc_esp(to_ex_inc_esp),
        .to_ex_dec_esp(to_ex_dec_esp),
        .to_ex_imm(to_ex_imm),
        .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
        .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
        .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
        .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
        .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
        .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
        .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
        .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),
        .to_ex_rel_eip(to_ex_rel_eip),
        .to_ex_cs(to_ex_cs),
        .to_ex_oeip(to_ex_oeip),
        .to_ex_ieip(to_ex_ieip),
        .to_ex_pred_eip(to_ex_pred_eip),
        .to_ex_exception(to_ex_exception),
        .to_ex_valid(to_ex_valid),
        .to_ex_CMPS0(to_ex_CMPS0),
        .to_ex_CMPS1(to_ex_CMPS1),
        .to_ex_tempEIP(to_ex_tempEIP),
        .to_ex_tempCS(to_ex_tempCS),
        .to_ex_cs_limit(from_regunit_cs_limit),
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_cs_target(from_ex_cs_target),
        .from_ex_eip_target(from_ex_eip_target),
        .from_ex_control_sigs(from_ex_control_sigs),
        .from_ex_dstidA(from_ex_dstidA),
        .from_ex_dstidB(from_ex_dstidB),
        .from_ex_gp_wr_data_1(from_ex_gp_wr_data_1),
        .from_ex_gp_wr_data_2(from_ex_gp_wr_data_2),
        .from_ex_seg_wr_data(from_ex_seg_wr_data),
        .from_ex_mmx_wr_data(from_ex_mmx_wr_data),
        .from_ex_store_data(from_ex_store_data),
        .from_ex_store_is_io_line_0(from_ex_store_is_io_line_0),
        .from_ex_store_addr_line_0(from_ex_store_addr_line_0),
        .from_ex_store_mask_line_0(from_ex_store_mask_line_0),
        .from_ex_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0),
        .from_ex_store_addr_line_1(from_ex_store_addr_line_1),
        .from_ex_store_mask_line_1(from_ex_store_mask_line_1),
        .from_ex_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1),
        .from_ex_store_data_shf_amt(from_ex_store_data_shf_amt),
        .from_ex_cs(from_ex_cs),
        .from_ex_oeip(from_ex_oeip),
        .from_ex_valid(from_ex_valid),
        .from_ex_exception(from_ex_exception)
    );
    
    wire [1:0] from_ex_ldAB;
    wire [1:0] from_ex_dstA_size;
    wire [1:0] from_ex_dstB_size;
    wire [2:0] from_ex_ldREGS;
    wire [1:0] from_ex_rw;
    wire [1:0] from_ex_ds;

    wb_sig dut_wb_sig(
        .ucode_sig(from_ex_control_sigs),
        .ldAB(from_ex_ldAB),
        .dstA_size(from_ex_dstA_size),
        .dstB_size(from_ex_dstB_size),
        .ldREGS(from_ex_ldREGS),
        .rw(from_ex_rw),
        .ds(from_ex_ds)
    ); 

    always #5 clk = ~clk;

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

            from_mem_valid_store_inst = 1'b0;
            from_ex_valid_store_inst = 1'b0;
            from_wb_stall_if_mem_en = 1'b0;
            from_wb_valid_store_inst = 1'b0;

            to_ex_CMPS0 = 32'b0;
            to_ex_CMPS1 = 32'b0;
            to_ex_tempEIP = 32'b0;
            to_ex_tempCS = 16'b0;

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
        input [31:0] pred_eip;
        input [1:0] exception;
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
        to_rr_pred_eip    = pred_eip;
        to_rr_exception   = exception;    
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

    task print_from_mem_sigs;
    begin 
        $display("----------------------------------------------------------------");
        $display("ldAB=%02b, dstA_size=%02b, dstB_size=%02b", from_mem_ldAB, from_mem_dstA_size, from_mem_dstB_size);
        $display("ldREGS=%03b, ldEFLAGS=%0b, ldEIP=%0b, ldCS=%0b", from_mem_ldREGS, from_mem_ldEFLAGS, from_mem_ldEIP, from_mem_ldCS);
        $display("alu_srcb_mux=%0b, shf_srcb_mux=%02b", from_mem_alu_srcb_mux, from_mem_shf_srcb_mux);
        $display("alu_op=%03b, mmx_op=%02b, shf_op=%0b", from_mem_alu_op, from_mem_mmx_op, from_mem_shf_op);
        $display("eflags_mux=%03b, eip_mux=%03b, cs_mux=%02b", from_mem_eflags_mux, from_mem_eip_mux, from_mem_cs_mux);
        $display("cmps=%0b, con_jmp=%0b, cmpxchg=%0b, cmovc=%0b", from_mem_cmps, from_mem_con_jmp, from_mem_cmpxchg, from_mem_cmovc);
        $display("gp_dsta_mux=%04b, gp_dstb_mux=%03b, seg_dst_mux=%0b, mm_dst_mux=%02b", from_mem_gp_dsta_mux, from_mem_gp_dstb_mux, from_mem_seg_dst_mux, from_mem_mm_dst_mux);
        $display("store_data_mux=%04b", from_mem_store_data_mux);
        $display("rw=%02b, ds=%02b", from_mem_rw, from_mem_ds);
        $display("rm=%0b, op_ovr=%0b, palu_size=%0b", from_mem_rm, from_mem_op_ovr, from_mem_palu_size);
        $display("----------------------------------------------------------------");
    end
    endtask

    task print_from_ex_sigs;
    begin 
        $display("----------------------------------------------------------------");
        $display("ldAB=%02b, dstA_size=%02b, dstB_size=%02b", from_ex_ldAB, from_ex_dstA_size, from_ex_dstB_size);
        $display("ldREGS=%03b", from_ex_ldREGS);
        $display("rw=%02b, ds=%02b", from_ex_rw, from_ex_ds);
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
        $display("(%0d)sreg1=[%0d]%04h, slim1=%05h", to_dep_needREGS[3], to_dep_SREG1_idx, from_rr_sreg1, from_rr_slim1);
        $display("(%0d)base1=[%0d]%08h, (%0d)index1=[%0d]%08h, scale_mux=%02b, disp=%08h", to_dep_needREGS[7], to_dep_basereg1_idx, from_rr_base1, to_dep_needREGS[5], to_dep_indexreg1_idx, from_rr_index1, from_rr_scale_mux, from_rr_disp);
        $display("(%0d)sreg2=[%0d]%04h, slim2=%04h", to_dep_needREGS[2], to_dep_SREG2_idx, from_rr_sreg2, from_rr_slim2);
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
        $display("rel_eip=%08h", from_ag_rel_eip);
        $display("ld_addr=%08h, ld_offset=%08h, ld_slim=%05h", from_ag_ld_addr, from_ag_ld_offset, from_ag_ld_slim);
        $display("st_addr=%08h, st_offset=%08h, st_slim=%05h", from_ag_st_addr, from_ag_st_offset, from_ag_st_slim);
        $display("inc_esp=%08h, dec_esp=%05h", from_ag_inc_esp, from_ag_dec_esp);
        $display("imm=%08h", from_ag_imm);
        $display("exception=%02b", from_ag_exception);
        $display("oeip=%08h, ieip=%08h, pred_eip=%08h, cs=%04h", from_ag_oeip, from_ag_ieip, from_ag_pred_eip, from_ag_cs);
        $display("valid=%0b, stall=%0b", from_ag_valid, from_ag_stall);
        $display("\n");
    end
    endtask

    task print_mem_outputs;
    begin 
        $display("************************************************");
        $display("*               MEM TO EX                      *");
        $display("************************************************");
        $display("control signals=%b", from_mem_control_sigs);
        print_from_mem_sigs();
        $display("dstidA=%0d, dstidB=%0d", from_mem_dstidA, from_mem_dstidB);
        $display("srcregA=%08h, srcregB=%08h, srcregC=%08h", from_mem_srcregA, from_mem_srcregB, from_mem_srcregC);
        $display("srcSREG=%04h, MMA=%016h, MMB=%016h", from_mem_srcSREG, from_mem_MMA, from_mem_MMB);
        $display("target_cs=%04h", from_mem_target_cs);
        $display("rel_eip=%08h", from_mem_rel_eip);
        $display("load_result=%04h", from_mem_load_result);
        $display("inc_esp=%08h, dec_esp=%05h", from_mem_inc_esp, from_mem_dec_esp);
        $display("imm=%08h", from_mem_imm);
        $display("store_is_io_line0=%0b, store_addr_line0=%03h, store_mask_line0=%04h, store_queue_alloc_line0=%0b", from_mem_store_is_io_line_0, from_mem_store_addr_line_0, from_mem_store_mask_line_0, from_mem_store_queue_alloc_line_0);
        $display("store_addr_line1=%03h, store_mask_line1=%04h, store_queue_alloc_line1=%0b, store_data_shf_amt=%0h", from_mem_store_addr_line_1, from_mem_store_mask_line_1, from_mem_store_queue_alloc_line_1, from_mem_store_data_shf_amt);
        $display("exception=%02b", from_mem_exception);
        $display("oeip=%08h, ieip=%08h, pred_eip=%08h, cs=%04h", from_mem_oeip, from_mem_ieip, from_mem_pred_eip, from_mem_cs);
        $display("valid=%0b, stall=%0b", from_mem_valid, from_mem_stall);
        $display("\n");
    end
    endtask

    task print_ex_outputs;
    begin 
        $display("************************************************");
        $display("*               EX TO WB.                      *");
        $display("************************************************");
        $display("control signals=%b", from_ex_control_sigs);
        print_from_ex_sigs();
        $display("dstidA=%0d, dstidB=%0d", from_ex_dstidA, from_ex_dstidB);
        $display("gp_wr_data1=%08h, gp_wr_data2=%08h", from_ex_gp_wr_data_1, from_ex_gp_wr_data_2);
        $display("seg_wr_data=%04h", from_ex_seg_wr_data);
        $display("mmx_wr_data=%016h", from_ex_mmx_wr_data);
        $display("store_data=%016h", from_ex_store_data);
        $display("eflags=%08h", dut_stage_ex.eflags_inst.eflags_din);
        $display("ld_cs=%0b, cs_target=%08h", from_ex_ld_cs, from_ex_cs_target);
        $display("mispredict=%0b, br_valid=%0b, br_t_nt=%0b, eip_target=%08h, flush=%0b", dut_stage_ex.mispredict, from_ex_br_valid, from_ex_br_t_nt, from_ex_eip_target, from_ex_flush);
        $display("store_is_io_line0=%0b, store_addr_line0=%03h, store_mask_line0=%04h, store_queue_alloc_line0=%0b", from_ex_store_is_io_line_0, from_ex_store_addr_line_0, from_ex_store_mask_line_0, from_ex_store_queue_alloc_line_0);
        $display("store_addr_line1=%03h, store_mask_line1=%04h, store_queue_alloc_line1=%0b, store_data_shf_amt=%0h", from_ex_store_addr_line_1, from_ex_store_mask_line_1, from_ex_store_queue_alloc_line_1, from_ex_store_data_shf_amt);
        $display("exception=%02b", from_ex_exception);
        $display("oeip=%08h, cs=%04h", from_ex_oeip, from_ex_cs);
        $display("valid=%0b", from_ex_valid);
        $display("\n");
    end
    endtask

    task insert_nop; 
        apply_de_inputs(6'b000110, 8'h01, 8'hc0, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'h0, 2'b0, 1'b0);
    endtask

    task quiet_test;
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
        input [31:0] pred_eip;
        input [1:0] exception;
        input valid;
    begin 
        @(posedge clk);
        apply_de_inputs(prefix, opcode, modrm, sib, disp, dispsize, imm, imm_size, addr_mode, oeip, ieip, pred_eip, exception, valid);
        #8 
        @(posedge clk);
        insert_nop();
        #8
        @(posedge clk);
        insert_nop();
        #8
        @(posedge clk);
        insert_nop();
        #8
        @(posedge clk);
        insert_nop();
        #8;
    end
    endtask

    task test_with_nops;
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
        input [31:0] pred_eip;
        input [1:0] exception;
        input valid;
    begin 
        @(posedge clk);
        apply_de_inputs(prefix, opcode, modrm, sib, disp, dispsize, imm, imm_size, addr_mode, oeip, ieip, pred_eip, exception, valid);
        #8 
        // print_rr_outputs();
        @(posedge clk);
        insert_nop();
        #8
        // print_ag_outputs();
        @(posedge clk);
        insert_nop();
        #8
        // print_mem_outputs();
        @(posedge clk);
        insert_nop();
        #8
        print_ex_outputs();
        @(posedge clk);
        insert_nop();
        #8
        $display("eflags=%08h", dut_stage_ex.eflags_out);
        $display("\n");
        NUM_TESTS = NUM_TESTS + 1;
    end
    endtask

    task clear_eflags_with_add;
    begin
        quiet_test(6'b000110, 8'h80, 8'hc7, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        $display("cleared eflags=%08h", dut_stage_ex.eflags_out);
        $display("\n");
    end
    endtask

    task set_cf_with_add;
    begin
        quiet_test(6'b000110, 8'h80, 8'hc3, 8'bx, 32'bx, 2'b00,
                        48'hff, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        $display("set eflags=%08h", dut_stage_ex.eflags_out);
        $display("\n");
    end
    endtask

    task set_zf_with_add;
    begin
        quiet_test(6'b000110, 8'h00, 8'hc0, 8'bx, 32'bx, 2'b00,
                        48'hff, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        $display("set eflags=%08h", dut_stage_ex.eflags_out);
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

        $display("eflags=%08h", dut_stage_ex.eflags_out);
        $display("\n");
        
        /* ******************************************************* */
        /* *                      ALU                            * */
        /* ******************************************************* */

        $display("======================================");
        $display("TEST CASE%0d: ADD EAX, ECX", NUM_TESTS);
        $display("======================================");
        // 01 C8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h01, 8'hc8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: ADD BH, 0x8", NUM_TESTS);
        $display("======================================");
        // 80 c7 08
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h80, 8'hc7, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: ADD BX, 0x1234", NUM_TESTS);
        $display("======================================");
        // 66 81 c3 34 12
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h81, 8'hc3, 8'bx, 32'bx, 2'b00,
                        48'h1234, 3'b010, 2'b01, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
        
        
        $display("======================================");
        $display("TEST CASE%0d: ADD [EBX], CH", NUM_TESTS);
        $display("======================================");
        // 00 2b=00000000 00101011
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h00, 8'h2b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: ADD EAX, 0x12345678", NUM_TESTS);
        $display("======================================");
        // 05 78 56 34 12
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h05, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h12345678, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: ADC EAX, ECX", NUM_TESTS);
        $display("======================================");
        // 11 C8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h11, 8'hC8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);
        

        $display("======================================");
        $display("TEST CASE%0d: AND [EBX], EAX", NUM_TESTS);
        $display("======================================");
        // 21 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h21, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: OR CX, DX", NUM_TESTS);
        $display("======================================");
        // 66 09 d1
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h09, 8'hd1, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: SBB EDX, ECX", NUM_TESTS);
        $display("======================================");
        // 19 CA
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h19, 8'hCA, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                     PALU                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: PACKSSWB MM1, MM2", NUM_TESTS);
        $display("======================================");
        // 0f 63 ca
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h63, 8'hCA, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: PACKSSDW MM0,[EBX]", NUM_TESTS);
        $display("======================================");
        // 0f 6b 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h6b, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: PADDW MM0, [EBX]", NUM_TESTS);
        $display("======================================");
        // 0f fd 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'hfd, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: PAVGB MM0, MM2", NUM_TESTS);
        $display("======================================");
        // 0f e0 c2
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'he0, 8'hc2, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: PAVGW MM0, [EBX]", NUM_TESTS);
        $display("======================================");
        // 0f e3 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'he3, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                      BSF                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: BSF AX, DX", NUM_TESTS);
        $display("======================================");
        // 66 0f bc c2
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010111, 8'hbc, 8'hc2, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h4, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                       NOT                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: NOT AL", NUM_TESTS);
        $display("======================================");
        // f6 d0
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hf6, 8'hd0, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: NOT [ECX]", NUM_TESTS);
        $display("======================================");
        // 66 f7 11
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hf7, 8'h11, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                       AAA                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: AAA (manually set AL=0xF)", NUM_TESTS);
        $display("======================================");
        // 37
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h37, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                       SHF                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: SAL BL, 2", NUM_TESTS);
        $display("======================================");
        // c0 e3 02
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hc0, 8'he3, 8'bx, 32'bx, 2'b00,
                        48'h2, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: SAL EBX, CL", NUM_TESTS);
        $display("======================================");
        // d3 e3 =11100011
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hd3, 8'he3, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: SAR CL, 2", NUM_TESTS);
        $display("======================================");
        // c0 f9 02
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hc0, 8'hf9, 8'bx, 32'bx, 2'b00,
                        48'h2, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: SAR EBX, CL", NUM_TESTS);
        $display("======================================");
        // d3 fb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hd3, 8'hfb, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                     POP/PUSH                          * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: POP EAX", NUM_TESTS);
        $display("======================================");
        // 58
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h58, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: POP word [EBX]", NUM_TESTS);
        $display("======================================");
        // 66 8f 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h8f, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: POP DS", NUM_TESTS);
        $display("======================================");
        // 1f
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h1f, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
         
        $display("======================================");
        $display("TEST CASE%0d: PUSH CX", NUM_TESTS);
        $display("======================================");
        // 66 51
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h51, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: PUSH word [EBX]", NUM_TESTS);
        $display("======================================");
        // 66 ff 33
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hff, 8'h33, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: PUSH 0x11", NUM_TESTS);
        $display("======================================");
        // 6a 11
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h6a, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h11, 3'b001, 2'b00, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: PUSH CS", NUM_TESTS);
        $display("======================================");
        // 0e
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h0e, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                      MOV                            * */
        // /* ******************************************************* */
        
        $display("======================================");
        $display("TEST CASE%0d: MOV AX, CX", NUM_TESTS);
        $display("======================================");
        // 66 89 c8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h89, 8'hc8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV WORD [EBX], CX", NUM_TESTS);
        $display("======================================");
        // 66 89 0b
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h89, 8'h0b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV BYTE AL, [ECX]", NUM_TESTS);
        $display("======================================");
        // 8a 01
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h8a, 8'h01, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV DS, AX", NUM_TESTS);
        $display("======================================");
        // 8e d8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h8e, 8'hd8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: MOV DS, WORD [EBX]", NUM_TESTS);
        $display("======================================");
        // 8e 1b
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h8e, 8'h1b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV WORD [EBX], DS", NUM_TESTS);
        $display("======================================");
        // 8c 1b
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h8c, 8'h1b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV EAX, 0x12345678", NUM_TESTS);
        $display("======================================");
        // b8 78 56 34 12 
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hb8, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h12345678, 3'b100, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOV [EBX+2*ESI+1], 0x12345678", NUM_TESTS);
        $display("======================================");
        // c7 44 73 01 78 56 34 12 
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hc7, 8'h44, 8'h73, 32'h01, 2'b01,
                        48'h12345678, 3'b100, 2'b11, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOVQ [EBX], MM1", NUM_TESTS);
        $display("======================================");
        // 0f 7f 0b 
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h7f, 8'h0b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOVQ MM0, MM4", NUM_TESTS);
        $display("======================================");
        // 0f 6f c4
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h6f, 8'hc4, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        

        // /* ******************************************************* */
        // /* *                     CMOV                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: CMOVC EAX, ECX (CF=0)", NUM_TESTS);
        $display("======================================");
        // 0f 42 c1
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h42, 8'hc1, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CMOVC EAX, ECX (Set CF=1)", NUM_TESTS);
        $display("======================================");
        // 0f 42 c1
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        set_cf_with_add();
        test_with_nops(6'b000111, 8'h42, 8'hc1, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        clear_eflags_with_add();

        // /* ******************************************************* */
        // /* *                     XCHG                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: XCHG CX, AX", NUM_TESTS);
        $display("======================================");
        // 66 91
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h91, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: XCHG byte [EBX], CH", NUM_TESTS);
        $display("======================================");
        // 86 2b
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h86, 8'h2b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: XCHG BL, CH", NUM_TESTS);
        $display("======================================");
        // 86 eb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h86, 8'heb, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                  CMPXCHG                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: CMPXCHG AL, CH", NUM_TESTS);
        $display("======================================");
        // 0f b0 e8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'hb0, 8'he8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CMPXCHG WORD [EBX], CX", NUM_TESTS);
        $display("======================================");
        // 66 0f b1 0b
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010111, 8'hb1, 8'h0b, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h1, 32'bx, 2'b0, 1'b1);
        
        // /* ******************************************************* */
        // /* *                     Jcc                             * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: JNBE 2 (Taken)", NUM_TESTS);
        $display("======================================");
        // 77 02
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h77, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h02, 3'b001, 2'b00, 32'h0, 32'h2, 32'h4, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: JNBE 2 (ZF=1, Not Taken)", NUM_TESTS);
        $display("======================================");
        // 77 02
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        set_zf_with_add();
        test_with_nops(6'b000110, 8'h77, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h02, 3'b001, 2'b00, 32'h0, 32'h2, 32'h4, 2'b0, 1'b1);
        clear_eflags_with_add();

        $display("======================================");
        $display("TEST CASE%0d: JNBE FF (CF=1, Not Taken, sign-extended)", NUM_TESTS);
        $display("======================================");
        // 77 FF
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        set_cf_with_add();
        test_with_nops(6'b000110, 8'h77, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'hFF, 3'b001, 2'b00, 32'h0, 32'h2, 32'h4, 2'b0, 1'b1);
        clear_eflags_with_add();

        $display("======================================");
        $display("TEST CASE%0d: JNE 0x11111111 (Taken but with exception)", NUM_TESTS);
        $display("======================================");
        // 0F 85 11 11 11 11
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h85, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h1111_1111, 3'b100, 2'b00, 32'h0, 32'h6, 32'h4, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: JNE 0x11111111 (Taken, with operand_override so no exception)", NUM_TESTS);
        $display("======================================");
        // 66 0F 85 11 11 11 11
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010111, 8'h85, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h1111_1111, 3'b100, 2'b00, 32'h0, 32'h7, 32'h4, 2'b0, 1'b1);

        /* ******************************************************* */
        /* *                     JMP                             * */
        /* ******************************************************* */

        $display("======================================");
        $display("TEST CASE%0d: JMP 0xFFFF (Taken, Predict Correctly)", NUM_TESTS);
        $display("======================================");
        // 66 e9 ff fb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'he9, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'hfffb, 3'b010, 2'b00, 32'h7, 32'hb, 32'h6, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: JMP DX (Taken, Predict Incorrectly)", NUM_TESTS);
        $display("======================================");
        // 66 ff e2
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hff, 8'he2, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'h6, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: JMP DWORD [EBX] (Taken, Predict Incorrectly, Exception)", NUM_TESTS);
        $display("======================================");
        // ff 23
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hff, 8'h23, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'h6, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: JMP far 0x12:0x3456 (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // ea 56 34 00 00 12 00 
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hea, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h001200003456, 3'b110, 2'b00, 32'h0, 32'h3, 32'h00003456, 2'b0, 1'b1);

        /* ******************************************************* */
        /* *                     CALL                            * */
        /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: CALL 0x4 (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // e8 04 00 00 00  
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'he8, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h4, 3'b100, 2'b00, 32'h0, 32'h5, 32'h3, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CALL BX (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // 66 ff d3
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hff, 8'hd3, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h3, 32'h3, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CALL dword [EBX] (Taken, Predict Incorrectly, Exception)", NUM_TESTS);
        $display("======================================");
        // ff 13
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hff, 8'h13, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'h3, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CALL far 0x12:0x3456789a (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // 9a 9a 78 56 34 12 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h9a, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h00123456789a, 3'b110, 2'b00, 32'h0, 32'h7, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CALL far 0x12:0x3456 (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // 66 56 34 12 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h9a, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h00123456, 3'b100, 2'b00, 32'h0, 32'h8, 32'h00003456, 2'b0, 1'b1);

        // /* ******************************************************* */
        // /* *                      RET                            * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: RET near (Taken, Predict Incorrectly, No Exception)", NUM_TESTS);
        $display("======================================");
        // C3
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hC3, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: RET near (with operand_size override)", NUM_TESTS);
        $display("======================================");
        // 66 C3
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hC3, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1236, 32'h00003456, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: RET near 0x8", NUM_TESTS);
        $display("======================================");
        // C2 08 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hC2, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b010, 2'b00, 32'h1234, 32'h1237, 32'h00003456, 2'b0, 1'b1);

        $display("======================================");
        $display("TEST CASE%0d: RET far", NUM_TESTS);
        $display("======================================");
        // cb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hcb, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TTEST CASE%0d: RET far (with operand_size override)", NUM_TESTS);
        $display("======================================");
        // 66 cb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'hcb, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: RET far 0x8", NUM_TESTS);
        $display("======================================");
        // ca 08 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hca, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b010, 2'b00, 32'h1234, 32'h1237, 32'h00003456, 2'b0, 1'b1);
        
        // /* ******************************************************* */
        // /* *                  STD/CLD/MOVS                         * */
        // /* ******************************************************* */
        $display("======================================");
        $display("TEST CASE%0d: STD", NUM_TESTS);
        $display("======================================");
        // fd
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hfd, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOVSB", NUM_TESTS);
        $display("======================================");
        // a4
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'ha4, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOVSW", NUM_TESTS);
        $display("======================================");
        // 66 a5
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'ha5, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: CLD", NUM_TESTS);
        $display("======================================");
        // fc
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hfc, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
        
        $display("======================================");
        $display("TEST CASE%0d: MOVSD", NUM_TESTS);
        $display("======================================");
        // a5
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'ha5, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h1234, 32'h1235, 32'h00003456, 2'b0, 1'b1);
                        
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule