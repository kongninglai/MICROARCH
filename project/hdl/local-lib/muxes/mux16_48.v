/*
This module is a 16 to 1 multiplexer for 48-bit inputs. 
Constructed using three parallel 16-bit 16-to-1 multiplexers.

Delay: 1.1ns total
*/

module mux16_48 (
    output wire [47:0] Y,
    input  wire [47:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire [47:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15,
    input  wire        S0, S1, S2, S3 
);

    // Layer 1: 
    mux16_16 slice_low ( //lower 16 bits [15:0]
        .Y(Y[15:0]),
        .IN0(IN0[15:0]),   .IN1(IN1[15:0]),   .IN2(IN2[15:0]),   .IN3(IN3[15:0]),
        .IN4(IN4[15:0]),   .IN5(IN5[15:0]),   .IN6(IN6[15:0]),   .IN7(IN7[15:0]),
        .IN8(IN8[15:0]),   .IN9(IN9[15:0]),   .IN10(IN10[15:0]), .IN11(IN11[15:0]),
        .IN12(IN12[15:0]), .IN13(IN13[15:0]), .IN14(IN14[15:0]), .IN15(IN15[15:0]),
        .S0(S0), .S1(S1), .S2(S2), .S3(S3)
    );

    mux16_16 slice_mid ( //Middle 16 bits [31:16]
        .Y(Y[31:16]),
        .IN0(IN0[31:16]),   .IN1(IN1[31:16]),   .IN2(IN2[31:16]),   .IN3(IN3[31:16]),
        .IN4(IN4[31:16]),   .IN5(IN5[31:16]),   .IN6(IN6[31:16]),   .IN7(IN7[31:16]),
        .IN8(IN8[31:16]),   .IN9(IN9[31:16]),   .IN10(IN10[31:16]), .IN11(IN11[31:16]),
        .IN12(IN12[31:16]), .IN13(IN13[31:16]), .IN14(IN14[31:16]), .IN15(IN15[31:16]),
        .S0(S0), .S1(S1), .S2(S2), .S3(S3)
    );

    mux16_16 slice_high ( // Upper 16 bits [47:32]
        .Y(Y[47:32]),
        .IN0(IN0[47:32]),   .IN1(IN1[47:32]),   .IN2(IN2[47:32]),   .IN3(IN3[47:32]),
        .IN4(IN4[47:32]),   .IN5(IN5[47:32]),   .IN6(IN6[47:32]),   .IN7(IN7[47:32]),
        .IN8(IN8[47:32]),   .IN9(IN9[47:32]),   .IN10(IN10[47:32]), .IN11(IN11[47:32]),
        .IN12(IN12[47:32]), .IN13(IN13[47:32]), .IN14(IN14[47:32]), .IN15(IN15[47:32]),
        .S0(S0), .S1(S1), .S2(S2), .S3(S3)
    );

endmodule