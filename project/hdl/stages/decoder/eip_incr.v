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

    mux16_32 (
        .Y(incr_eip),
        .IN0(mux_in[0]), .IN1(mux_in[1]), .IN2(mux_in[2]), .IN3(mux_in[3]), .IN4(mux_in[4]), .IN5(mux_in[5]), .IN6(mux_in[6]), .IN7(mux_in[7]),
        .IN8(mux_in[8]), .IN9(mux_in[9]), .IN10(mux_in[10]), .IN11(mux_in[11]), .IN12(mux_in[12]), .IN13(mux_in[13]), .IN14(mux_in[14]), .IN15(mux_in[15]),
        .S0(incr_amt[0]), .S1(incr_amt[1]), .S2(incr_amt[2]), .S3(incr_amt[3]) 
    );

endmodule