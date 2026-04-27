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

    // wire shft_reg_we_buf64;
    // bufferH64$    bufferH64$_shft_reg_we_buf64(shft_reg_we_buf64, shft_reg_we);

    wire fetch_ptr_load_en_bar;
    nor3$ nor3$_fetch_ptr_load_en_bar(fetch_ptr_load_en_bar, shft_reg_we, from_ex_flush, from_de_take_branch);

    reg_n_16 #(.WIDTH(16), .USE_EN_BAR(1'b1), .RESET_TO_ONES(1'b0)) FEIP_REG_high (
        .clk(clk),
        .rst(rst_bar),
        .en(fetch_ptr_load_en_bar),
        .d(eip_true[31:16]),
        .q(feip_reg_out32_prebuf[31:16])
    );

    reg_n_16 #(.WIDTH(16), .USE_EN_BAR(1'b1), .RESET_TO_ONES(1'b0)) FEIP_REG_low (
        .clk(clk),
        .rst(rst_bar),
        .en(fetch_ptr_load_en_bar),
        .d(eip_true[15:0]),
        .q(feip_reg_out32_prebuf[15:0])
    );

    bufferH16$    bufferH16$_feip_reg_out32[31:0](feip_reg_out32, feip_reg_out32_prebuf);

    wire cout;
    HA_4b CS_FEIP_ADDER (
      .in0(from_rr_cs_reg[3:0]), .in1(feip_reg_out32[19:16]),
      .s(ic_addr[19:16]),
      .cout(cout)
    );

    wire [11:0] inc_cs;
    big_increment #(
      .WIDTH(12)
    ) big_increment_inc_cs (
      .a(from_rr_cs_reg[15:4]),
      .s(inc_cs)
    );

    wire [3:0] dummy;
    mux2_16$  mux2_16$_ic_addr
    (
      {dummy, ic_addr[31:20]},
      {4'd0, from_rr_cs_reg[15:4]},
      {4'd0, inc_cs},
      cout
    );

    assign ic_addr[15:0] = feip_reg_out32[15:0];

endmodule