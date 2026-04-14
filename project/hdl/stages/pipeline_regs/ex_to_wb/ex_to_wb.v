module ex_to_wb(
    input clk,
    input rst_n,
    input we,
    input flush_bar,

    input [11:0]        from_ex_control_sigs,
    input [2:0]         from_ex_dstidA, 
    input [2:0]         from_ex_dstidB,
    input [31:0]        from_ex_gp_wr_data_1,
    input [31:0]        from_ex_gp_wr_data_2,
    input [15:0]        from_ex_seg_wr_data,
    input [63:0]        from_ex_mmx_wr_data,
    input [63:0]        from_ex_store_data,
    input               from_ex_store_is_io_line_0,
    input [10:0]        from_ex_store_addr_line_0,
    input [15:0]        from_ex_store_mask_line_0,
    input               from_ex_store_queue_alloc_line_0,
    input [10:0]        from_ex_store_addr_line_1,
    input [15:0]        from_ex_store_mask_line_1,
    input               from_ex_store_queue_alloc_line_1,
    input [4:0]         from_ex_store_data_shf_amt,
    input [15:0]        from_ex_cs,
    input [31:0]        from_ex_oeip,
    input [31:0]        from_ex_ieip,
    input               from_ex_valid,
    input [1:0]         from_ex_exception,
 
    output [11:0]       to_wb_control_sigs,
    output [2:0]        to_wb_dstidA, 
    output [2:0]        to_wb_dstidB,
    output [31:0]       to_wb_gp_wr_data_1,
    output [31:0]       to_wb_gp_wr_data_2,
    output [15:0]       to_wb_seg_wr_data,
    output [63:0]       to_wb_mmx_wr_data,
    output [63:0]       to_wb_store_data,
    output              to_wb_store_is_io_line_0,
    output [10:0]       to_wb_store_addr_line_0,
    output [15:0]       to_wb_store_mask_line_0,
    output              to_wb_store_queue_alloc_line_0,
    output [10:0]       to_wb_store_addr_line_1,
    output [15:0]       to_wb_store_mask_line_1,
    output              to_wb_store_queue_alloc_line_1,
    output [4:0]        to_wb_store_data_shf_amt,
    output [15:0]       to_wb_cs,
    output [31:0]       to_wb_oeip,
    output [31:0]       to_wb_ieip,
    output              to_wb_valid,
    output [1:0]        to_wb_exception
);

wire [370:0] reg_din, reg_q, reg_qb;
wire valid_with_flush;
and2$ and2_valid(valid_with_flush, flush_bar, from_ex_valid);

assign reg_din = {from_ex_control_sigs, from_ex_dstidA, from_ex_dstidB, from_ex_gp_wr_data_1, from_ex_gp_wr_data_2, from_ex_seg_wr_data, from_ex_mmx_wr_data, from_ex_store_data, from_ex_store_is_io_line_0, from_ex_store_addr_line_0, from_ex_store_mask_line_0, from_ex_store_queue_alloc_line_0, from_ex_store_addr_line_1, from_ex_store_mask_line_1, from_ex_store_queue_alloc_line_1, from_ex_store_data_shf_amt, from_ex_cs, from_ex_oeip, from_ex_ieip, valid_with_flush, from_ex_exception};
assign {to_wb_control_sigs, to_wb_dstidA, to_wb_dstidB, to_wb_gp_wr_data_1, to_wb_gp_wr_data_2, to_wb_seg_wr_data, to_wb_mmx_wr_data, to_wb_store_data, to_wb_store_is_io_line_0, to_wb_store_addr_line_0, to_wb_store_mask_line_0, to_wb_store_queue_alloc_line_0, to_wb_store_addr_line_1, to_wb_store_mask_line_1, to_wb_store_queue_alloc_line_1, to_wb_store_data_shf_amt, to_wb_cs, to_wb_oeip, to_wb_ieip, to_wb_valid, to_wb_exception} = reg_q;

wire flush, we_with_flush;
inv1$ inv_flush_bar(flush, flush_bar);
or2$ or2_we_with_flush(we_with_flush, flush, we);
reg_ex_to_wb reg340_ex_to_wb(clk, reg_din, reg_q, reg_qb, rst_n, 1'b1, we_with_flush);

endmodule