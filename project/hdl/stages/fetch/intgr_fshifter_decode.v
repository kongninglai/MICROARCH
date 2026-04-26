module intgr_fshifter_decode #(
    parameter BP_EN=1'b1
)(
    input wire clk,
    input wire rst_bar,

    //fetch buffer inputs
    input wire [127:0] from_f_cache_line, //from first half of fetch
    input wire ICACHE_VALID, //from first half of fetch
    input wire from_wb_flush,

    //decode inputs
    input wire [31:0] from_ex_eip_target,
    input wire from_rr_stall,
    input wire from_ex_br_t_nt,
    input wire from_ex_br_valid,
    input wire from_ex_flush,
    input wire [3:0] from_ex_pht_idx,
    input wire from_f_cl_pf, //the cache line loaded had a page fault

    output wire [1:0] to_rr_exception_flags,
    output wire [31:0] to_rr_i_eip,
    output wire [31:0] to_rr_o_eip,
    output wire [31:0] to_rr_bp_target, //after latch
    output wire [31:0] to_pr_bp_target, //before latch
    output wire to_rr_pr_valid, 
    output wire to_rr_pred_dir,
    output wire [3:0] to_rr_pht_idx,
    output wire [6:0] to_rr_prefixes, //{prefix_seg, prefix_rep, prefix_op_size, prefix_seg_ov_id, prefix_ext}
    output wire [7:0] to_rr_opcode,
    output wire [7:0] to_rr_modrm,
    output wire [7:0] to_rr_sib, 
    output wire [1:0] to_rr_disp_size_mux,
    output wire [31:0] to_rr_disp, 
    output wire [2:0] to_rr_imm_size,
    output wire [47:0] to_rr_imm,
    output wire [1:0] to_rr_addressing_mode,
    output wire [3:0] to_rr_instr_length,
    output wire [95:0] to_rr_ucode_sigs,
    output wire from_de_eip_redirection,

    output wire shft_reg_we
);  

    wire [4:0]  tail_ptr;
    wire [3:0] to_pr_instr_length;
    wire [95:0] to_pr_ucode_sigs;

    wire to_pr_pr_valid, to_pr_pr_valid_buf16;
    bufferH16$  bufferH16$_to_pr_pr_valid_buf16(to_pr_pr_valid_buf16, to_pr_pr_valid);

    wire [127:0] to_de_outbytes;
    wire [15:0] to_de_pf_expn_bytes_out;
    wire [31:0] to_pr_i_eip, to_pr_o_eip;
    wire iq_full;

    fetch_buffer FETCH_BUFF(
        .clk(clk), 
        .rst_bar(rst_bar),
        .from_de_instr_len(to_pr_instr_length),
        .from_de_valid(to_pr_pr_valid),
        .from_wb_flush(from_wb_flush),
        .from_ex_flush(from_ex_flush),
        .from_de_stall(iq_full), //if decode stalls, fetch should still load cl if there is space (but should not decrement the tail pointer by the instr length because we are not moving to the next instruction if de stall -> logic_stall_flush )
        .from_f_cl_pf(from_f_cl_pf), 
        .from_f_cache_line(from_f_cache_line),
        .from_de_eip_redirection(from_de_eip_redirection), 
        .ICACHE_VALID(ICACHE_VALID),
        .offset(to_pr_o_eip[3:0]), //lower bits of current eip
        .shft_reg_we(shft_reg_we), //output to first half of fetch
        .tail_ptr(tail_ptr),
        .to_de_outbytes(to_de_outbytes),
        .to_de_pf_expn_bytes_out(to_de_pf_expn_bytes_out), 
        .ready() //unused
    );    

    wire to_pr_ld_pr_rr, to_pr_ld_pr_rr_prebuf;
    wire to_f_ld_eip;
    wire to_pr_prefix_rep, to_pr_prefix_op_size, to_pr_prefix_ext, to_pr_prefix_seg;
    wire [2:0] to_pr_prefix_seg_ov_id, to_pr_imm_size;
    wire [7:0] to_pr_opcode, to_pr_modrm, to_pr_sib;
    wire [1:0] to_pr_disp_size_mux, to_pr_addressing_mode, to_pr_exception_flags;
    wire to_pr_pred_dir;
    wire [3:0] to_pr_pht_idx;
    wire [31:0] to_pr_disp;
    wire [47:0] to_pr_imm;
    stage_decode #(
        .BP_EN(BP_EN)
    ) STAGE_DECODE(
        .cache_line(to_de_outbytes),
        .tail_ptr(tail_ptr),
        .eip_target_ex(from_ex_eip_target), //comes from execute stage
        .flush_ex(from_ex_flush), //comes from execute stage
        .from_wb_flush(from_wb_flush), //comes from writeback stage
        .stall_rr(iq_full), 

        .clk(clk),
        .rst_bar(rst_bar),
        .br_t_nt_ex_d(from_ex_br_t_nt), //comes from execute stage (taken not taken signal)
        .br_valid_ex_d(from_ex_br_valid), //comes from execute stage (branch valid signal)
        .pht_idx_ex_d(from_ex_pht_idx), //comes from execute stage:
        .from_f_pf_expn_bytes_out(to_de_pf_expn_bytes_out),

        //outputs
        .i_eip(to_pr_i_eip),
        .o_eip(to_pr_o_eip),
        .bp_eip_target(to_pr_bp_target),
        .pr_de_rr_valid(to_pr_pr_valid), //to rr stage pipeline regs are valid
        .pred_dir(to_pr_pred_dir),
        .pht_idx(to_pr_pht_idx),

        //to fetch output
        .ld_eip(), //unused in this tb (to fetch)
        .eip_true(), //unused in this tb (to fetch)
        .to_f_take_branch(from_de_eip_redirection), 

        //decoder output
        .prefix_rep(to_pr_prefix_rep),
        .prefix_op_size(to_pr_prefix_op_size),
        .prefix_seg_ov_id(to_pr_prefix_seg_ov_id),
        .prefix_seg(to_pr_prefix_seg),
        .prefix_ext(to_pr_prefix_ext),
        .opcode(to_pr_opcode),
        .modrm(to_pr_modrm),
        .sib(to_pr_sib),
        .disp_size_mux(to_pr_disp_size_mux),
        .disp(to_pr_disp),
        .imm_size(to_pr_imm_size),
        .imm(to_pr_imm),
        .addressing_mode(to_pr_addressing_mode),
        .instr_length(to_pr_instr_length),
        .ucode_sigs(to_pr_ucode_sigs),
        .ld_pr_rr(to_pr_ld_pr_rr_prebuf),
        .exception_flags(to_pr_exception_flags)

    );

    bufferH256$   bufferH256$_to_pr_ld_pr_rr(to_pr_ld_pr_rr, to_pr_ld_pr_rr_prebuf);

    
    //decoder output
    de_to_rr PR_DE_RR(
        .clk(clk),
        .rst(rst_bar),
        .from_rr_stall(from_rr_stall),
        .from_ex_flush(from_ex_flush),
        .from_wb_flush(from_wb_flush),

        .from_f_exception_flags(to_pr_exception_flags), // {Protection, Page Fault}

        .from_de_i_eip(to_pr_i_eip),
        .from_de_o_eip(to_pr_o_eip),
        .from_de_bp_target(to_pr_bp_target),
        .from_de_pr_valid(to_pr_pr_valid_buf16),
        .from_de_pred_dir(to_pr_pred_dir),
        .from_de_pht_idx(to_pr_pht_idx),

        //decoder output
        .from_de_prefix_rep(to_pr_prefix_rep),
        .from_de_prefix_op_size(to_pr_prefix_op_size),
        .from_de_prefix_seg_ov_id(to_pr_prefix_seg_ov_id),
        .from_de_prefix_seg(to_pr_prefix_seg),
        .from_de_prefix_ext(to_pr_prefix_ext),
        .from_de_opcode(to_pr_opcode),
        .from_de_modrm(to_pr_modrm),
        .from_de_sib(to_pr_sib),
        .from_de_disp_size_mux(to_pr_disp_size_mux),
        .from_de_disp(to_pr_disp),
        .from_de_imm_size(to_pr_imm_size),
        .from_de_imm(to_pr_imm),
        .from_de_addressing_mode(to_pr_addressing_mode),
        .from_de_instr_length(to_pr_instr_length),
        .from_de_ucode_sigs(to_pr_ucode_sigs),
        //outputs
        .to_rr_exception_flags(to_rr_exception_flags),
        .to_rr_i_eip(to_rr_i_eip),
        .to_rr_o_eip(to_rr_o_eip),
        .to_rr_bp_target(to_rr_bp_target),
        .to_rr_pr_valid(), 
        .to_rr_pred_dir(to_rr_pred_dir),
        .to_rr_pht_idx(to_rr_pht_idx),

        //to rr output
        .to_rr_prefixes(to_rr_prefixes), //{prefix_seg, prefix_rep, prefix_op_size, prefix_seg_ov_id, prefix_ext}
        .to_rr_opcode(to_rr_opcode),
        .to_rr_modrm(to_rr_modrm),
        .to_rr_sib(to_rr_sib), 
        .to_rr_disp_size_mux(to_rr_disp_size_mux),
        .to_rr_disp(to_rr_disp), 
        .to_rr_imm_size(to_rr_imm_size),
        .to_rr_imm(to_rr_imm),
        .to_rr_addressing_mode(to_rr_addressing_mode),
        .to_rr_instr_length(to_rr_instr_length),
        .to_rr_ucode_sigs(to_rr_ucode_sigs),
        .iq_full(iq_full),
        .to_rr_valid(to_rr_pr_valid)
    ); 

endmodule