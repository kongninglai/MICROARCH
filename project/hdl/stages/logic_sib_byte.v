module logic_sib_byte(
    input wire [7:0] candidate_modrm1,
    input wire [7:0] candidate_modrm2,
    input wire [7:0] candidate_modrm3,
    input wire [7:0] candidate_modrm4,
    input wire [7:0] candidate_modrm5,
    input wire [7:0] candidate_modrm6,
    input wire [2:0] modrm_idx,
    output wire [7:0] sib_byte_true,
    output wire is_sib_true
);  
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

    wire is_any_sib;
    //CHECK ALL LOGIC BELOW THIS IT IS ALL PROBBABLY WRONG IM TIRED
    //or8$ check_any(.out(is_any_sib), .in0(is_sib1), .in1(is_sib2), .in2(is_sib3), .in3(is_sib4), .in4(is_sib5), .in5(is_sib6), .in6(1'b0), .in7(1'b0));
    assign is_sib_true = is_any_sib;

    mux8_8 choose_sib(.Y(sib_byte_true), .IN0(candidate_modrm2), .IN1(candidate_modrm3), .IN2(candidate_modrm4), .IN3(candidate_modrm5), .IN4(candidate_modrm6), .IN5(8'd0), .IN6(8'd0), .IN7(8'd0), .S0(modrm_idx[0]), .S1(modrm_idx[1]), .S2(modrm_idx[2]));
    mux8 choose_is_sib(.outb(is_any_sib), .in0(is_sib1), .in1(is_sib2), .in2(is_sib3), .in3(is_sib4), .in4(is_sib5), .in5(is_sib6), .in6(1'b0), .in7(1'b0), .s0(modrm_idx[0]), .s1(modrm_idx[1]), .s2(modrm_idx[2]));
endmodule