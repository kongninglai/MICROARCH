module fetch_pointer(
    input wire clk,
    input wire rst_bar,

    input wire shft_reg_we, // WE = (~IF_FULL && ICACHE_VALID) or from_de_valid instruction consumed or flush
    input wire from_ex_ld_cs,
    input wire [15:0] from_rr_cs_reg,
    input wire from_de_take_branch,
    input wire from_ex_flush, //misprediction or exception
    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target,

    output wire [31:0] ic_addr
);

    //FEIP Logic
    wire [31:0] feip_reg_out32, feip_reg_out32_prebuf, ld_feip_val, i_eip;

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

    wire shft_reg_we_buf64;
    bufferH64$    bufferH64$_shft_reg_we_buf64(shft_reg_we_buf64, shft_reg_we);

    reg_n #(.WIDTH(32), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) FEIP_REG (
        .clk(clk),
        .rst(rst_bar),
        .en({{28{shft_reg_we_buf64}}, 4'd0}),
        .d(eip_true),
        .q(feip_reg_out32_prebuf)
    );

    bufferH16$    bufferH16$_feip_reg_out32[31:0](feip_reg_out32, feip_reg_out32_prebuf);

    PA_32b CS_FEIP_ADDER(
        .in0({from_rr_cs_reg, 16'h0000}), .in1({feip_reg_out32[31:4], 4'd0}),
	      .s(ic_addr)
    );

endmodule