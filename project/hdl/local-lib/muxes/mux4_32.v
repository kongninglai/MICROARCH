/*
This module is a 4 input multiplexer for 32 bit inputs. It takes 4 32-bit inputs and selects. 
Delay: 
0.22 data
0.5 select
*/

module mux4_32(
    input [31:0] IN0,
    input [31:0] IN1,
    input [31:0] IN2,
    input [31:0] IN3,
    input  S0,
    input  S1,
    output [31:0] Y
);

    mux4_16$ lower(.Y(Y[15:0]), .IN0(IN0[15:0]), .IN1(IN1[15:0]), .IN2(IN2[15:0]), .IN3(IN3[15:0]), .S0(S0), .S1(S1));
    mux4_16$ upper(.Y(Y[31:16]), .IN0(IN0[31:16]), .IN1(IN1[31:16]), .IN2(IN2[31:16]), .IN3(IN3[31:16]), .S0(S0), .S1(S1));

endmodule