module fetch_pointer(
    input wire clk,
    input wire rst_bar,

    input wire from_de_eip_redir,
    input wire from_ex_ld_cs,
    input wire [15:0] from_ex_cs_reg,
    input wire from_ex_flush, //misprediction or exception
    input wire from_wb_flush, //exception
    input wire from_f_cl_ld, //fetch buffer request cache line 

    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target, 

);

    //CS REG Logic
    wire [32:0] cs_reg_out32;
    reg_n #(.WIDTH(32), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) CS_REG (
        .clk(clk),
        .rst(rst_bar),
        .en({16{from_ex_ld_cs}, 16'd0}),
        .d({from_ex_cs_reg, 16'd0),
        .q(cs_reg_out32)
    );

    //FEIP Logic
    wire [31:0] feip_reg_out32, ld_feip_val, i_eip;

    big_increment #(.WIDTH(32)) FEIP_INCR(
        .a(feip_reg_out32), .s(i_eip)
    );

    mux4_32 MUX_CHOOSE_FEIP( //choose eip logic
        .in0(i_eip), 
        .in1(bp_eip_target), 
        .in2(feip_reg_out32), //original eip
        .in3(ex_eip_target), 
        .s0(eip_sel[0]), //Select incremented EIP if we're loading RR pipeline registers
        .s1(eip_sel[1]), //Currently unused, can be used to select other EIP sources in the future
        .out(eip_true) //Output EIP to be used in the rest of the decode logic
    );

    wire ld_feip; //load eip logic
    wire is_redirection;
    or2$ check_redir(is_redirection, from_ex_flush, from_de_eip_redir); // Example signals
    or2$ OR_LD_FEIP(ld_feip, /*shift reg we*/, is_redirection); 

    reg_n #(.WIDTH(32), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) FEIP_REG (
        .clk(clk),
        .rst(rst_bar),
        .en({28{ld_feip}, 4'd0}),
        .d({from_ex_cs_reg, 16'd0),
        .q(feip_reg_out32)
    );

endmodule