    module de_to_rr(
        input wire clk,
        input wire rst,
        input wire from_rr_stall,
        input wire from_ex_flush,
        input wire from_wb_flush,

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

        output wire iq_full,
        output wire to_rr_valid
); 

        localparam ENTRY_BIT_WIDTH = 221;
        localparam VALID_BIT       = 122;
        localparam COUNT_WIDTH     = 3;

        wire [6:0] prefixes;
        assign prefixes = {from_de_prefix_seg, from_de_prefix_rep, from_de_prefix_op_size, from_de_prefix_seg_ov_id, from_de_prefix_ext};

        wire [ENTRY_BIT_WIDTH-1:0] reg_in;
        assign reg_in = {from_f_exception_flags, from_de_i_eip, from_de_o_eip, from_de_bp_target, from_de_pr_valid, 
                        prefixes, from_de_opcode, from_de_modrm, from_de_sib, from_de_disp_size_mux, from_de_disp, 
                        from_de_imm_size, from_de_imm, from_de_addressing_mode, from_de_instr_length};

        wire [ENTRY_BIT_WIDTH-1:0] reg_out;
        wire                       head_valid;
        wire                       iq_empty;
        wire [COUNT_WIDTH-1:0]     entry_count;

        /* Write when decode produces a valid instruction AND queue is not full */
        wire iq_wr, iq_wr_bar;
        wire iq_full_bar;
        inv1$ inv1$_iq_full_bar(iq_full_bar, iq_full);
        nand2$ nand2$_iq_wr_bar(iq_wr_bar, from_de_pr_valid, iq_full_bar);
        bufferHInv16$ bufferHInv16$_iq_wr(iq_wr, iq_wr_bar);

        /* Read when RR is not stalling and iq_empty === 1'b0 */
        wire from_rr_stall_bar, iq_rd;
        nor2$ nor2$_iq_rd(iq_rd, from_rr_stall, iq_empty);

        /* Flush on either pipeline flush */
        wire flush_bar, flush;
        nor2$ nor2$_flush_bar(flush_bar, from_ex_flush, from_wb_flush);
        bufferHInv16$ bufferHInv16$_flush(flush, flush_bar);

        iq_de_to_rr #(
          .ENTRY_BIT_WIDTH(ENTRY_BIT_WIDTH),
          .VALID_BIT(VALID_BIT)
        ) IQ_DE_TO_RR (
          .clk(clk),
          .rst_n(rst),
          .wr(iq_wr),
          .rd(iq_rd),
          .flush(flush),
          .data_in(reg_in),
          .empty(iq_empty),
          .full(iq_full),
          .entry_count(entry_count),
          .data_out(reg_out),
          .head_valid(head_valid)
        );

        /* to_rr_valid: queue is non-empty AND head entry has valid bit set */
        wire entry_count_nonzero;
        or3$ or3$_entry_count_nonzero(entry_count_nonzero, entry_count[0], entry_count[1], entry_count[2]);
        and2$ and2$_to_rr_valid(to_rr_valid, entry_count_nonzero, head_valid);

        assign {to_rr_exception_flags, to_rr_i_eip, to_rr_o_eip, to_rr_bp_target, to_rr_pr_valid, 
                to_rr_prefixes, to_rr_opcode, to_rr_modrm, to_rr_sib, to_rr_disp_size_mux, to_rr_disp, 
                to_rr_imm_size, to_rr_imm, to_rr_addressing_mode, to_rr_instr_length} = reg_out;

    endmodule