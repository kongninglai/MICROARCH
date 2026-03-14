/*
Add Prefix Amount (0,1,2,3,4), Opcode Amount (1), Modrm Amount (0, 1), SIB Amount (0,1),
Disp Bytes (0,1,2,4), Immediate Amount (0,1,2,4,6)

Rom Sum: Opcode Amount (1) + Modrm Amount + Imm Amount 

Delay: 3.1ns
5.05 + 3.1ns = Incr Amount Ready at 8.15ns
*/
module logic_incr_amt(
    input wire [2:0] rom_sum, //Ready at 4.2ns
    input wire [2:0] disp_size_inbytes, //Ready at 5.05ns
    input wire [2:0] prefix_amount, //Ready at 3.38ns
    input wire sib_present, //Ready at 4.55ns
    output wire [4:0] incr_amt
);

    wire [4:0] csa_sum, csa_carry;
    csa CSA( //1.2ns
        .in0({2'd0, rom_sum}), .in1({2'd0, disp_size_inbytes}), .in2({2'd0, prefix_amount}),
        .sum_vec(csa_sum), .carry_vec(csa_carry)
    );

    FA_4b FA_4b_uut( //1.9ns
        .in0(csa_sum), .in1(csa_carry), .cin(sib_present),
        .s(incr_amt)
    );

endmodule

/*
100 disp
110 sum
100 prefix
001 for sib
----

when sum is 111, imm is 6, there is no displacement i think

*/