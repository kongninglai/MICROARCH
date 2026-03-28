/*
This module outputs the correct sib byte and whether it is a true sib byte. 
Critical Path: through is_sib_true signal
Delay: 4.55ns total delay for is_sib_true signal.
Prefix_num signal is ready at 3.38ns. 
Then, it takes 0.8ns to select the correct sib byte and determine if there is an sib byte. Then it takes 0.35ns to 
determine if the signal is true. Is_modrm is ready at 4.2ns. 
3.38 + 0.8 = 4.18 (need to wait for modrm to be ready, so wait until 4.2ns) + 0.35 = 4.55ns total delay for is_sib_true signal
*/

module logic_sib_byte(
    input wire [7:0] candidate_modrm1,
    input wire [7:0] candidate_modrm2,
    input wire [7:0] candidate_modrm3,
    input wire [7:0] candidate_modrm4,
    input wire [7:0] candidate_modrm5,
    input wire [7:0] candidate_modrm6,
    input wire is_modrm_true, //signal is ready at 2.69ns
    input wire [2:0] prefix_num, //signal is ready at 3.38ns
    output wire [7:0] sib_byte_true,
    output wire is_sib_true
);  

    //Layer 1: 0.75ns
    wire is_sib1, is_sib2, is_sib3, is_sib4, is_sib5, is_sib6;
    logic_is_sib IS_SIB1(
        .candidate_modrm(candidate_modrm1),
        .is_sib(is_sib1)
    );
    logic_is_sib IS_SIB2(
        .candidate_modrm(candidate_modrm2),
        .is_sib(is_sib2)
    );
    logic_is_sib IS_SIB3(
        .candidate_modrm(candidate_modrm3),
        .is_sib(is_sib3)
    );
    logic_is_sib IS_SIB4(
        .candidate_modrm(candidate_modrm4),
        .is_sib(is_sib4)
    );
    logic_is_sib IS_SIB5(
        .candidate_modrm(candidate_modrm5),
        .is_sib(is_sib5)
    );
    logic_is_sib IS_SIB6(
        .candidate_modrm(candidate_modrm6),
        .is_sib(is_sib6)
    );
    
    //Layer 2: 0.8ns
    wire is_any_sib;
    mux8 choose_is_sib(.outb(is_any_sib), .in0(is_sib1), .in1(is_sib2), .in2(is_sib3), .in3(is_sib4), .in4(is_sib5), .in5(is_sib6), .in6(1'b0), .in7(1'b0), .s0(prefix_num[0]), .s1(prefix_num[1]), .s2(prefix_num[2]));
    mux8_8 choose_sib_byte(.Y(sib_byte_true), .IN0(candidate_modrm2), .IN1(candidate_modrm3), .IN2(candidate_modrm4), .IN3(candidate_modrm5), .IN4(candidate_modrm6), .IN5(8'd0), .IN6(8'd0), .IN7(8'd0), .S0(prefix_num[0]), .S1(prefix_num[1]), .S2(prefix_num[2]));

    //Layer 3: 0.35ns
    and2$ and_sib_true_signal(.out(is_sib_true), .in0(is_any_sib), .in1(is_modrm_true));
endmodule