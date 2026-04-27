module rr_to_ag #(
    parameter AG_CONTROL_SIGS_WIDTH=69,
    parameter REG_SIZE=628+AG_CONTROL_SIGS_WIDTH
)(
    input clk,
    input rst_n,
    input we,
    input flush_bar, // flush=1 -> write valid = 0; flush=0 -> write valid = valid; valid = ~flush & valid
    input [AG_CONTROL_SIGS_WIDTH-1:0] from_rr_control_sigs,
    input [2:0] from_rr_dstidA,
    input [2:0] from_rr_dstidB,
    input [31:0] from_rr_srcregA,
    input [31:0] from_rr_srcregB,
    input [31:0] from_rr_srcregC,
    input [15:0] from_rr_srcSREG,
    input [63:0] from_rr_MMA,
    input [63:0] from_rr_MMB,
    input [31:0] from_rr_imm,
    input [15:0] from_rr_sreg1,
    input [31:0] from_rr_slim1,
    input [31:0] from_rr_base1,
    input [31:0] from_rr_index1,
    input [31:0] from_rr_disp,
    input [1:0] from_rr_scale_mux,
    input [15:0] from_rr_sreg2,
    input [31:0] from_rr_slim2,
    input [31:0] from_rr_base2,
    input [3:0] from_rr_intex_vec,
    input [15:0] from_rr_cs,
    input [31:0] from_rr_oeip,
    input [31:0] from_rr_ieip,
    input [31:0] from_rr_pred_eip,
    input from_rr_pred_dir,
    input [3:0]  from_rr_pht_idx,
    input [1:0]  from_rr_exception,
    input from_rr_valid,
    output [AG_CONTROL_SIGS_WIDTH-1:0] to_ag_control_sigs,
    output [2:0] to_ag_dstidA,
    output [2:0] to_ag_dstidB,
    output [31:0] to_ag_srcregA,
    output [31:0] to_ag_srcregB,
    output [31:0] to_ag_srcregC,
    output [15:0] to_ag_srcSREG,
    output [63:0] to_ag_MMA,
    output [63:0] to_ag_MMB,
    output [31:0] to_ag_imm,
    output [15:0] to_ag_sreg1,
    output [31:0] to_ag_slim1,
    output [31:0] to_ag_base1,
    output [31:0] to_ag_index1,
    output [31:0] to_ag_disp,
    output [1:0] to_ag_scale_mux,
    output [15:0] to_ag_sreg2,
    output [31:0] to_ag_slim2,
    output [31:0] to_ag_base2,
    output [3:0] to_ag_intex_vec,
    output [15:0] to_ag_cs,
    output [31:0] to_ag_oeip,
    output [31:0] to_ag_ieip,
    output [31:0] to_ag_pred_eip,
    output to_ag_pred_dir,
    output [3:0]  to_ag_pht_idx,
    output [1:0] to_ag_exception,
    output to_ag_valid
);

wire [REG_SIZE-1:0] reg_din, reg_q, reg_qb;
wire valid_with_flush;
and2$ and2_valid(valid_with_flush, flush_bar, from_rr_valid);
assign reg_din = {from_rr_control_sigs, from_rr_dstidA, from_rr_dstidB, from_rr_srcregA, from_rr_srcregB, from_rr_srcregC, from_rr_srcSREG, from_rr_MMA, from_rr_MMB, from_rr_imm, from_rr_sreg1, from_rr_slim1, from_rr_base1, from_rr_index1, from_rr_disp, from_rr_scale_mux, from_rr_sreg2, from_rr_slim2, from_rr_base2, from_rr_intex_vec, from_rr_cs, from_rr_oeip, from_rr_ieip, 
        from_rr_pred_eip, from_rr_pred_dir, from_rr_pht_idx, from_rr_exception, valid_with_flush};
assign {to_ag_control_sigs, to_ag_dstidA, to_ag_dstidB, to_ag_srcregA, to_ag_srcregB, to_ag_srcregC, to_ag_srcSREG, to_ag_MMA, to_ag_MMB, to_ag_imm, to_ag_sreg1, to_ag_slim1, to_ag_base1, to_ag_index1, to_ag_disp, to_ag_scale_mux, to_ag_sreg2, to_ag_slim2, to_ag_base2, to_ag_intex_vec, to_ag_cs, to_ag_oeip, to_ag_ieip, 
    to_ag_pred_eip, to_ag_pred_dir, to_ag_pht_idx, to_ag_exception, to_ag_valid} = reg_q;

wire flush, we_with_flush_bar, we_with_flush;
inv1$ inv_flush_bar(flush, flush_bar);
nor2$ nor2_we_with_flush_bar(we_with_flush_bar, flush, we);
bufferHInv16$ bufferHInv16$_we_with_flush(we_with_flush, we_with_flush_bar);
reg_rr_to_ag #(.REG_SIZE(REG_SIZE)) reg_inst(clk, reg_din, reg_q, reg_qb, rst_n, 1'b1, we_with_flush);

endmodule


    


    