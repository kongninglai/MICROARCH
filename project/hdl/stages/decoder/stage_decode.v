module stage_decode(
    input wire [127:0] cache_line,
    input wire [4:0] tail_ptr,
    input wire [31:0] eip_target_ex, //comes from execute stage
    input wire flush_ex, //comes from execute stage
    input wire v_excptn_src_wb, //comes from writeback stage
    input wire stall_rr, 

    input wire clk, 
    input wire rst_bar,
    input wire br_t_nt_ex_d, //comes from execute stage (taken not taken signal)
    input wire br_valid_ex_d, //comes from execute stage (branch valid signal)
    input wire [3:0] pht_idx_ex_d, //comes from execute stage:
    input wire [15:0] from_f_pf_expn_bytes_out,

    output wire [31:0] i_eip,
    output wire [31:0] o_eip,
    output wire [31:0] bp_eip_target,
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
    output wire [2:0] imm_size,
    output wire [47:0] imm,
    output wire [1:0] addressing_mode,
    output wire [3:0] instr_length,

    output wire ld_pr_rr, //to load register read pipeline registers signal
    output wire [1:0] exception_flags

);

    wire modrm_v;
    block_decoder DECODER(
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm(modrm),
        .modrm_v(modrm_v),
        .sib(sib),
        .disp_size_mux(disp_size_mux),
        .disp(disp),
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .instr_length(instr_length)
    );     

    logic_stall_flush LOGIC_STALL_FLUSH(
        .i_eip(i_eip),
        .tail_ptr(tail_ptr),
        .incr_amt(instr_length),
        .flush_ex(flush_ex), //comes from execute stage
        .stall_rr(stall_rr), //comes from register read stage

        .ld_pr_rr(ld_pr_rr), //to load register read pipeline registers signal
        .instr_valid(pr_de_rr_valid)
    );

    pf_expn EXCEPTION_FLAGS_GEN(
        .pf_expn_bytes(from_f_pf_expn_bytes_out),
        .instr_len(instr_length),
        .exception_flags(exception_flags)
    );


    //Decode logic tells what type of branch is currently being decoded
    wire [1:0] branch_type;
    wire is_branch;
    logic_branch BRANCH_TYPE( //for instruction in decode (if branch)
        .opcode(opcode),
        .modrm(modrm), 
        .v_modrm(modrm_v),
        .ext_opcode(prefix_ext),       
        .is_branch(is_branch), 
        .branch_type(branch_type)
    );

    wire hit;
    wire cur_instr_prediction;
    choose_eip EIP_LOGIC(
        .clk(clk),
        .rst_bar(rst_bar),

        //eip incr logic
        .instr_length(instr_length),

        .ld_pr_rr(ld_pr_rr), //to load register read pipeline registers signal
        .instr_valid(pr_de_rr_valid),
        .cur_instr_prediction(cur_instr_prediction),
        .flush_ex(flush_ex),
        
        .bp_eip_target(bp_eip_target),
        .ex_eip_target(eip_target_ex),
        .branch_type(branch_type),
        .hit(hit),
        
        .i_eip(i_eip),
        .o_eip(o_eip),
        .ld_eip(ld_eip),
        .eip_true(eip_true),
        .take_branch(to_f_take_branch)
    );

    bp BP(
        .clk(clk),
        .rst_bar(rst_bar),
        .is_branch(is_branch),
        .o_eip(o_eip), //used to predict cur instruction in decode
        .br_t_nt_ex_d(br_t_nt_ex_d), //used to update pht for instr in execute stage
        .br_valid_ex_d(br_valid_ex_d), //used to update pht for instr in execute stage
        .ext_pht_idx(pht_idx_ex_d), //used to update pht for instr in execute stage

        .bp_eip_target(bp_eip_target), 
        .hit(hit),

        .cur_instr_prediction(cur_instr_prediction),
        .ghr_out() //used internally only
    );

endmodule

