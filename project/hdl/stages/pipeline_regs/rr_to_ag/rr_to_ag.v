module rr_to_ag(
    input clk,
    input rst_n,
    input we,
    input flush_bar,
    input [66:0] from_rr_control_sigs,
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
    input [1:0]  from_rr_exception,
    input from_rr_valid,
    output [66:0] to_ag_control_sigs,
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
    output [1:0] to_ag_exception,
    output to_ag_valid
);

wire [689:0] reg_din, reg_q, reg_qb;
assign reg_din = {from_rr_control_sigs, from_rr_dstidA, from_rr_dstidB, from_rr_srcregA, from_rr_srcregB, from_rr_srcregC, from_rr_srcSREG, from_rr_MMA, from_rr_MMB, from_rr_imm, from_rr_sreg1, from_rr_slim1, from_rr_base1, from_rr_index1, from_rr_disp, from_rr_scale_mux, from_rr_sreg2, from_rr_slim2, from_rr_base2, from_rr_intex_vec, from_rr_cs, from_rr_oeip, from_rr_ieip, 
                    from_rr_pred_eip, from_rr_exception, from_rr_valid};
assign {to_ag_control_sigs, to_ag_dstidA, to_ag_dstidB, to_ag_srcregA, to_ag_srcregB, to_ag_srcregC, to_ag_srcSREG, to_ag_MMA, to_ag_MMB, to_ag_imm, to_ag_sreg1, to_ag_slim1, to_ag_base1, to_ag_index1, to_ag_disp, to_ag_scale_mux, to_ag_sreg2, to_ag_slim2, to_ag_base2, to_ag_intex_vec, to_ag_cs, to_ag_oeip, to_ag_ieip, 
            to_ag_pred_eip, to_ag_exception, to_ag_valid} = reg_q;

wire rst_or_flush;
and2$ and2_rst_or_flush(rst_or_flush, flush_bar, rst_n);
reg_rr_to_ag reg_inst(clk, reg_din, reg_q, reg_qb, rst_or_flush, 1'b1, we);

endmodule


    


    