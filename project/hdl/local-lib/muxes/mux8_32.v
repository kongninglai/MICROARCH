/*
32-bit wide 8-to-1 Multiplexer
Constructed from 4 parallel 8-bit slices.
Delay: 0.8ns 
*/

module mux8_32 (
    output wire [31:0] Y,
    input  wire [31:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire        S0, S1, S2
);

    // Slice 0: Bits [7:0]
    mux8_8 byte0 (
        .Y(Y[7:0]),
        .IN0(IN0[7:0]), .IN1(IN1[7:0]), .IN2(IN2[7:0]), .IN3(IN3[7:0]),
        .IN4(IN4[7:0]), .IN5(IN5[7:0]), .IN6(IN6[7:0]), .IN7(IN7[7:0]),
        .S0(S0), .S1(S1), .S2(S2)
    );

    // Slice 1: Bits [15:8]
    mux8_8 byte1 (
        .Y(Y[15:8]),
        .IN0(IN0[15:8]), .IN1(IN1[15:8]), .IN2(IN2[15:8]), .IN3(IN3[15:8]),
        .IN4(IN4[15:8]), .IN5(IN5[15:8]), .IN6(IN6[15:8]), .IN7(IN7[15:8]),
        .S0(S0), .S1(S1), .S2(S2)
    );

    // Slice 2: Bits [23:16]
    mux8_8 byte2 (
        .Y(Y[23:16]),
        .IN0(IN0[23:16]), .IN1(IN1[23:16]), .IN2(IN2[23:16]), .IN3(IN3[23:16]),
        .IN4(IN4[23:16]), .IN5(IN5[23:16]), .IN6(IN6[23:16]), .IN7(IN7[23:16]),
        .S0(S0), .S1(S1), .S2(S2)
    );

    // Slice 3: Bits [31:24]
    mux8_8 byte3 (
        .Y(Y[31:24]),
        .IN0(IN0[31:24]), .IN1(IN1[31:24]), .IN2(IN2[31:24]), .IN3(IN3[31:24]),
        .IN4(IN4[31:24]), .IN5(IN5[31:24]), .IN6(IN6[31:24]), .IN7(IN7[31:24]),
        .S0(S0), .S1(S1), .S2(S2)
    );

endmodule