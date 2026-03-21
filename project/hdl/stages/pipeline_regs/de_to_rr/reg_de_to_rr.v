module reg_de_to_rr(
    input wire CLK,
    input wire CLR,
    input wire en,
    input wire [218:0] Din,
    output wire [218:0] Q
);

    reg_n #(.WIDTH(219), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) reg_inst (
        .clk(CLK),
        .rst(CLR),
        .en({219{en}}),
        .d(Din),
        .q(Q)
    );

endmodule