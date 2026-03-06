/*
0.2 - data 
0.3 - select
*/
module mux2_32(Y, IN0, IN1, S0);
    input  [31:0] IN0;
    input  [31:0] IN1;
    input  S0;
    output [31:0] Y;

    // Lower 16 bits [15:0]
    mux2_16$ mux_lower (
        .Y(Y[15:0]),
        .IN0(IN0[15:0]),
        .IN1(IN1[15:0]),
        .S0(S0)
    );

    // Upper 16 bits [31:16]
    mux2_16$ mux_upper (
        .Y(Y[31:16]),
        .IN0(IN0[31:16]),
        .IN1(IN1[31:16]),
        .S0(S0)
    );

endmodule