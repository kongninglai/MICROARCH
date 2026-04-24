    module de_to_rr_no_instr_q(
        input wire clk,
        input wire rst,
        input wire from_de_ld_pr,

        input wire [1:0] from_f_exception_flags,

        input wire [31:0] from_de_i_eip,
        input wire [31:0] from_de_o_eip,
        input wire [31:0] from_de_bp_target,
        input wire from_de_pr_valid, 

        //decoder output
        input wire from_de_prefix_rep,
        input wire from_de_prefix_op_size, 
        input wire [2:0] from_de_prefix_seg_ov_id,
        input wire from_de_prefix_seg,
        input wire from_de_prefix_ext,
        input wire [7:0] from_de_opcode,
        input wire [7:0] from_de_modrm,
        input wire [7:0] from_de_sib, 
        input wire [1:0] from_de_disp_size_mux,
        input wire [31:0] from_de_disp, 
        input wire [2:0] from_de_imm_size,
        input wire [47:0] from_de_imm,
        input wire [1:0] from_de_addressing_mode,
        input wire [3:0] from_de_instr_length,
        input wire [95:0] from_de_ucode_sigs,

        output wire [1:0] to_rr_exception_flags,
        output wire [31:0] to_rr_i_eip,
        output wire [31:0] to_rr_o_eip,
        output wire [31:0] to_rr_bp_target,
        output wire to_rr_pr_valid, 

        //decoder output
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
        output wire [95:0] to_rr_ucode_sigs
    ); 

        wire [6:0] prefixes;
        assign prefixes = {from_de_prefix_seg, from_de_prefix_rep, from_de_prefix_op_size, from_de_prefix_seg_ov_id, from_de_prefix_ext};

        wire [316:0] reg_in;
        assign reg_in = {from_f_exception_flags, from_de_i_eip, from_de_o_eip, from_de_bp_target, from_de_pr_valid, 
                        prefixes, from_de_opcode, from_de_modrm, from_de_sib, from_de_disp_size_mux, from_de_disp, 
                        from_de_imm_size, from_de_imm, from_de_addressing_mode, from_de_instr_length, from_de_ucode_sigs};

        wire [316:0] reg_out;
        reg_de_to_rr #(.WIDTH(317)) PR_DR_TO_RR(.CLK(clk), .CLR(rst), .en(from_de_ld_pr), .Din(reg_in), .Q(reg_out));
        assign {to_rr_exception_flags, to_rr_i_eip, to_rr_o_eip, to_rr_bp_target, to_rr_pr_valid, 
                to_rr_prefixes, to_rr_opcode, to_rr_modrm, to_rr_sib, to_rr_disp_size_mux, to_rr_disp, 
                to_rr_imm_size, to_rr_imm, to_rr_addressing_mode, to_rr_instr_length, to_rr_ucode_sigs} = reg_out;

    endmodule