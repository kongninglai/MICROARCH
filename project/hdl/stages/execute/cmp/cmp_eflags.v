module cmp_eflags #(
    parameter WIDTH=32
) (
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] out,
    input [31:0] cout,

    output OF,
    output SF,
    output ZF,
    output AF,
    output CF,
    output PF
); 
    // SF, ZF, PF doesn't depend on alu_op

    set_sf_zf_pf #(.WIDTH(WIDTH)) st_sf_zf_pf_inst(.out(out),.SF(SF),.ZF(ZF),.PF(PF));

    // CF Logic:
    // sbb: borrow = ~cout

    inv1$ inv_sub_cf(CF, cout[WIDTH-1]);

    // OF Logic:
    // sbb: carry into MSB ~ carry out of MSB
    xor2$ xor_cout6_7(OF, cout[WIDTH-2], cout[WIDTH-1]);

    // AF Logic:
    // sub: ~cout[3]
    // and/or: cleared to 0

    inv1$ inv_sub_af(AF, cout[3]);

endmodule