module temp_exception_regs_bh(
    input clk,
    input rst_n,
    
    input [15:0] from_wb_temp_cs,
    input [31:0] from_wb_temp_eip,
    input [1:0]  from_wb_temp_exception,
    input        from_wb_flush,

    output [15:0] to_ex_tempCS,
    output [31:0] to_ex_tempEIP
);  
    reg [15:0] temp_cs;
    reg [31:0] temp_eip;
    reg [1:0] temp_exception;

    assign to_ex_tempCS = temp_cs;
    assign to_ex_tempEIP = temp_eip;
    
    always @(posedge clk) begin 
        if (~rst_n) begin
            temp_cs <= 16'b0;
            temp_eip <= 32'b0;
            temp_exception <= 2'b0;
        end else begin
            if (from_wb_flush) begin 
                temp_cs <= from_wb_temp_cs;
                temp_eip <= from_wb_temp_eip;
                temp_exception <= from_wb_temp_exception;
            end
        end
    end

endmodule