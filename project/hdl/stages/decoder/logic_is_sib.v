module logic_is_sib(
    input wire [7:0] candidate_modrm,
    output wire is_sib 
);

    wire [1:0] mod_bits;
    wire [2:0] rm_bits;
    assign mod_bits = candidate_modrm[7:6];
    assign rm_bits = candidate_modrm[2:0];

    wire is_mod_not_11;
    big_neq #(2) check_mod (
        .in0(mod_bits), .in1(2'b11), .neq(is_mod_not_11)
    );

    wire is_rm_100;
    big_eq #(3) check_rm (
        .in0(rm_bits), .in1(3'b100), .eq(is_rm_100)
    );

    and2$ check_sib(.out(is_sib), .in0(is_mod_not_11), .in1(is_rm_100));

endmodule