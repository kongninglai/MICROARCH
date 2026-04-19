/*
This module determines if a candidate modrm byte has an sib byte.

Critical Path: through is_sib signal
Delay: 0.55ns
0.2 + 0.35ns
*/

module logic_is_sib(
    input wire [7:0] candidate_modrm,
    output wire is_sib 
);

    wire [1:0] mod_bits;
    wire [2:0] rm_bits;
    assign mod_bits = candidate_modrm[7:6];
    assign rm_bits = candidate_modrm[2:0];

    //Layer 1: 0.2ns worst case
    wire is_mod_not_11; //0.35ns
    nand2$    nand2$_is_mod_not_11(is_mod_not_11, mod_bits[0], mod_bits[1]);

    wire is_rm_X00; //0.2ns
    nor2$     nor2$_is_rm_X00(is_rm_X00, rm_bits[0], rm_bits[1]);

    //Layer 2: 0.35ns
    and3$ check_sib(.out(is_sib), .in0(is_mod_not_11), .in1(is_rm_X00), .in2(rm_bits[2]));

endmodule