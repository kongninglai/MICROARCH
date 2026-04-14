module temp_exception_regs(
    input clk,
    input rst_n,
    
    input [15:0] from_wb_temp_cs,
    input [31:0] from_wb_temp_eip,
    input [1:0]  from_wb_temp_exception,
    input        from_wb_flush,

    output [15:0] to_ex_tempCS,
    output [31:0] to_ex_tempEIP,
    output [1:0]  to_rr_temp_exception
);  
    wire [31:0] tempEIP_qb;
    wire [15:0] tempCS_qb;
    reg16e reg_temp_cs(clk, from_wb_temp_cs, to_ex_tempCS, tempCS_qb, rst_n, 1'b1, from_wb_flush);
    reg32e$ reg32e$_inst(clk, from_wb_temp_eip, to_ex_tempEIP, tempEIP_qb, rst_n, 1'b1, from_wb_flush);
    
    reg_n #(
        .WIDTH(2),
        .USE_EN_BAR(0)
    ) reg_n_temp_exception (
        .clk(clk), .rst(rst_n),
        .en({from_wb_flush, from_wb_flush}), .d(from_wb_temp_exception),
        .q(to_rr_temp_exception)
    );
endmodule