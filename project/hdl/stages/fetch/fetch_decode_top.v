module fetch_decode_top(
    input wire clk,
    input wire rst_bar,

    // TLB I/O
    output wire [19:0] ITLB_VPN,
    inout wire [2:0]  ITLB_PFN_OUT, 
    input wire ITLB_PAGE_FAULT_OUT,

    // Cache I/o
    inout wire ICACHE_VALID,
    inout wire [127:0] ICACHE_HIT_DATA,
    output wire [11:0] F_PAGE_OFFSET,

    // Pipeline Inputs 
    input wire from_fetch_buffer_write_enable,
    input wire [31:0] from_de_bp_target,
    input wire from_de_eip_redirection,
    input wire [15:0] from_rr_cs,
    input wire [31:0] from_ex_eip_target,
    input wire from_ex_flush,
    input wire from_wb_flush
);

    

endmodule