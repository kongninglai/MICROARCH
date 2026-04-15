module reg_de_to_rr #(
  parameter WIDTH=221
) (
    input wire CLK,
    input wire CLR,
    input wire en,
    input wire [WIDTH-1:0] Din,
    output wire [WIDTH-1:0] Q
);

    reg_n #(.WIDTH(WIDTH), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) reg_inst (
        .clk(CLK),
        .rst(CLR),
        .en({WIDTH{en}}),
        .d(Din),
        .q(Q)
    );

endmodule