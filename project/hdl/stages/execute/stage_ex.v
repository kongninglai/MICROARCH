module stage_ex(
    input clk,
    input rst_n,
    input [54:0]    to_ex_control_sigs,
    input [2:0]     to_ex_dstidA, 
    input [2:0]     to_ex_dstidB,
    input [31:0]    to_ex_srcregA,
    input [31:0]    to_ex_srcregB,
    input [31:0]    to_ex_srcregC,
    input [15:0]    to_ex_srcSREG,
    input [63:0]    to_ex_MMA,
    input [63:0]    to_ex_MMB,
    input [15:0]    to_ex_target_cs,
    input [63:0]    to_ex_load_result,
    input [31:0]    to_ex_inc_esp,
    input [31:0]    to_ex_dec_esp,
    input [31:0]    to_ex_imm,
    input           to_ex_store_is_io_line_0,
    input [10:0]    to_ex_store_addr_line_0,
    input [15:0]    to_ex_store_mask_line_0,
    input           to_ex_store_queue_alloc_line_0,
    input [10:0]    to_ex_store_addr_line_1,
    input [15:0]    to_ex_store_mask_line_1,
    input           to_ex_store_queue_alloc_line_1,
    input [4:0]     to_ex_store_data_shf_amt,
    input [31:0]    to_ex_rel_eip,
    input [15:0]    to_ex_cs,
    input [31:0]    to_ex_oeip,
    input [31:0]    to_ex_ieip,
    input [31:0]    to_ex_pred_eip,
    input [1:0]     to_ex_exception,
    input           to_ex_valid,

    /* TEMP REGISTER FOR CMPS*/
    input [31:0]    to_ex_CMPS0,
    input [31:0]    to_ex_CMPS1,

    /* TEMP REGISTER FOR EXCEPTION*/
    input [31:0]    to_ex_tempEIP,
    input [15:0]    to_ex_tempCS,

    /* CS LIMIT */
    input [31:0]        to_ex_cs_limit, 

    /* FLUSH SIGNAL */
    output              from_ex_flush, 


     /* TO FETCH/DECODE SIGNALS */
    output              from_ex_ld_cs,
    output              from_ex_br_t_nt,
    output              from_ex_br_valid,
    output [15:0]       from_ex_cs_target,
    output [31:0]       from_ex_eip_target,
    /*TODO: ADD from_ex_pht_idx[3:0] */

    output [11:0]       from_ex_control_sigs,
    output [2:0]        from_ex_dstidA, 
    output [2:0]        from_ex_dstidB,
    output [31:0]       from_ex_gp_wr_data_1,
    output [31:0]       from_ex_gp_wr_data_2,
    output [15:0]       from_ex_seg_wr_data,
    output [63:0]       from_ex_mmx_wr_data,
    output [63:0]       from_ex_store_data,
    output              from_ex_store_is_io_line_0,
    output [10:0]       from_ex_store_addr_line_0,
    output [15:0]       from_ex_store_mask_line_0,
    output              from_ex_store_queue_alloc_line_0,
    output [10:0]       from_ex_store_addr_line_1,
    output [15:0]       from_ex_store_mask_line_1,
    output              from_ex_store_queue_alloc_line_1,
    output [4:0]        from_ex_store_data_shf_amt,
    output [15:0]       from_ex_cs,
    output [31:0]       from_ex_oeip,
    output              from_ex_valid_store_inst,
    output              from_ex_valid,
    output [1:0]        from_ex_exception,

    /* TO DEP UNIT */
    input  [1:0]        from_ex_dstA_size,
    input  [1:0]        from_ex_dstB_size,
    input               from_ex_ld_gp0,
    input               from_ex_ld_gp1,
    input               from_ex_ld_seg,
    input               from_ex_ld_mmx
); 
    wire valid_instruction;

    /*** PASS THROUGH SIGNALS ***/
    assign from_ex_dstidA = to_ex_dstidA;
    assign from_ex_dstidB = to_ex_dstidB;
    // assign from_ex_store_is_io_line_0 = to_ex_store_is_io_line_0;
    assign from_ex_store_addr_line_0 = to_ex_store_addr_line_0;
    assign from_ex_store_mask_line_0 = to_ex_store_mask_line_0;
    // assign from_ex_store_queue_alloc_line_0 = to_ex_store_queue_alloc_line_0;
    assign from_ex_store_addr_line_1 = to_ex_store_addr_line_1;
    assign from_ex_store_mask_line_1 = to_ex_store_mask_line_1;
    // assign from_ex_store_queue_alloc_line_1 = to_ex_store_queue_alloc_line_1;
    assign from_ex_store_data_shf_amt = to_ex_store_data_shf_amt;
    assign from_ex_oeip = to_ex_oeip;
    assign from_ex_cs = to_ex_cs;
    assign from_ex_valid = to_ex_valid;
    /*** Control Signals ***/
    wire [1:0] sig_ldAB, sig_dstA_size, sig_dstB_size, sig_shf_srcb_mux, sig_cs_mux, sig_mmx_op, sig_con_jmp, sig_mm_dst_mux, sig_rw, sig_ds;

    wire sig_shf_op, sig_cmps, sig_ldEFLAGS, sig_ldEIP, sig_ldCS, sig_alu_srcb_mux, sig_cmpxchg, sig_cmovc, sig_seg_dst_mux;
    
    wire sig_rm, sig_op_ovr, sig_palu_size;

    wire [2:0] sig_ldREGS, sig_eflags_mux, sig_eip_mux, sig_alu_op, sig_gp_dstb_mux;
   
    wire [3:0] sig_gp_dsta_mux, sig_store_data_mux;

    ex_sig ex_sig_parsing (
        .ucode_sig(to_ex_control_sigs),.ldAB(sig_ldAB),.dstA_size(sig_dstA_size),.dstB_size(sig_dstB_size),
        .ldREGS(sig_ldREGS),.ldEFLAGS(sig_ldEFLAGS),.ldEIP(sig_ldEIP),.ldCS(sig_ldCS),.alu_srcb_mux(sig_alu_srcb_mux),.shf_srcb_mux(sig_shf_srcb_mux),
        .eflags_mux(sig_eflags_mux),.eip_mux(sig_eip_mux),.cs_mux(sig_cs_mux),.mmx_op(sig_mmx_op),.alu_op(sig_alu_op),.shf_op(sig_shf_op),
        .cmps(sig_cmps),.con_jmp(sig_con_jmp),.cmpxchg(sig_cmpxchg),.cmovc(sig_cmovc),
        .gp_dsta_mux(sig_gp_dsta_mux),.gp_dstb_mux(sig_gp_dstb_mux),.seg_dst_mux(sig_seg_dst_mux),.mm_dst_mux(sig_mm_dst_mux),
        .store_data_mux(sig_store_data_mux),.rw(sig_rw), .ds(sig_ds), .rm(sig_rm), .op_ovr(sig_op_ovr), .palu_size(sig_palu_size)
    );

    /*** EFLAGS ***/
    wire [31:0] alu_eflags, shf_eflags, bsf_eflags, aaa_eflags, cmp_eflags;
    wire [31:0] alu_eflags_mask, shf_eflags_mask, bsf_eflags_mask, aaa_eflags_mask, cmp_eflags_mask;
    wire [31:0] eflags_out;
    wire eflags_af, eflags_cf, eflags_df, eflags_zf;
    assign eflags_af = eflags_out[4];
    assign eflags_cf = eflags_out[0];
    assign eflags_zf = eflags_out[6];
    assign eflags_df = eflags_out[10];

    wire valid_ld_eflags;
    and2$ and_valid_ld_eflags(valid_ld_eflags, sig_ldEFLAGS, valid_instruction);
    ex_eflags eflags_inst (
        .clk(clk),
        .rst_n(rst_n),
        .alu_eflags(alu_eflags),
        .shf_eflags(shf_eflags),
        .bsf_eflags(bsf_eflags),
        .aaa_eflags(aaa_eflags),
        .cmp_eflags(cmp_eflags),
        .alu_eflags_mask(alu_eflags_mask),
        .shf_eflags_mask(shf_eflags_mask),
        .bsf_eflags_mask(bsf_eflags_mask),
        .aaa_eflags_mask(aaa_eflags_mask),
        .cmp_eflags_mask(cmp_eflags_mask),
        .sig_eflags_mux(sig_eflags_mux),
        .ldEFLAGS(valid_ld_eflags),
        .eflags(eflags_out)
    );
    /*** Function Units ***/
    wire [31:0] regA_rm;
    mux2_32 mux2_regA_rm(regA_rm, to_ex_srcregA, to_ex_load_result[31:0], sig_rm);
    
    // ALU
    wire [31:0] alu_op2;
    wire [31:0] alu_out;
    mux2_32 mux2_alu_op2(alu_op2, to_ex_srcregB, to_ex_imm, sig_alu_srcb_mux);
    ex_alu alu (
        .alu_op         (sig_alu_op),
        .ds             (sig_ds),
        .in0            (regA_rm),
        .in1            (alu_op2),
        .eflags_cf      (eflags_cf),
        .alu_out        (alu_out),
        .alu_eflags     (alu_eflags),
        .alu_eflags_mask(alu_eflags_mask)
    );

    // SHF
    wire [7:0] shf_amt;
    wire [31:0] shf_out;
    mux4_8$ mux4_shf_amt(shf_amt, 8'h1, to_ex_srcregC[7:0], to_ex_imm[7:0], 8'bx, sig_shf_srcb_mux[0], sig_shf_srcb_mux[1]);
    ex_shf shf (
        .shf_op(sig_shf_op),
        .ds(sig_ds),
        .shf_data(regA_rm),
        .shf_amt(shf_amt),
        .shf_out(shf_out),
        .shf_eflags(shf_eflags),
        .shf_eflags_mask(shf_eflags_mask)
    );

    // BSF
    wire [31:0] bsf_out;
    ex_bsf bsf (
        .bsf_data(regA_rm),
        .ds(sig_ds),
        .bsf_out(bsf_out),
        .bsf_eflags(bsf_eflags),
        .bsf_eflags_mask(bsf_eflags_mask)
    );

    // AAA
    wire [31:0] aaa_out;
    ex_aaa aaa (
        .eax(to_ex_srcregA),
        .eflags_af(eflags_af),
        .aaa_out(aaa_out),
        .aaa_eflags(aaa_eflags),
        .aaa_eflags_mask(aaa_eflags_mask)
    );

    // CMP
    wire [31:0] cmp_in0, cmp_in1;
    mux2_32 mux2_cmp_in0(cmp_in0, to_ex_srcregC, to_ex_CMPS0, sig_cmps);
    mux2_32 mux2_cmp_in1(cmp_in1, regA_rm, to_ex_CMPS1, sig_cmps);

    ex_cmp cmp (
        .ds(sig_ds),
        .in0(cmp_in0),
        .in1(cmp_in1),
        .cmp_eflags(cmp_eflags),
        .cmp_eflags_mask(cmp_eflags_mask)
    );

    // NOT
    wire [31:0] not_out;
    ex_not not_inst (
        .not_out(not_out), .not_in(regA_rm)
    );

    // INC
    wire [31:0] inc1_out, inc2_out;

    ex_inc inc1 (
        .inc_out(inc1_out), 
        .ds(sig_ds), 
        .eflags_df(eflags_df), 
        .inc_in(to_ex_srcregA)
    );

    ex_inc inc2 (
        .inc_out(inc2_out), 
        .ds(sig_ds), 
        .eflags_df(eflags_df), 
        .inc_in(to_ex_srcregB)
    );

    // INC_ECX
    wire [31:0] inc_ecx_out;
    big_increment #(
        .WIDTH(32)
    ) big_increment_inc_ecx (
        .a(to_ex_srcregA),
        .s(inc_ecx_out)
    );

    // PALU
    wire [63:0] MMB_rm;
    mux2_64 mux2_MMB_rm(MMB_rm, to_ex_MMB, to_ex_load_result, sig_rm);
    wire [63:0] palu_out;
    ex_palu palu(
        .dest_in(to_ex_MMA),
        .src_in(MMB_rm),
        .palu_size(sig_palu_size),
        .mmx_op(sig_mmx_op),
        .dest_out(palu_out)
    );  


    /*** REGFILE WRITE DATA*/
    mux16_32 mux16_gp_wr_data1(from_ex_gp_wr_data_1, alu_out, bsf_out, aaa_out, shf_out, not_out, inc1_out, regA_rm, to_ex_srcregA, 
                                to_ex_srcregB, {16'b0, to_ex_srcSREG}, to_ex_imm, to_ex_load_result[31:0], inc_ecx_out, 32'bx, 32'bx, 32'bx, 
                                sig_gp_dsta_mux[0], sig_gp_dsta_mux[1], sig_gp_dsta_mux[2], sig_gp_dsta_mux[3]);
    
    mux8_32 mux8_gp_wr_data2(from_ex_gp_wr_data_2, inc2_out, to_ex_inc_esp, to_ex_dec_esp, regA_rm, to_ex_srcregB, 32'bx, 32'bx, 32'bx, 
                                sig_gp_dstb_mux[0], sig_gp_dstb_mux[1], sig_gp_dstb_mux[2]);
    
    mux2_16$ mux2_seg_wr_data(from_ex_seg_wr_data, regA_rm[15:0], to_ex_load_result[15:0], sig_seg_dst_mux);

    mux4_64 mux4_mmx_wr_data(from_ex_mmx_wr_data, palu_out, to_ex_MMB, MMB_rm, 64'bx, sig_mm_dst_mux[0], sig_mm_dst_mux[1]);

    wire [63:0] call_far_store_data;
    mux2_64 mux2_call_far_store_data(call_far_store_data, {16'b0, to_ex_cs, to_ex_ieip}, {32'b0, to_ex_cs, to_ex_ieip[15:0]}, sig_op_ovr);
    mux16_64 mux16_store_data(from_ex_store_data, call_far_store_data,
                                                  {32'b0, to_ex_ieip},
                                                  {32'b0, alu_out},
                                                  {32'b0, shf_out},
                                                  {32'b0, not_out},
                                                  {32'b0, to_ex_srcregB},
                                                  {48'b0, to_ex_srcSREG},
                                                  to_ex_MMA,
                                                  {32'b0, eflags_out}, // for exception, but we don't need to use a temp register?  
                                                  {32'b0, to_ex_imm},
                                                  to_ex_load_result,
                                                  {16'b0, to_ex_tempCS, to_ex_tempEIP}, {32'b0, regA_rm}, 64'bx, 64'bx, 64'bx,
                                                  sig_store_data_mux[0], sig_store_data_mux[1], sig_store_data_mux[2], sig_store_data_mux[3]);


    // Control
    wire [31:0] target_eip;
    wire branch_taken, mispredict;
    ex_control control (
        .r_m(regA_rm),
        .imm(to_ex_imm),
        .load_result(to_ex_load_result),
        .rel_eip(to_ex_rel_eip),
        .pred_eip(to_ex_pred_eip),
        .ieip(to_ex_ieip),
        .sig_con_jump(sig_con_jmp),
        .sig_eip_mux(sig_eip_mux),
        .sig_op_ovr(sig_op_ovr),
        .eflags_zf(eflags_zf),
        .eflags_cf(eflags_cf),

        .new_eip(target_eip),
        .branch_taken(branch_taken),
        .mispredict(mispredict)
    ); 

    wire is_taken_branch;
    and2$ and2_is_taken_branch(is_taken_branch, branch_taken, sig_ldEIP);
    
    wire [15:0] ret_cs;
    mux2_16$ mux2_ret_cs(ret_cs, to_ex_load_result[47:32], to_ex_load_result[31:16], sig_op_ovr);
    mux4_16$ mux4_cs(from_ex_cs_target, to_ex_target_cs, ret_cs, to_ex_load_result[31:16], 16'bx, sig_cs_mux[0], sig_cs_mux[1]);
    
    wire branch_gp_exception, gp_exception;
    seg_limit_cmp cs_limit_cmp(.in(target_eip), .seg_limit(to_ex_cs_limit), .exception(gp_exception));
    and2$ and_valid_gp_ex(branch_gp_exception, gp_exception, is_taken_branch);

    // TODO: How to filter out the exceptions/uncod ? do we need that? hurt performance, but rare
    // valid_instruction = ~to_ex_exception[0] & ~to_ex_exception[1] & ~jmp_gp_exception & to_ex_valid
    wire no_exception;
    nor3$ nor3_no_exception(no_exception, to_ex_exception[0], to_ex_exception[1], branch_gp_exception);
    and2$ and_valid_instruction(valid_instruction, to_ex_valid, no_exception);

    or2$ or_from_ex_exception(from_ex_exception[0], to_ex_exception[0], branch_gp_exception);
    assign from_ex_exception[1] = to_ex_exception[1];

    wire valid_ld_CS, valid_ld_EIP;
    and2$ and2_valid_ldCS(valid_ld_CS, valid_instruction, sig_ldCS);
    and3$ and3_valid_ldEIP(valid_ld_EIP, valid_instruction, sig_ldEIP, mispredict);
    or2$ or_flush(from_ex_flush, valid_ld_CS, valid_ld_EIP);
    assign from_ex_ld_cs = valid_ld_CS;
    
    assign from_ex_br_t_nt = branch_taken;
    // and2$ and_br_valid(from_ex_br_valid, sig_ldEIP, from_ex_valid);
    assign from_ex_br_valid = sig_ldEIP;
    assign from_ex_eip_target = target_eip;

    // ldAB for cmov/cmpxchg
    /* from_ex_control_sigs, */
    // if cmpxchg & r/m=r: ldA=ZF, ldB=~ZF
    // if cmpxchg & r/m=m: store=ZF, ldB=~ZF
    // if cmov: ldA=CF

    wire ldA_cmpxchg, ldA_cond, cmpxchg_ZF_inv, ldB_cond, sig_rm_is_r, cmpxchg_r, cmpxchg_m;
    inv1$ inv_sig_rm_is_r(sig_rm_is_r, sig_rm);
    and2$ and2_cmpxchg_r(cmpxchg_r, sig_cmpxchg, sig_rm_is_r);
    and2$ and2_cmpxchg_m(cmpxchg_m, sig_cmpxchg, sig_rm);
    
    wire cmpxchg_store_is_io_line_0, cmpxchg_store_queue_alloc_line_0, cmpxchg_store_queue_alloc_line_1;
    and2$ and2_cmpxchg_store_is_io_line_0(cmpxchg_store_is_io_line_0, to_ex_store_is_io_line_0, cmp_eflags[6]);
    and2$ and2_cmpxchg_store_queue_alloc_line_0(cmpxchg_store_queue_alloc_line_0, to_ex_store_queue_alloc_line_0, cmp_eflags[6]);
    and2$ and2_cmpxchg_store_queue_alloc_line_1(cmpxchg_store_queue_alloc_line_1, to_ex_store_queue_alloc_line_1, cmp_eflags[6]);

    mux2$ mux2_store_is_io_line_0(from_ex_store_is_io_line_0, to_ex_store_is_io_line_0, cmpxchg_store_is_io_line_0, cmpxchg_m);
    mux2$ mux2_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0, to_ex_store_queue_alloc_line_0, cmpxchg_store_queue_alloc_line_0, cmpxchg_m);
    mux2$ mux2_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1, to_ex_store_queue_alloc_line_1, cmpxchg_store_queue_alloc_line_1, cmpxchg_m);

    wire ldA_cmpxchg_r;
    and2$ and2_ldA_cmpxchg_r(ldA_cmpxchg_r, sig_ldAB[1], cmp_eflags[6]);
    mux2$ mux2_ldA_cmpxchg(ldA_cmpxchg, sig_ldAB[1], ldA_cmpxchg_r, cmpxchg_r);
    mux2$ mux2_ldA_cond(ldA_cond, ldA_cmpxchg, eflags_cf, sig_cmovc);

    inv1$ inv1_cmpxchg_ZF(cmpxchg_ZF_inv, cmp_eflags[6]);
    mux2$ mux2_ldB_cond(ldB_cond, sig_ldAB[0], cmpxchg_ZF_inv, sig_cmpxchg);

    wire gpwr0_en, gpwr1_en, mmxwr_en, segwr_en;
    wire inv_ldSEG_out;
    inv1$ inv_ldSEG(inv_ldSEG_out, sig_ldREGS[1]);
    and4$ and_gpwr0_en(gpwr0_en, ldA_cond, sig_ldREGS[2], inv_ldSEG_out, valid_instruction);

    and3$ and_gpwr1_en(gpwr1_en, ldB_cond, sig_ldREGS[2], valid_instruction);
    and3$ and_segwr_en(segwr_en, sig_ldAB[1], sig_ldREGS[1], valid_instruction);
    and3$ and_mmxwr_en(mmxwr_en, sig_ldAB[1], sig_ldREGS[0], valid_instruction);

    assign from_ex_control_sigs = {
        {gpwr0_en, gpwr1_en, segwr_en, mmxwr_en}, sig_dstA_size, sig_dstB_size, sig_rw, sig_ds
    };

    and2$ and2_valid_store_inst(from_ex_valid_store_inst, valid_instruction, sig_rw[0]);

    assign from_ex_dstA_size = sig_dstA_size;
    assign from_ex_dstB_size = sig_dstB_size;
    assign from_ex_ld_gp0 = gpwr0_en;
    assign from_ex_ld_gp1 = gpwr1_en;
    assign from_ex_ld_seg = segwr_en;
    assign from_ex_ld_mmx = mmxwr_en;
endmodule