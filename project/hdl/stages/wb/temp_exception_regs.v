module temp_exception_regs(
    input clk,
    input rst_n,
    
    input [15:0] from_wb_temp_cs,
    input [31:0] from_wb_temp_eip,
    input [1:0]  from_wb_temp_exception,
    input        from_wb_flush,

    output [15:0] to_ex_tempCS,
    output [31:0] to_ex_tempEIP
);  
    wire [31:0] tempEIP_qb;
    wire [15:0] tempCS_qb;
    reg16e reg_temp_cs(clk, from_wb_temp_cs, to_ex_tempCS, tempCS_qb, rst_n, 1'b1, from_wb_flush);
    reg32e$ reg32e$_inst(clk, from_wb_temp_eip, to_ex_tempEIP, tempEIP_qb, rst_n, 1'b1, from_wb_flush);
endmodule