/*
This module is a 16 to 1 multiplexer for 48-bit inputs. 
Constructed using three parallel 16-bit 16-to-1 multiplexers.

Delay: 0.5ns total (worst 0.22 though data and 0.5 select)
*/

module mux4_48 (
    output wire [47:0] Y,
    input  wire [47:0] IN0, IN1, IN2, IN3,
    input  wire        S0, S1
);

    // Layer 1: 
    mux4_16$ slice_low ( //lower 16 bits [15:0]
        .Y(Y[15:0]),
        .IN0(IN0[15:0]),   .IN1(IN1[15:0]),   .IN2(IN2[15:0]),   .IN3(IN3[15:0]),
        .S0(S0), .S1(S1)
    );

    mux4_16$ slice_mid ( //Middle 16 bits [31:16]
        .Y(Y[31:16]),
        .IN0(IN0[31:16]),   .IN1(IN1[31:16]),   .IN2(IN2[31:16]),   .IN3(IN3[31:16]),
        .S0(S0), .S1(S1)
    );

    mux4_16$ slice_high ( // Upper 16 bits [47:32]
        .Y(Y[47:32]),
        .IN0(IN0[47:32]),   .IN1(IN1[47:32]),   .IN2(IN2[47:32]),   .IN3(IN3[47:32]),
        .S0(S0), .S1(S1)
    );

endmodule