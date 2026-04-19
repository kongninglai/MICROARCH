module reg_f_to_de(
    input wire CLK,
    input wire CLR,
    input wire en,
    input wire [219:0] Din,
    output wire [219:0] Q
);

    reg_n #(.WIDTH(220), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) reg_inst (
        .clk(CLK),
        .rst(CLR),
        .en({220{en}}),
        .d(Din),
        .q(Q)
    );

endmodule