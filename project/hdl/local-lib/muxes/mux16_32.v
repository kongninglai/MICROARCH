/*
This module is a 16 to 1 multiplexer for 32 bit inputs. It takes 16 32-bit inputs and selects 
one of them based on the 4-bit select signal (S0, S1, S2, S3).

Delay: 1.1ns
0.8ns + 0.3ns = 1.1ns

*/

module mux16_32 (
    output wire [31:0] Y,
    input  wire [31:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire [31:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15,
    input  wire        S0, S1, S2, S3 
);

    wire [31:0] lower_half_out;
    wire [31:0] upper_half_out;

    // Stage 1: 0.8ns 
    mux8_32 lower_mux (
        .Y(lower_half_out),
        .IN0(IN0), .IN1(IN1), .IN2(IN2), .IN3(IN3),
        .IN4(IN4), .IN5(IN5), .IN6(IN6), .IN7(IN7),
        .S0(S0), .S1(S1), .S2(S2)
    );

    mux8_32 upper_mux (
        .Y(upper_half_out),
        .IN0(IN8), .IN1(IN9), .IN2(IN10), .IN3(IN11),
        .IN4(IN12), .IN5(IN13), .IN6(IN14), .IN7(IN15),
        .S0(S0), .S1(S1), .S2(S2)
    );

    //Stage 2: 0.3ns through select 
    mux2_32 final (
        .Y(Y), 
        .IN0(lower_half_out), 
        .IN1(upper_half_out), 
        .S0(S3)
    );

endmodule