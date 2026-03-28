module fetch_pointer(
    input wire clk,
    input wire rst_bar,

    input wire shft_reg_we,
    input wire from_ex_ld_cs,
    input wire [15:0] from_ex_cs_reg,
    input wire from_de_take_branch,
    input wire from_ex_flush, //misprediction or exception
    input wire from_f_cl_ld, //fetch buffer request cache line 

    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target,

    output wire [31:0] ic_addr
);

    //CS REG Logic
    wire [31:0] cs_reg_out32;
    reg_n #(.WIDTH(32), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) CS_REG (
        .clk(clk),
        .rst(rst_bar),
        .en({{16{from_ex_ld_cs}}, 16'd0}),
        .d({from_ex_cs_reg, 16'd0}),
        .q(cs_reg_out32)
    );

    //FEIP Logic
    wire [31:0] feip_reg_out32, ld_feip_val, i_eip;

    big_increment #(.WIDTH(32)) FEIP_INCR(
        .a({4'd0, feip_reg_out32[31:4]}), .s(i_eip)
    );

    wire [31:0] eip_true;
    mux4_32 MUX_CHOOSE_FEIP( //choose eip logic
        .in0({{i_eip[27:0]}, 4'd0}), 
        .in1(bp_eip_target), 
        .in2(ex_eip_target), 
        .in3(ex_eip_target), 
        .s0(from_de_take_branch), 
        .s1(from_ex_flush), 
        .out(eip_true) 
    );

    wire ld_feip; //load eip logic
    or3$ OR_LD_FEIP(ld_feip, shft_reg_we, from_ex_flush, from_de_take_branch); //ld eip if there is space in fetch buffer, or is some type of redirection

    reg_n #(.WIDTH(32), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) FEIP_REG (
        .clk(clk),
        .rst(rst_bar),
        .en({{28{ld_feip}}, 4'd0}),
        .d({eip_true[31:4], 4'd0}),
        .q(feip_reg_out32)
    );

    PA_32b CS_FEIP_ADDER(
        .in0(cs_reg_out32), .in1(feip_reg_out32),
	    .s(ic_addr)
    );

endmodule