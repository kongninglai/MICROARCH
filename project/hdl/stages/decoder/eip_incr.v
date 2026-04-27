module eip_incr(
    input wire [3:0] incr_amt,
    input wire [31:0] eip,
    output wire [31:0] incr_eip
);
    wire [31:0] mux_in [15:0];
    genvar i;
    generate
        for (i = 0; i < 16; i= i+ 1) begin: gen_eip_adders
            PA_32b eip_adders(
                .in0(eip), .in1(i),
                .s(mux_in[i])
            );
        end
    endgenerate

    mux16_32 CHOOSE_INCR(
        .out(incr_eip),
        .in0(mux_in[0]), .in1(mux_in[1]), .in2(mux_in[2]), .in3(mux_in[3]), .in4(mux_in[4]), .in5(mux_in[5]), .in6(mux_in[6]), .in7(mux_in[7]),
        .in8(mux_in[8]), .in9(mux_in[9]), .in10(mux_in[10]), .in11(mux_in[11]), .in12(mux_in[12]), .in13(mux_in[13]), .in14(mux_in[14]), .in15(mux_in[15]),
        .s0(incr_amt[0]), .s1(incr_amt[1]), .s2(incr_amt[2]), .s3(incr_amt[3]) 
    );

endmodule

module eip_incr_br(
    input wire [2:0] incr_amt,
    input wire [31:0] eip,
    output wire [31:0] incr_eip
);
    wire [31:0] mux_in [7:0];
    genvar i;
    generate
        for (i = 2; i < 8; i= i+ 1) begin: gen_eip_adders
            PA_32b eip_adders(
                .in0(eip), .in1(i),
                .s(mux_in[i])
            );
        end
    endgenerate

    mux8_32 CHOOSE_INCR
    (
        .out(incr_eip),
        .in0(), .in1(), .in2(mux_in[2]), .in3(mux_in[3]), .in4(mux_in[4]), .in5(mux_in[5]), .in6(mux_in[6]), .in7(mux_in[7]),
        .s0(incr_amt[0]), .s1(incr_amt[1]), .s2(incr_amt[2])
    );

endmodule