module pending_int_bh(
    input clk,
    input rst_n,
    input set_int,
    input clear_int,

    output pending_int
); 
    reg reg_int;
    assign pending_int = reg_int;
    always @(posedge clk) begin
        if (!rst_n) begin
            reg_int <= 1'b0;
        end else begin
            if (set_int) begin
                reg_int <= 1'b1;
            end else if (clear_int) begin
                reg_int <= 1'b0;
            end
        end
    end
endmodule