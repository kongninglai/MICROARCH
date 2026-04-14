module ex_eflags(
    input clk,
    input rst_n,

    input [31:0] alu_eflags,
    input [31:0] shf_eflags,
    input [31:0] bsf_eflags,
    input [31:0] aaa_eflags,
    input [31:0] cmp_eflags,
    input [31:0] alu_eflags_mask,
    input [31:0] shf_eflags_mask,
    input [31:0] bsf_eflags_mask,
    input [31:0] aaa_eflags_mask,
    input [31:0] cmp_eflags_mask,
    input [31:0] LR,
    input [2:0]  sig_eflags_mux,
    input        ldEFLAGS,

    output [31:0] eflags
); 
    wire [31:0] eflags_q, eflags_qbar, eflags_din, eflags_value, eflags_mask;
    // DF: bit 10, STD = 0100 0000 0000 = 0x400
    mux8_32 mux_eflags_value(eflags_value, alu_eflags, shf_eflags, bsf_eflags, aaa_eflags, cmp_eflags, 32'h0, 32'h400, LR, sig_eflags_mux[0], sig_eflags_mux[1], sig_eflags_mux[2]);
    mux8_32 mux_eflags_mux(eflags_mask, alu_eflags_mask, shf_eflags_mask, bsf_eflags_mask, aaa_eflags_mask, cmp_eflags_mask, 32'h400, 32'h400, 32'hffff_ffff, sig_eflags_mux[0], sig_eflags_mux[1], sig_eflags_mux[2]);
    
    mux2$ mux_eflags_din[31:0](eflags_din, eflags_q, eflags_value, eflags_mask);
    reg32e$ reg32e$_eflags(clk, eflags_din, eflags_q, eflags_qbar, rst_n, 1'b1, ldEFLAGS);

    assign eflags = eflags_q;
endmodule