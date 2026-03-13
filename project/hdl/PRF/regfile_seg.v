module regfile_seg (  
    input clk,
    input rst_n,

    input [2:0] segrd0_idx,
    input [2:0] segrd1_idx,
    output [15:0] segrd0_data,
    output [15:0] segrd1_data,
    output [19:0] segrd0_limit,
    output [19:0] segrd1_limit,
    output [15:0] cs,

    input [2:0] segwr_idx,
    input [15:0] segwr_data,
    input segwr_en,

    input cs_wr_en,
    input [15:0] cs_wr_data
); 
    wire [15:0] rf_segrd0_data, rf_segrd1_data;
    wire [15:0] cs_q, cs_qb;
    
    assign cs = cs_q;

    wire segrd0_idx0_inv, segrd1_idx0_inv, segrd0_is_cs, segrd1_is_cs;
    inv1$ inv_segrd0_idx0(segrd0_idx0_inv, segrd0_idx[0]);
    inv1$ inv_segrd1_idx0(segrd1_idx0_inv, segrd1_idx[0]);

    nor3$ nor3_segrd0_cs(segrd0_is_cs, segrd0_idx[2], segrd0_idx[1], segrd0_idx0_inv);
    nor3$ nor3_segrd1_cs(segrd1_is_cs, segrd1_idx[2], segrd1_idx[1], segrd1_idx0_inv);

    mux2_16$ mux2_segrd0_data(segrd0_data, rf_segrd0_data, cs_q, segrd0_is_cs);
    mux2_16$ mux2_segrd1_data(segrd1_data, rf_segrd1_data, cs_q, segrd1_is_cs);

    wire [31:0] slim0_32, slim1_32;
    mux8_32 mux8_slim0(slim0_32, 32'h000003ff, 32'h00004fff, 32'h00004000, 32'h000011ff, 32'h000003ff, 32'h000007ff, 32'bx, 32'bx, segrd0_idx[0], segrd0_idx[1], segrd0_idx[2]);
    mux8_32 mux8_slim1(slim1_32, 32'h000003ff, 32'h00004fff, 32'h00004000, 32'h000011ff, 32'h000003ff, 32'h000007ff, 32'bx, 32'bx, segrd1_idx[0], segrd1_idx[1], segrd1_idx[2]);
    
    assign segrd0_limit = slim0_32[19:0];
    assign segrd1_limit = slim1_32[19:0];
    
    reg16e reg16e_cs(clk, cs_wr_data, cs_q, cs_qb, rst_n, 1'b1, cs_wr_en);

    regfile_2r1w #(
        .WIDTH(16)
    ) seg_rf(  
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(segrd0_idx),
        .rd_reg1_idx(segrd1_idx),
        .rd_reg0_data(rf_segrd0_data),
        .rd_reg1_data(rf_segrd1_data),

        .wr_reg0_idx(segwr_idx),
        .wr_reg0_data(segwr_data),
        .wr0_en(segwr_en)
    );

endmodule