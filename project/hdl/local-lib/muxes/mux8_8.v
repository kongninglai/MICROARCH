/*
8 Input mux that can select 8 wide inputs
Delay: 0.8ns worst case
*/
module mux8_8 (
    output wire [7:0] Y,
    input  wire [7:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire       S0, S1, S2
);

    wire [7:0] w0;
    wire [7:0] w1;

    // Delay: Select -> 0.5ns, Data -> 0.22ns
    mux4_8$ m0 (
        .Y(w0), 
        .IN0(IN0), 
        .IN1(IN1), 
        .IN2(IN2), 
        .IN3(IN3), 
        .S0(S0), 
        .S1(S1)
    );

    // Delay: Select -> 0.5ns, Data -> 0.22ns
    mux4_8$ m1 (
        .Y(w1), 
        .IN0(IN4), 
        .IN1(IN5), 
        .IN2(IN6), 
        .IN3(IN7), 
        .S0(S0), 
        .S1(S1)
    );

    // Delay: Select -> 0.3ns, Data -> 0.2ns
    mux2_8$ m2 (
        .Y(Y), 
        .IN0(w0), 
        .IN1(w1), 
        .S0(S2)
    );

endmodule