module stage_ex #(
    parameter EX_CONTROL_SIGS_WIDTH=59
)(
    input clk,
    input rst_n,
    input [EX_CONTROL_SIGS_WIDTH-1:0]    to_ex_control_sigs,
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
    input           to_ex_pred_dir, 
    input [3:0]     to_ex_pht_idx,
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

    /* WB FLUSH */
    input               from_wb_flush,
    /* FLUSH SIGNAL */
    output              from_ex_flush, 

    /* REP CMPS SIGNAL */
    output              from_ex_cmps_found,

     /* TO FETCH/DECODE SIGNALS */
    output              from_ex_ld_cs,
    output              from_ex_br_t_nt,
    output              from_ex_br_valid,
    output [15:0]       from_ex_cs_target,
    output [31:0]       from_ex_eip_target,
    output [3:0]        from_ex_pht_idx,

    output [16:0]       from_ex_control_sigs,
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
    output [31:0]       from_ex_ieip,
    output              from_ex_valid_store_inst,
    output              from_ex_valid,
    output [1:0]        from_ex_exception,

    /* TO DEP UNIT */
    output [1:0]        from_ex_dstA_size,
    output [1:0]        from_ex_dstB_size,
    output              from_ex_ld_gp0,
    output              from_ex_ld_gp1,
    output              from_ex_ld_seg,
    output              from_ex_ld_mmx,

    /* FROM WB FORWARDING */
    input        from_wb_gpwr0_idx_bit_2,
    input [31:0] from_wb_gpwr0_data,
    input [1:0]  from_wb_gpwr0_size,
    input        from_wb_gpwr0_en,
    input        from_wb_gpwr1_idx_bit_2,
    input [31:0] from_wb_gpwr1_data,
    input [1:0]  from_wb_gpwr1_size,
    input        from_wb_gpwr1_en,

    input [15:0] from_wb_segwr_data,
    input [63:0] from_wb_mmxwr_data
); 
    wire valid_instruction;

    /*** PASS THROUGH SIGNALS ***/
    bufferH64$  bufferH64$_from_ex_dstidA[2:0](from_ex_dstidA, to_ex_dstidA);  
    bufferH16$  bufferH16$_from_ex_dstidB[2:0](from_ex_dstidB, to_ex_dstidB);
    // assign from_ex_store_is_io_line_0 = to_ex_store_is_io_line_0;
    assign from_ex_store_addr_line_0 = to_ex_store_addr_line_0;
    assign from_ex_store_mask_line_0 = to_ex_store_mask_line_0;
    // assign from_ex_store_queue_alloc_line_0 = to_ex_store_queue_alloc_line_0;
    assign from_ex_store_addr_line_1 = to_ex_store_addr_line_1;
    assign from_ex_store_mask_line_1 = to_ex_store_mask_line_1;
    // assign from_ex_store_queue_alloc_line_1 = to_ex_store_queue_alloc_line_1;
    assign from_ex_store_data_shf_amt = to_ex_store_data_shf_amt;
    assign from_ex_oeip = to_ex_oeip;
    assign from_ex_pht_idx = to_ex_pht_idx;

    bufferH16$  bufferH16$_from_ex_valid(from_ex_valid, to_ex_valid);
    /*** Control Signals ***/
    wire [1:0] sig_ldAB, sig_dstA_size, sig_dstB_size, sig_shf_srcb_mux, sig_cs_mux, sig_mmx_op, sig_con_jmp, sig_mm_dst_mux, sig_rw, sig_ds;
    wire [1:0] sig_ds_buf64;
    bufferH64$  bufferH64$_sig_ds_buf64[1:0](sig_ds_buf64, sig_ds);
    wire sig_shf_op, sig_movs0, sig_movs1, sig_cmps0, sig_cmps1, sig_cmps2, sig_ldEFLAGS, sig_ldEIP, sig_ldCS, sig_alu_srcb_mux, sig_cmpxchg, sig_cmovc, sig_seg_dst_mux;
    wire sig_cmps2_prebuf;
    bufferH16$  bufferH16$_sig_cmps2(sig_cmps2, sig_cmps2_prebuf);

    wire sig_rm, sig_op_ovr, sig_palu_size, sig_sbb_dir, sig_iret0;
    wire sig_rm_buf16, sig_op_ovr_buf16, sig_palu_size_buf16;
    bufferH16$  bufferH16$_sig_rm_buf16(sig_rm_buf16, sig_rm);
    bufferH16$  bufferH16$_sig_op_ovr_buf16(sig_op_ovr_buf16, sig_op_ovr);
    bufferH16$  bufferH16$_sig_palu_size_buf16(sig_palu_size_buf16, sig_palu_size);

    wire [2:0] sig_ldREGS, sig_eflags_mux, sig_eip_mux, sig_alu_op, sig_gp_dstb_mux;
    wire [2:0] sig_eflags_mux_buf16;
    bufferH16$  bufferH16$_sig_eflags_mux_buf16[2:0](sig_eflags_mux_buf16, sig_eflags_mux);
   
    wire [3:0] sig_gp_dsta_mux, sig_store_data_mux;

    wire [8:0] EX_FW_CONTROL_SIGS;

    ex_sig #(.EX_CONTROL_SIGS_WIDTH(EX_CONTROL_SIGS_WIDTH)) ex_sig_parsing (
        .ucode_sig(to_ex_control_sigs),.ldAB(sig_ldAB),.dstA_size(sig_dstA_size),.dstB_size(sig_dstB_size),
        .ldREGS(sig_ldREGS),.ldEFLAGS(sig_ldEFLAGS),.ldEIP(sig_ldEIP),.ldCS(sig_ldCS),.alu_srcb_mux(sig_alu_srcb_mux),.shf_srcb_mux(sig_shf_srcb_mux),
        .eflags_mux(sig_eflags_mux),.eip_mux(sig_eip_mux),.cs_mux(sig_cs_mux),.mmx_op(sig_mmx_op),.alu_op(sig_alu_op),.shf_op(sig_shf_op),
        .movs0(sig_movs0), .movs1(sig_movs1), .cmps0(sig_cmps0), .cmps1(sig_cmps1), .cmps2(sig_cmps2_prebuf), .con_jmp(sig_con_jmp),.cmpxchg(sig_cmpxchg),.cmovc(sig_cmovc),
        .gp_dsta_mux(sig_gp_dsta_mux),.gp_dstb_mux(sig_gp_dstb_mux),.seg_dst_mux(sig_seg_dst_mux),.mm_dst_mux(sig_mm_dst_mux),
        .store_data_mux(sig_store_data_mux),.rw(sig_rw), .ds(sig_ds), .rm(sig_rm), .op_ovr(sig_op_ovr), .palu_size(sig_palu_size), .sbb_dir(sig_sbb_dir), .iret0(sig_iret0),
        .EX_FW_CONTROL_SIGS(EX_FW_CONTROL_SIGS)
    );

    wire [1:0] fw_A, fw_B, fw_C;
    wire fw_SREG, fw_MMA, fw_MMB;

    assign {fw_A, fw_B, fw_C, fw_SREG, fw_MMA, fw_MMB} = EX_FW_CONTROL_SIGS;

    wire [31:0] f_srcregA, f_srcregB, f_srcregC;
    wire [31:0] f_srcregA_buf16, f_srcregB_buf16;
    bufferH16$  bufferH16$_f_srcregA_buf16[31:0](f_srcregA_buf16, f_srcregA);
    bufferH16$  bufferH16$_f_srcregB_buf16[31:0](f_srcregB_buf16, f_srcregB);
    wire [15:0] f_srcSREG;
    wire [63:0] f_MMA, f_MMB;
    wire [63:0] f_MMA_buf64;
    bufferH64$  bufferH64$_f_MMA_buf64[63:0](f_MMA_buf64, f_MMA);
    wire [31:0] to_ex_srcregA_buf16;
    bufferH16$  bufferH16$_to_ex_srcregA_buf16[31:0](to_ex_srcregA_buf16, to_ex_srcregA);
    wire [31:0] to_ex_srcregB_buf16;
    bufferH16$  bufferH16$_to_ex_srcregB_buf16[31:0](to_ex_srcregB_buf16, to_ex_srcregB);
    wire [31:0] to_ex_srcregC_buf16;
    bufferH16$  bufferH16$_to_ex_srcregC_buf16[31:0](to_ex_srcregC_buf16, to_ex_srcregC);
    gp_forwarding gp_forward_A(
        .from_wb_gpwr0_idx_bit_2(from_wb_gpwr0_idx_bit_2),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx_bit_2(from_wb_gpwr1_idx_bit_2),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .srcreg(to_ex_srcregA_buf16),
        .fw_mux(fw_A),
        .f_reg(f_srcregA)
    );

    gp_forwarding gp_forward_B(
        .from_wb_gpwr0_idx_bit_2(from_wb_gpwr0_idx_bit_2),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx_bit_2(from_wb_gpwr1_idx_bit_2),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .srcreg(to_ex_srcregB_buf16),
        .fw_mux(fw_B),
        .f_reg(f_srcregB)
    );

    gp_forwarding gp_forward_C(
        .from_wb_gpwr0_idx_bit_2(from_wb_gpwr0_idx_bit_2),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx_bit_2(from_wb_gpwr1_idx_bit_2),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .srcreg(to_ex_srcregC_buf16),
        .fw_mux(fw_C),
        .f_reg(f_srcregC)
    );

    mux2_16$ mux2_f_srcSREG(f_srcSREG, to_ex_srcSREG, from_wb_segwr_data, fw_SREG);
    mux2_64  mux2_f_MMA(f_MMA, to_ex_MMA, from_wb_mmxwr_data, fw_MMA);
    mux2_64  mux2_f_MMB(f_MMB, to_ex_MMB, from_wb_mmxwr_data, fw_MMB);

    /*** EFLAGS ***/
    wire [31:0] alu_eflags, shf_eflags, bsf_eflags, aaa_eflags, cmp_eflags;
    wire [31:0] cmp_eflags_buf16;
    bufferH16$  bufferH16$_cmp_eflags_buf16[31:0](cmp_eflags_buf16, cmp_eflags);
    wire [31:0] alu_eflags_mask, shf_eflags_mask, bsf_eflags_mask, aaa_eflags_mask, cmp_eflags_mask;
    wire [31:0] eflags_out;
    wire eflags_af, eflags_cf, eflags_df, eflags_zf;
    assign eflags_af = eflags_out[4];
    bufferH16$  bufferH16$_eflags_cf(eflags_cf, eflags_out[0]);
    assign eflags_zf = eflags_out[6];
    bufferH16$  bufferH16$_eflags_df(eflags_df, eflags_out[10]);

    wire valid_ld_eflags;
    and2$ and_valid_ld_eflags(valid_ld_eflags, sig_ldEFLAGS, valid_instruction);

    wire [63:0] to_ex_load_result_buf16;
    bufferH16$  bufferH16$_to_ex_load_result_buf16[63:0](to_ex_load_result_buf16, to_ex_load_result);

    ex_eflags eflags_inst (
        .clk(clk),
        .rst_n(rst_n),
        .alu_eflags(alu_eflags),
        .shf_eflags(shf_eflags),
        .bsf_eflags(bsf_eflags),
        .aaa_eflags(aaa_eflags),
        .cmp_eflags(cmp_eflags_buf16),
        .alu_eflags_mask(alu_eflags_mask),
        .shf_eflags_mask(shf_eflags_mask),
        .bsf_eflags_mask(bsf_eflags_mask),
        .aaa_eflags_mask(aaa_eflags_mask),
        .cmp_eflags_mask(cmp_eflags_mask),
        .sig_eflags_mux(sig_eflags_mux_buf16),
        .LR(to_ex_load_result_buf16[31:0]),
        .ldEFLAGS(valid_ld_eflags),
        .eflags(eflags_out)
    );
    /*** Function Units ***/
    wire [31:0] regA_rm, regA_rm_buf64;
    mux2_32 mux2_regA_rm(regA_rm, f_srcregA_buf16, to_ex_load_result_buf16[31:0], sig_rm_buf16);
    bufferH64$  bufferH64$_regA_rm_buf64[31:0](regA_rm_buf64, regA_rm);
    
    // ALU
    wire [31:0] alu_op2, alu_op2_buf16;
    bufferH16$  bufferH16$_alu_op2_buf16[31:0](alu_op2_buf16, alu_op2);
    wire [31:0] alu_out;
    wire [31:0] to_ex_imm_buf16;
    bufferH16$  bufferH16$_to_ex_imm_buf16[31:0](to_ex_imm_buf16, to_ex_imm);
    mux2_32 mux2_alu_op2(alu_op2, f_srcregB_buf16, to_ex_imm_buf16, sig_alu_srcb_mux);
    ex_alu alu (
        .alu_op         (sig_alu_op),
        .ds             (sig_ds_buf64),
        .in0            (regA_rm_buf64),
        .in1            (alu_op2_buf16),
        .sbb_dir        (sig_sbb_dir),
        .eflags_cf      (eflags_cf),
        .alu_out        (alu_out),
        .alu_eflags     (alu_eflags),
        .alu_eflags_mask(alu_eflags_mask)
    );

    // SHF
    wire [7:0] shf_amt, shf_amt_buf256;
    wire [31:0] shf_out;
    mux4_8$ mux4_shf_amt(shf_amt, 8'h1, f_srcregC[7:0], to_ex_imm_buf16[7:0], 8'bx, sig_shf_srcb_mux[0], sig_shf_srcb_mux[1]);
    bufferH256$ bufferH256$_shf_amt_buf256[7:0](shf_amt_buf256, shf_amt);
    ex_shf shf (
        .shf_op(sig_shf_op),
        .ds(sig_ds_buf64),
        .shf_data(regA_rm_buf64),
        .shf_amt(shf_amt_buf256),
        .shf_out(shf_out),
        .shf_eflags(shf_eflags),
        .shf_eflags_mask(shf_eflags_mask)
    );

    // BSF
    wire [31:0] bsf_out;
    ex_bsf bsf (
        .bsf_data(regA_rm_buf64),
        .ds(sig_ds_buf64),
        .bsf_out(bsf_out),
        .bsf_eflags(bsf_eflags),
        .bsf_eflags_mask(bsf_eflags_mask)
    );

    // AAA
    wire [31:0] aaa_out;
    ex_aaa aaa (
        .eax(f_srcregA_buf16),
        .eflags_af(eflags_af),
        .aaa_out(aaa_out),
        .aaa_eflags(aaa_eflags),
        .aaa_eflags_mask(aaa_eflags_mask)
    );

    // CMP
    // LOAD TEMP CMPS0(DS:[ESI])
    wire [31:0] temp_cmps0;
    reg32e$ reg32e$_temp_cmps0(clk, to_ex_load_result_buf16[31:0], temp_cmps0, , rst_n, 1'b1, sig_cmps0);

    wire [31:0] temp_cmps1;
    reg32e$ reg32e$_temp_cmps1(clk, to_ex_load_result_buf16[31:0], temp_cmps1, , rst_n, 1'b1, sig_cmps1);

    wire [31:0] cmp_in0, cmp_in1;
    mux2_32 mux2_cmp_in0(cmp_in0, f_srcregC, temp_cmps0, sig_cmps2);
    mux2_32 mux2_cmp_in1(cmp_in1, regA_rm_buf64, temp_cmps1, sig_cmps2);

    ex_cmp cmp (
        .ds(sig_ds_buf64),
        .in0(cmp_in0),
        .in1(cmp_in1),
        .cmp_eflags(cmp_eflags),
        .cmp_eflags_mask(cmp_eflags_mask)
    );
    // from_ex_cmps_found = sig_cmps1 & zf=0 & valid_instruction
    wire cmp_zf_is_0;
    inv1$ inv1_cmps_zf(cmp_zf_is_0, cmp_eflags_buf16[6]);
    and3$ and_cmps_found(from_ex_cmps_found, sig_cmps2, cmp_zf_is_0, valid_instruction);
    // NOT
    wire [31:0] not_out;
    ex_not not_inst (
        .not_out(not_out), .not_in(regA_rm_buf64)
    );

    // INC
    wire [31:0] inc1_out, inc2_out;

    ex_inc inc1 (
        .inc_out(inc1_out), 
        .ds(sig_ds_buf64), 
        .eflags_df(eflags_df), 
        .inc_in(f_srcregA_buf16)
    );

    ex_inc inc2 (
        .inc_out(inc2_out), 
        .ds(sig_ds_buf64), 
        .eflags_df(eflags_df), 
        .inc_in(f_srcregB_buf16)
    );

    // DEC_ECX
    wire [31:0] dec_ecx_out;
    big_decrement #(
        .WIDTH(32)
    ) big_decrement_inc_ecx (
        .a(f_srcregA_buf16),
        .s(dec_ecx_out)
    );

    // PALU
    wire [63:0] MMB_rm, MMB_rm_buf64;
    bufferH64$  bufferH64$_MMB_rm_buf64[63:0](MMB_rm_buf64, MMB_rm);
    mux2_64 mux2_MMB_rm(MMB_rm, f_MMB, to_ex_load_result_buf16, sig_rm_buf16);
    wire [63:0] palu_out;
    ex_palu palu(
        .dest_in(f_MMA_buf64),
        .src_in(MMB_rm_buf64),
        .palu_size(sig_palu_size_buf16),
        .mmx_op(sig_mmx_op),
        .dest_out(palu_out)
    );  


    /*** REGFILE WRITE DATA*/
    mux16_32 mux16_gp_wr_data1(from_ex_gp_wr_data_1, alu_out, bsf_out, aaa_out, shf_out, not_out, inc1_out, regA_rm_buf64, f_srcregA_buf16, 
                                f_srcregB_buf16, {16'b0, f_srcSREG}, to_ex_imm_buf16, to_ex_load_result_buf16[31:0], dec_ecx_out, 32'bx, 32'bx, 32'bx, 
                                sig_gp_dsta_mux[0], sig_gp_dsta_mux[1], sig_gp_dsta_mux[2], sig_gp_dsta_mux[3]);
    
    mux8_32 mux8_gp_wr_data2(from_ex_gp_wr_data_2, inc2_out, to_ex_inc_esp, to_ex_dec_esp, regA_rm_buf64, f_srcregB_buf16, 32'bx, 32'bx, 32'bx, 
                                sig_gp_dstb_mux[0], sig_gp_dstb_mux[1], sig_gp_dstb_mux[2]);
    
    mux2_16$ mux2_seg_wr_data(from_ex_seg_wr_data, regA_rm_buf64[15:0], to_ex_load_result_buf16[15:0], sig_seg_dst_mux);

    mux4_64 mux4_mmx_wr_data(from_ex_mmx_wr_data, palu_out, f_MMB, MMB_rm_buf64, 64'bx, sig_mm_dst_mux[0], sig_mm_dst_mux[1]);

    wire [63:0] call_far_store_data;
    wire [31:0] to_ex_ieip_buf16;
    bufferH16$  bufferH16$_to_ex_ieip_buf16[31:0](to_ex_ieip_buf16, to_ex_ieip);
    mux2_64 mux2_call_far_store_data(call_far_store_data, {16'b0, to_ex_cs, to_ex_ieip_buf16}, {32'b0, to_ex_cs, to_ex_ieip_buf16[15:0]}, sig_op_ovr_buf16);
    mux16_64 mux16_store_data(from_ex_store_data, call_far_store_data,
                                                  {32'b0, to_ex_ieip_buf16},
                                                  {32'b0, alu_out},
                                                  {32'b0, shf_out},
                                                  {32'b0, not_out},
                                                  {32'b0, f_srcregB_buf16},
                                                  {48'b0, f_srcSREG},
                                                  f_MMA_buf64,
                                                  {32'b0, eflags_out}, // for exception, but we don't need to use a temp register?  
                                                  {32'b0, to_ex_imm_buf16},
                                                  to_ex_load_result_buf16,
                                                  {16'b0, to_ex_cs, to_ex_oeip}, {32'b0, regA_rm_buf64}, 64'bx, 64'bx, 64'bx,
                                                  sig_store_data_mux[0], sig_store_data_mux[1], sig_store_data_mux[2], sig_store_data_mux[3]);

    wire valid_iret0;
    and2$ and4_valid_iret0(valid_iret0, sig_iret0, to_ex_valid);

    wire [31:0] iret_eip, iret_eip_bar;
    wire [15:0] iret_cs, iret_cs_bar;
    reg32e$ reg_iret_eip(clk, to_ex_load_result_buf16[31:0], iret_eip, iret_eip_bar, rst_n, 1'b1, valid_iret0);
    reg16e reg_iret_cs(clk, to_ex_load_result_buf16[47:32], iret_cs, iret_cs_bar, rst_n, 1'b1, valid_iret0);

    // Control
    wire [31:0] target_eip, target_eip_buf16;
    bufferH16$  bufferH16$_target_eip_buf16[31:0](target_eip_buf16, target_eip);
    wire branch_taken, mispredict_bar;
    wire [31:0] jump_eip;

    wire direction_mispredict_wo_valid, target_mispredict_wo_valid, rel_target_mispredict_wo_valid;
    reg  [31:0] num_direction_mispredict, num_target_mispredict, num_rel_target_mispredict, total_valid_branch, total_mispredict;
    ex_control control (
        .r_m(regA_rm),
        .imm(to_ex_imm),
        .load_result(to_ex_load_result_buf16),
        .rel_eip(to_ex_rel_eip),
        .pred_eip(to_ex_pred_eip),
        .pred_dir(to_ex_pred_dir),
        .ieip(to_ex_ieip_buf16),
        .iret_eip(iret_eip),
        .sig_con_jump(sig_con_jmp),
        .sig_eip_mux(sig_eip_mux),
        .sig_op_ovr(sig_op_ovr_buf16),
        .eflags_zf(eflags_zf),
        .eflags_cf(eflags_cf),
        .jump_eip(jump_eip),
        .new_eip(target_eip),
        .branch_taken(branch_taken),
        .mispredict_bar(mispredict_bar),
        .direction_mispredict(direction_mispredict_wo_valid),
        .target_mispredict(target_mispredict_wo_valid),
        .rel_target_mispredict(rel_target_mispredict_wo_valid)
    ); 

    always @(posedge clk) begin
        if (!rst_n) begin 
            num_direction_mispredict    <= 32'h0;
            num_target_mispredict       <= 32'h0;
            num_rel_target_mispredict   <= 32'h0;
            total_valid_branch          <= 32'h0;
            total_mispredict            <= 32'h0;
        end else if (from_ex_br_valid) begin 
            total_valid_branch          <= total_valid_branch + 1;
            num_direction_mispredict    <= (direction_mispredict_wo_valid) ? (num_direction_mispredict+1) : num_direction_mispredict;
            num_target_mispredict       <= (target_mispredict_wo_valid) ? (num_target_mispredict+1) : num_target_mispredict;
            num_rel_target_mispredict   <= (rel_target_mispredict_wo_valid) ? (num_rel_target_mispredict+1) : num_rel_target_mispredict;
            total_mispredict            <= mispredict_bar ? total_mispredict :  (total_mispredict+1);
        end
    end

    wire is_taken_branch;
    and2$ and2_is_taken_branch(is_taken_branch, branch_taken, sig_ldEIP);
    
    wire [15:0] ret_cs;
    mux2_16$ mux2_ret_cs(ret_cs, to_ex_load_result_buf16[47:32], to_ex_load_result_buf16[31:16], sig_op_ovr_buf16);
    mux4_16$ mux4_cs(from_ex_cs_target, to_ex_target_cs, ret_cs, to_ex_load_result_buf16[31:16], iret_cs, sig_cs_mux[0], sig_cs_mux[1]);
    
    wire branch_gp_exception, gp_exception;
    cmp_gt_32b cs_limit_cmp(.in0(jump_eip), .in1(to_ex_cs_limit), .gt(gp_exception));
    and2$ and_valid_gp_ex(branch_gp_exception, gp_exception, is_taken_branch);

    // TODO: How to filter out the exceptions/uncod ? do we need that? hurt performance, but rare
    // valid_instruction = ~to_ex_exception[0] & ~to_ex_exception[1] & ~jmp_gp_exception & to_ex_valid
    wire no_exception;
    nor3$ nor3_no_exception(no_exception, to_ex_exception[0], to_ex_exception[1], branch_gp_exception);
    wire wb_flush_bar;
    inv1$ inv1_wb_flush(wb_flush_bar, from_wb_flush);

    wire valid_instruction_bar;
    nand3$ nand_valid_instruction_bar(valid_instruction_bar, to_ex_valid, no_exception, wb_flush_bar);
    bufferHInv16$ bufferHInv16$_valid_instruction(valid_instruction, valid_instruction_bar);

    or2$ or_from_ex_exception(from_ex_exception[1], to_ex_exception[1], branch_gp_exception);
    assign from_ex_exception[0] = to_ex_exception[0];

    wire valid_ld_CS, valid_ld_EIP, sig_ldEIP_bar;
    inv1$ inv1_sig_ldEIP_bar(sig_ldEIP_bar, sig_ldEIP);
    and2$ and2_valid_ldCS(valid_ld_CS, valid_instruction, sig_ldCS);
    nor3$ nor3_valid_ldEIP(valid_ld_EIP, valid_instruction_bar, sig_ldEIP_bar, mispredict_bar);
    wire from_ex_flush_bar;
    nor3$ nor_flush_bar(from_ex_flush_bar, valid_ld_CS, valid_ld_EIP, from_ex_cmps_found);
    bufferHInv64$ bufferHInv64$_from_ex_flush(from_ex_flush, from_ex_flush_bar);
    assign from_ex_ld_cs = valid_ld_CS;
    
    wire [31:0] predicted_eip_or_ieip;
    mux2_32 mux2_predicted_eip_or_ieip(predicted_eip_or_ieip, to_ex_ieip_buf16, to_ex_pred_eip, to_ex_pred_dir);
    mux2_32 mux2_ieip(from_ex_ieip, predicted_eip_or_ieip, from_ex_eip_target, from_ex_flush);
    mux2_16$ mux2_cs(from_ex_cs, to_ex_cs, from_ex_cs_target, valid_ld_CS);

    assign from_ex_br_t_nt = branch_taken;

    wire from_ex_br_valid_bar;
    nand2$ and_br_valid(from_ex_br_valid_bar, sig_ldEIP, to_ex_valid);
    bufferHInv16$ bufferHInv16$_from_ex_br_valid(from_ex_br_valid, from_ex_br_valid_bar);
    // assign from_ex_br_valid = sig_ldEIP;

    wire [31:0] from_ex_eip_target_prebuf;
    mux2_32 mux2_32_eip_target(from_ex_eip_target_prebuf, target_eip_buf16, to_ex_ieip_buf16, sig_cmps2);
    // assign from_ex_eip_target = target_eip_buf16;
    bufferH16$  bufferH16$_from_ex_eip_target[31:0](from_ex_eip_target, from_ex_eip_target_prebuf);

    // ldAB for cmov/cmpxchg
    /* from_ex_control_sigs, */
    // if cmpxchg & r/m=r: ldA=ZF, ldB=~ZF
    // if cmpxchg & r/m=m: store=ZF, ldB=~ZF
    // if cmov: ldA=CF

    wire ldA_cmpxchg, ldA_cond, cmpxchg_ZF_inv, ldB_cond, sig_rm_is_r, cmpxchg_r, cmpxchg_m;
    inv1$ inv_sig_rm_is_r(sig_rm_is_r, sig_rm_buf16);
    and2$ and2_cmpxchg_r(cmpxchg_r, sig_cmpxchg, sig_rm_is_r);
    and2$ and2_cmpxchg_m(cmpxchg_m, sig_cmpxchg, sig_rm_buf16);
    
    wire cmpxchg_store_is_io_line_0, cmpxchg_store_queue_alloc_line_0, cmpxchg_store_queue_alloc_line_1;
    and2$ and2_cmpxchg_store_is_io_line_0(cmpxchg_store_is_io_line_0, to_ex_store_is_io_line_0, cmp_eflags_buf16[6]);
    and2$ and2_cmpxchg_store_queue_alloc_line_0(cmpxchg_store_queue_alloc_line_0, to_ex_store_queue_alloc_line_0, cmp_eflags_buf16[6]);
    and2$ and2_cmpxchg_store_queue_alloc_line_1(cmpxchg_store_queue_alloc_line_1, to_ex_store_queue_alloc_line_1, cmp_eflags_buf16[6]);

    mux2$ mux2_store_is_io_line_0(from_ex_store_is_io_line_0, to_ex_store_is_io_line_0, cmpxchg_store_is_io_line_0, cmpxchg_m);
    mux2$ mux2_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0, to_ex_store_queue_alloc_line_0, cmpxchg_store_queue_alloc_line_0, cmpxchg_m);
    mux2$ mux2_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1, to_ex_store_queue_alloc_line_1, cmpxchg_store_queue_alloc_line_1, cmpxchg_m);

    wire ldA_cmpxchg_r;
    and2$ and2_ldA_cmpxchg_r(ldA_cmpxchg_r, sig_ldAB[1], cmp_eflags_buf16[6]);
    mux2$ mux2_ldA_cmpxchg(ldA_cmpxchg, sig_ldAB[1], ldA_cmpxchg_r, cmpxchg_r);
    mux2$ mux2_ldA_cond(ldA_cond, ldA_cmpxchg, eflags_cf, sig_cmovc);

    inv1$ inv1_cmpxchg_ZF(cmpxchg_ZF_inv, cmp_eflags_buf16[6]);
    mux2$ mux2_ldB_cond(ldB_cond, sig_ldAB[0], cmpxchg_ZF_inv, sig_cmpxchg);

    wire gpwr0_en, gpwr1_en, mmxwr_en, segwr_en;
    wire inv_ldSEG_out;
    inv1$ inv_ldSEG(inv_ldSEG_out, sig_ldREGS[1]);
    and4$ and_gpwr0_en(gpwr0_en, ldA_cond, sig_ldREGS[2], inv_ldSEG_out, valid_instruction);

    and3$ and_gpwr1_en(gpwr1_en, ldB_cond, sig_ldREGS[2], valid_instruction);
    and3$ and_segwr_en(segwr_en, sig_ldAB[1], sig_ldREGS[1], valid_instruction);
    and3$ and_mmxwr_en(mmxwr_en, sig_ldAB[1], sig_ldREGS[0], valid_instruction);

    assign from_ex_control_sigs = {
        {gpwr0_en, gpwr1_en, segwr_en, mmxwr_en}, sig_dstA_size, sig_dstB_size, sig_rw, sig_ds_buf64,
        sig_movs0, sig_movs1, sig_cmps0, sig_cmps1, sig_cmps2
    };

    and2$ and2_valid_store_inst(from_ex_valid_store_inst, valid_instruction, sig_rw[0]);

    bufferH16$  bufferH16$_from_ex_dstA_size[1:0](from_ex_dstA_size, sig_dstA_size);
    bufferH16$  bufferH16$_from_ex_dstB_size[1:0](from_ex_dstB_size, sig_dstB_size);
    bufferH16$  bufferH16$_from_ex_ld_gp0(from_ex_ld_gp0, gpwr0_en);
    bufferH16$  bufferH16$_from_ex_ld_gp1(from_ex_ld_gp1, gpwr1_en);
    assign from_ex_ld_seg = segwr_en;
    assign from_ex_ld_mmx = mmxwr_en;
endmodule