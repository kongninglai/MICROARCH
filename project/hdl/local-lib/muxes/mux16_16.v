/*
This module is a 16 to 1 multiplexer for 16-bit inputs. 
Constructed using 8-to-1 8-bit multiplexers and 2-to-1 8-bit multiplexers.

Delay: 1.1ns total
Stage 1 (mux8_8): 0.8ns
Stage 2 (mux2_8$): 0.2ns for data and 0.3 for select
*/

module mux16_16 (
    output wire [15:0] Y,
    input  wire [15:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire [15:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15,
    input  wire        S0, S1, S2, S3 
);

    wire [7:0] lower_half_byte0; // IN0-IN7,   bits [7:0]
    wire [7:0] lower_half_byte1; // IN8-IN15,  bits [7:0]
    wire [7:0] upper_half_byte0; // IN0-IN7,   bits [15:8]
    wire [7:0] upper_half_byte1; // IN8-IN15,  bits [15:8]

    //Layer 1: 0.8ns
    mux8_8 lower_mux_b0 ( // lower byte
        .Y(lower_half_byte0),
        .IN0(IN0[7:0]), .IN1(IN1[7:0]), .IN2(IN2[7:0]), .IN3(IN3[7:0]),
        .IN4(IN4[7:0]), .IN5(IN5[7:0]), .IN6(IN6[7:0]), .IN7(IN7[7:0]),
        .S0(S0), .S1(S1), .S2(S2)
    );
    mux8_8 lower_mux_b1 (
        .Y(lower_half_byte1),
        .IN0(IN8[7:0]), .IN1(IN9[7:0]), .IN2(IN10[7:0]), .IN3(IN11[7:0]),
        .IN4(IN12[7:0]), .IN5(IN13[7:0]), .IN6(IN14[7:0]), .IN7(IN15[7:0]),
        .S0(S0), .S1(S1), .S2(S2)
    );

    mux8_8 upper_mux_b0 ( //upper byte
        .Y(upper_half_byte0),
        .IN0(IN0[15:8]), .IN1(IN1[15:8]), .IN2(IN2[15:8]), .IN3(IN3[15:8]),
        .IN4(IN4[15:8]), .IN5(IN5[15:8]), .IN6(IN6[15:8]), .IN7(IN7[15:8]),
        .S0(S0), .S1(S1), .S2(S2)
    );
    mux8_8 upper_mux_b1 (
        .Y(upper_half_byte1),
        .IN0(IN8[15:8]), .IN1(IN9[15:8]), .IN2(IN10[15:8]), .IN3(IN11[15:8]),
        .IN4(IN12[15:8]), .IN5(IN13[15:8]), .IN6(IN14[15:8]), .IN7(IN15[15:8]),
        .S0(S0), .S1(S1), .S2(S2)
    );

    //Layer 2: 0.2ns for data delay and 0.3ns for select delay
    mux2_8$ final_mux_b0 ( //lower select
        .Y(Y[7:0]), 
        .IN0(lower_half_byte0), 
        .IN1(lower_half_byte1), 
        .S0(S3) 
    );

    mux2_8$ final_mux_b1 ( //upper select
        .Y(Y[15:8]), 
        .IN0(upper_half_byte0), 
        .IN1(upper_half_byte1), 
        .S0(S3) 
    );

endmodule