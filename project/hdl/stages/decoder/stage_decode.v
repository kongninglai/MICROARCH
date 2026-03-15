module stage_decode(
    input wire [127:0] cache_line,
    input wire [31:0] o_eip, 
    input wire [3:0] tail_ptr,
    input wire [19:0] cs_limit_reg,
    input wire mispredict_src_ex, //comes from execute stage
    input wire v_excptn_src_wb, //comes from writeback stage
    input wire v_ld_cs_src_ex, //comes from execute stage
    input wire stall_ex, //comes from execute stage
    input wire stall_rr, //comes from register read stage
    input wire stall_mem, //comes from memory stage
    input wire stall_wb, //comes from writeback stage

    output wire exptn_prot,
    output wire [31:0] i_eip,
    output wire pr_de_rr_valid //to rr stage pipeline regs are valid

);

    block_decoder DECODER(
        input wire [127:0] cache_line,
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



    wire ld_pr_rr; //to load register read pipeline registers signal
    logic_stall_flush(
            .i_eip(i_eip),
            .cs_limit(cs_limit_reg),
            .tail_ptr(tail_ptr),
            .incr_amt(instr_length),
            .mispredict_src_ex(mispredict_src_ex), //comes from execute stage
            .v_excptn_src_wb(v_excptn_src_wb), //comes from writeback stage
            .v_ld_cs_src_ex(v_ld_cs_src_ex), //comes from execute stage
            .stall_ex(stall_ex), //comes from execute stage
            .stall_rr(stall_rr), //comes from register read stage
            .stall_mem(stall_mem), //comes from memory stage
            .stall_wb(stall_wb) //comes from writeback stage

            .ld_pr_rr(ld_pr_rr), //to load register read pipeline registers signal
            .instr_valid(pr_de_rr_valid),
            .exptn_prot(exptn_prot)
    );

endmodule