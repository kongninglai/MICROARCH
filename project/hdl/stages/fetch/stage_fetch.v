module stage_fetch(
    input wire clk,
    input wire rst_bar, 

    input wire from_de_valid, //TODO ADD TO TB
    input wire from_de_take_branch,
    input wire from_ex_flush,
    input wire from_ex_ld_cs,
    input wire [15:0] from_ex_cs_reg,
    input wire from_f_cl_ld,

    input wire [31:0] from_ex_eip_target,
    input wire [31:0] from_de_eip_target,

    //cache inputs/outputs
    input wire ICACHE_VALID,
    inout wire [127:0] ICACHE_HIT_DATA,
    inout wire [2:0] ITLB_PFN_OUT,
    inout wire ITLB_PAGE_FAULT_OUT,
    inout wire [11:0] F_PAGE_OFFSET,
    input wire shft_reg_we,

    output wire [31:0] ic_addr
);

//Fetch Pointer Logic
fetch_pointer FETCH_POINTER(
    .clk(clk), .rst_bar(rst_bar),
    .shft_reg_we(shft_reg_we),
    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_cs_reg(from_ex_cs_reg),
    .from_de_take_branch(from_de_take_branch),
    .from_ex_flush(from_ex_flush), //misprediction or exception
    .from_f_cl_ld(from_f_cl_ld), //fetch buffer request cache line 

    .bp_eip_target(from_de_eip_target),
    .ex_eip_target(from_ex_eip_target),

    .ic_addr(ic_addr)
);

    assign F_PAGE_OFFSET = 12'd0;

endmodule