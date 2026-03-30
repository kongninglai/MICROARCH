module ex_inc_bh(
    input [31:0] inc_in,
    input [1:0]  ds,
    input        eflags_df,
    output [31:0] inc_out
); 
    reg [31:0] inc_out_reg;
    always @(*) begin 
        case (ds) 
            2'b00: inc_out_reg = eflags_df ? (inc_in - 32'h1) : (inc_in + 32'h1);
            2'b01: inc_out_reg = eflags_df ? (inc_in - 32'h2) : (inc_in + 32'h2);
            2'b10: inc_out_reg = eflags_df ? (inc_in - 32'h4) : (inc_in + 32'h4);
            2'b11: inc_out_reg = 32'bx;
        endcase
    end

    assign inc_out = inc_out_reg;
endmodule