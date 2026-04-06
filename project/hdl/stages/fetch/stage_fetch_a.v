module stage_fetch_a (
    input wire clk,
    input wire rst_bar,

    // TLB I/O
    output wire [19:0] ITLB_VPN,

    // Cache I/o
    output wire [11:0] F_PAGE_OFFSET,

    // Pipeline Inputs 
    input wire shft_reg_we, //from fetch buffer signal generated
    input wire [31:0] from_de_bp_target,
    input wire from_de_take_branch,
    input wire [15:0] from_rr_cs,
    input wire [31:0] from_ex_eip_target,
    input wire from_ex_flush,
    input wire from_ex_ld_cs,
    output wire [31:0] ic_addr
);

    // Fetch Pointer Logic
    fetch_pointer FETCH_POINTER(
        .clk(clk), 
        .rst_bar(rst_bar), 
        .shft_reg_we(shft_reg_we), 
        .from_ex_ld_cs(from_ex_ld_cs), 
        .from_rr_cs_reg(from_rr_cs),
        .from_de_take_branch(from_de_take_branch),
        .from_ex_flush(from_ex_flush), 
        .bp_eip_target(from_de_bp_target),
        .ex_eip_target(from_ex_eip_target),

        .ic_addr(ic_addr)
    );


    // 32-bit address = 20-bit VPN + 12-bit Page Offset 
    assign ITLB_VPN = ic_addr[31:12]; 
    assign F_PAGE_OFFSET = ic_addr[11:0];  

endmodule