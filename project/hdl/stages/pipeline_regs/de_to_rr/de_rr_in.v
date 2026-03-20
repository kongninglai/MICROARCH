/*

module de_rr_pipelinereg(
    input wire [4:0] prefix_in,

    output wire [4:0] prefix_out
);

    wire reg_in;
    assign reg_in = {prefix_in, ext_opcode, ...};

    //reg instantiation
    reg_n DE_RR_REG(
        .clk(clk),
        .rst(rst),
        .en(en),
        .in(prefix_in),
        .out(prefix_out)
    );

    assign prefix_out = reg[4:0]


endmodule


*/