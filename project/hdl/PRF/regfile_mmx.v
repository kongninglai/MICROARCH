module regfile_mmx(
    input clk,
    input rst_n,

    input [2:0] mmxrd0_idx,
    input [2:0] mmxrd1_idx,
    output [63:0] mmxrd0_data,
    output [63:0] mmxrd1_data,

    input [2:0] mmxwr_idx,
    input [63:0] mmxwr_data,
    input mmxwr_en
); 

    regfile_2r1w #(
        .WIDTH(64)
    ) mmx_regs (
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(mmxrd0_idx),
        .rd_reg1_idx(mmxrd1_idx),
        .rd_reg0_data(mmxrd0_data),
        .rd_reg1_data(mmxrd1_data),

        .wr_reg0_idx(mmxwr_idx),
        .wr_reg0_data(mmxwr_data),
        .wr0_en(mmxwr_en)
    );

endmodule