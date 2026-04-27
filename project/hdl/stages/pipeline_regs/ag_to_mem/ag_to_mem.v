module ag_to_mem #(
    parameter MEM_CONTROL_SIGS_WIDTH=61,
    parameter REG_SIZE=702+MEM_CONTROL_SIGS_WIDTH
)(
    input clk,
    input rst_n,
    input we,
    input flush_bar,
    input [MEM_CONTROL_SIGS_WIDTH-1:0]     from_ag_control_sigs,
    input [2:0]      from_ag_dstidA,
    input [2:0]      from_ag_dstidB,
    input [31:0]     from_ag_srcregA,
    input [31:0]     from_ag_srcregB,
    input [31:0]     from_ag_srcregC,
    input [15:0]     from_ag_srcSREG,
    input [63:0]     from_ag_MMA,
    input [63:0]     from_ag_MMB,

    input [15:0]     from_ag_target_cs,
    input [31:0]     from_ag_ld_addr,
    input [31:0]     from_ag_ld_offset,
    input [31:0]     from_ag_ld_slim,
    input [31:0]     from_ag_st_addr,
    input [31:0]     from_ag_st_offset,
    input [31:0]     from_ag_st_slim,
    input [31:0]     from_ag_inc_esp,
    input [31:0]     from_ag_dec_esp,
    input [31:0]     from_ag_imm,
    input [31:0]     from_ag_rel_eip,
 
    input [15:0]     from_ag_cs,
    input [31:0]     from_ag_oeip,
    input [31:0]     from_ag_ieip,
    input [31:0]     from_ag_pred_eip,
    input            from_ag_pred_dir,
    input [3:0]      from_ag_pht_idx,
    input [1:0]      from_ag_exception,
    input            from_ag_valid,
    
    output [MEM_CONTROL_SIGS_WIDTH-1:0]     to_mem_control_sigs,
    output [2:0]      to_mem_dstidA,
    output [2:0]      to_mem_dstidB,
    output [31:0]     to_mem_srcregA,
    output [31:0]     to_mem_srcregB,
    output [31:0]     to_mem_srcregC,
    output [15:0]     to_mem_srcSREG,
    output [63:0]     to_mem_MMA,
    output [63:0]     to_mem_MMB,

    output [15:0]     to_mem_target_cs,
    output [31:0]     to_mem_ld_addr,
    output [31:0]     to_mem_ld_offset,
    output [31:0]     to_mem_ld_slim,
    output [31:0]     to_mem_st_addr,
    output [31:0]     to_mem_st_offset,
    output [31:0]     to_mem_st_slim,
    output [31:0]     to_mem_inc_esp,
    output [31:0]     to_mem_dec_esp,
    output [31:0]     to_mem_imm,
    output [31:0]     to_mem_rel_eip,
 
    output [15:0]     to_mem_cs,
    output [31:0]     to_mem_oeip,
    output [31:0]     to_mem_ieip,
    output [31:0]     to_mem_pred_eip,
    output            to_mem_pred_dir,
    output [3:0]      to_mem_pht_idx,
    output [1:0]      to_mem_exception,
    output            to_mem_valid
);

    wire [REG_SIZE-1:0] reg_din, reg_q, reg_qb;
    wire valid_with_flush;
    and2$ and2_valid(valid_with_flush, flush_bar, from_ag_valid);
    assign reg_din = {from_ag_control_sigs, from_ag_dstidA, from_ag_dstidB, from_ag_srcregA, from_ag_srcregB, from_ag_srcregC, from_ag_srcSREG, from_ag_MMA, from_ag_MMB, from_ag_target_cs, from_ag_ld_addr, from_ag_ld_offset, from_ag_ld_slim, from_ag_st_addr, from_ag_st_offset, from_ag_st_slim, from_ag_inc_esp, from_ag_dec_esp, from_ag_imm, from_ag_rel_eip, from_ag_cs, from_ag_oeip, from_ag_ieip, from_ag_pred_eip, from_ag_pred_dir, from_ag_pht_idx, from_ag_exception, valid_with_flush};
    assign           { to_mem_control_sigs,  to_mem_dstidA,  to_mem_dstidB,  to_mem_srcregA,  to_mem_srcregB,  to_mem_srcregC,  to_mem_srcSREG,  to_mem_MMA,  to_mem_MMB,  to_mem_target_cs,  to_mem_ld_addr,  to_mem_ld_offset,  to_mem_ld_slim,  to_mem_st_addr,  to_mem_st_offset,  to_mem_st_slim,  to_mem_inc_esp,  to_mem_dec_esp,  to_mem_imm,  to_mem_rel_eip,  to_mem_cs,  to_mem_oeip,  to_mem_ieip,  to_mem_pred_eip,  to_mem_pred_dir,  to_mem_pht_idx,  to_mem_exception,  to_mem_valid} = reg_q;
    
    wire flush, we_with_flush_bar, we_with_flush;
    inv1$ inv_flush_bar(flush, flush_bar);
    nor2$ nor2_we_with_flush_bar(we_with_flush_bar, flush, we);
    bufferHInv16$ bufferHInv16$_we_with_flush(we_with_flush, we_with_flush_bar);
    reg_ag_to_mem #(.REG_SIZE(REG_SIZE)) reg_ag_to_mem(clk, reg_din, reg_q, reg_qb, rst_n, 1'b1, we_with_flush);

endmodule