module fetch_decode_top(
    input wire clk,
    input wire rst_bar,

    // TLB I/O
    output wire [19:0] ITLB_VPN, //stage fetch a
    input wire [2:0]  ITLB_PFN_OUT, 
    input wire ITLB_PAGE_FAULT_OUT,

    // Cache I/o
    input wire ICACHE_VALID,
    input wire [127:0] ICACHE_HIT_DATA,
    output wire [11:0] F_PAGE_OFFSET, //stage fetch a

    // Pipeline Inputs 
    input wire [15:0] from_rr_cs,
    input wire from_rr_stall,

    input wire from_ex_ld_cs,
    input wire [31:0] from_ex_eip_target,
    input wire from_ex_flush,
    input wire from_ex_br_t_nt,
    input wire from_ex_br_valid,
    input wire [3:0] from_ex_pht_idx,

    input wire from_wb_flush,

    //Outputs
    output wire [6:0] to_rr_prefix,
    output wire [7:0] to_rr_opcode,
    output wire [7:0] to_rr_modrm,
    output wire [7:0] to_rr_sib,
    output wire [31:0] to_rr_disp,
    output wire [1:0] to_rr_dispsize,
    output wire [47:0] to_rr_imm,
    output wire [2:0] to_rr_imm_size,
    output wire [1:0] to_rr_addr_mode,
    output wire [31:0] to_rr_oeip,
    output wire [31:0] to_rr_ieip,
    output wire [31:0] to_rr_pred_eip,
    output wire to_rr_pred_dir,
    output wire [3:0] to_rr_pht_idx,
    output wire [31:0] to_pr_pred_eip,
    output wire [1:0] to_rr_exception,
    output wire [95:0] to_rr_ucode_sigs,
    output wire to_rr_valid
);

    //Internal Wires
    wire from_fetch_buffer_shft_reg_we, from_de_take_branch, from_de_take_branch_prebuf;
    bufferH16$    bufferH16$_from_de_take_branch(from_de_take_branch, from_de_take_branch_prebuf);

    //TODO GATE UNLATCHED TAKE BRANCH SIGNAL AND VALID SIGNAL
    // wire redir_valid_DEBUG;
    // and2(redir_valid_DEBUG, , );

    stage_fetch_a STAGE_FETCH_FRONT_HALF(
        .clk(clk),
        .rst_bar(rst_bar),

        // Pipeline Inputs 
        .shft_reg_we(from_fetch_buffer_shft_reg_we), //from fetch buffer signal generated
        .from_de_bp_target(to_pr_pred_eip),
        .from_de_take_branch(from_de_take_branch),
        .from_rr_cs(from_rr_cs),
        .from_ex_eip_target(from_ex_eip_target),
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        
        .ic_addr(), //output unused in top
        .ITLB_VPN(ITLB_VPN), // TLB Output
        .F_PAGE_OFFSET(F_PAGE_OFFSET) // Cache Output
    );

    intgr_fshifter_decode FETCHBUFF_DECODESTAGE_DEPR(
        .clk(clk),
        .rst_bar(rst_bar),

        //fetch buffer inputs
        .from_f_cache_line(ICACHE_HIT_DATA), 
        .ICACHE_VALID(ICACHE_VALID),
        .from_wb_flush(from_wb_flush),

        //decode inputs
        .from_ex_eip_target(from_ex_eip_target),
        .from_rr_stall(from_rr_stall),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_flush(from_ex_flush),
        .from_ex_pht_idx(from_ex_pht_idx),
        .from_f_cl_pf(ITLB_PAGE_FAULT_OUT), //the cache line loaded had a page fault

        //outputs
        .to_rr_exception_flags(to_rr_exception),
        .to_rr_i_eip(to_rr_ieip),
        .to_rr_o_eip(to_rr_oeip),
        .to_rr_bp_target(to_rr_pred_eip), //post de latch
        .to_pr_bp_target(to_pr_pred_eip), //pre de latch
        .to_rr_pr_valid(to_rr_valid),
        .to_rr_pred_dir(to_rr_pred_dir),
        .to_rr_pht_idx(to_rr_pht_idx),
        .to_rr_prefixes(to_rr_prefix), //{prefix_seg, prefix_rep, prefix_op_size, prefix_seg_ov_id, prefix_ext}
        .to_rr_opcode(to_rr_opcode),
        .to_rr_modrm(to_rr_modrm),
        .to_rr_sib(to_rr_sib),
        .to_rr_disp_size_mux(to_rr_dispsize),
        .to_rr_disp(to_rr_disp),
        .to_rr_imm_size(to_rr_imm_size),
        .to_rr_imm(to_rr_imm),
        .to_rr_addressing_mode(to_rr_addr_mode),
        .to_rr_instr_length(), //unused in top
        .from_de_eip_redirection(from_de_take_branch_prebuf),
        .shft_reg_we(from_fetch_buffer_shft_reg_we),
        .to_rr_ucode_sigs(to_rr_ucode_sigs)
    );  


endmodule