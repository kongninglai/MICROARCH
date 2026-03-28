module intgr_fshifter_decode(
    input wire clk,
    input wire rst_bar,

    //fetch buffer inputs
    input wire [3:0] from_de_instr_len,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_de_stall,
    input wire from_f_cl_pf, //the cache line loaded had a page fault
    input wire [127:0] from_f_cache_line,
    input wire from_de_eip_redirection,
    input wire shft_reg_we, //only signal from first half of fetch
    
    //decode inputs
    input wire [19:0] from_ex_cs_limit_reg, 
    input wire [31:0] from_ex_eip_target,
    input wire from_rr_stall,
    input wire from_ex_br_t_nt,
    input wire from_ex_br_valid,
    input wire [3:0] from_ex_pht_idx


);  

    wire [4:0]  tail_ptr;
    wire [127:0] to_de_outbytes;
    wire [15:0] to_de_pf_expn_bytes_out;
    fetch_buffer FETCH_BUFF(
        .clk(clk), 
        .rst_bar(rst_bar),
        .from_de_instr_len(from_de_instr_len),
        .from_f_icache_valid(from_f_icache_valid),
        .from_de_valid(from_de_valid),
        .from_wb_flush(from_wb_flush),
        .from_ex_flush(from_ex_flush),
        .from_de_stall(from_de_stall),
        .from_f_cl_pf(from_f_cl_pf), 
        .from_f_cache_line(from_f_cache_line),
        .from_de_eip_redirection(from_de_eip_redirection), 
        .shft_reg_we(shft_reg_we),
        .tail_ptr(tail_ptr),
        .to_de_outbytes(to_de_outbytes),
        .to_de_pf_expn_bytes_out(to_de_pf_expn_bytes_out), 
        .ready() //unused
    );  

    stage_decode STAGE_DECODE(
        .cache_line(to_de_outbytes),
        .tail_ptr(tail_ptr),
        .cs_limit_reg(from_ex_cs_limit_reg),
        .eip_target_ex(from_ex_eip_target), //comes from execute stage
        .flush_ex(from_ex_flush), //comes from execute stage
        .v_excptn_src_wb(from_wb_flush), //comes from writeback stage
        .stall_rr(from_rr_stall), 

        .clk(clk),
        .rst_bar(rst_bar),
        .br_t_nt_ex_d(from_ex_br_t_nt), //comes from execute stage (taken not taken signal)
        .br_valid_ex_d(from_ex_br_valid), //comes from execute stage (branch valid signal)
        .pht_idx_ex_d(from_ex_pht_idx), //comes from execute stage:

        .exptn_prot(),
        output wire [31:0] i_eip,
        output wire pr_de_rr_valid, //to rr stage pipeline regs are valid

        //to fetch output
        output wire ld_eip, //to fetch stage to load new feip
        output wire [31:0] eip_true, //to fetch stage new feip
        output wire to_f_take_branch,

        //decoder output
        output wire prefix_rep,
        output wire prefix_op_size, 
        output wire [2:0] prefix_seg_ov_id,
        output wire prefix_ext,
        output wire [7:0] opcode,
        output wire [7:0] modrm,
        output wire [7:0] sib, 
        output wire [1:0] disp_size_mux,
        output wire [31:0] disp, 
        output wire [1:0] imm_size,
        output wire [47:0] imm,
        output wire [1:0] addressing_mode,
        output wire [3:0] instr_length
    );

endmodule