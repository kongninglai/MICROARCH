module regfile_mmx(
    input clk,
    input rst_n,

    input [2:0] rd_reg0_idx,
    input [2:0] rd_reg1_idx,
    output [63:0] rd_reg0_data,
    output [63:0] rd_reg1_data,

    input [2:0] wr_reg0_idx,
    input [63:0] wr_reg0_data,
    input wr0_en
); 

    regfile_2r1w #(
        .WIDTH(64)
    ) mmx_regs (
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(rd_reg0_idx),
        .rd_reg1_idx(rd_reg1_idx),
        .rd_reg0_data(rd_reg0_data),
        .rd_reg1_data(rd_reg1_data),

        .wr_reg0_idx(wr_reg0_idx),
        .wr_reg0_data(wr_reg0_data),
        .wr0_en(wr0_en)
    );

endmodule