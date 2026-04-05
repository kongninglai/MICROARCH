module alu_eflags #(
    parameter WIDTH=32
) (
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] out,
    input [31:0] cout,
    input [2:0]  alu_op, // ADD, OR, ADC, SBB, AND
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
    // add/adc: cout
    // sbb: borrow = ~cout
    // and/or: cleared to 0
    wire add_cf, sub_cf;
    assign add_cf = cout[WIDTH-1];
    inv1$ inv_sub_cf(sub_cf, cout[WIDTH-1]);
    mux8 mux8_cf(CF, add_cf, 1'b0, add_cf, sub_cf, 1'b0, , , , alu_op[0], alu_op[1], alu_op[2]);

    // OF Logic:
    // add/adc/sbb: carry into MSB ~ carry out of MSB
    // and/or: cleared to 0
    wire arith_of;
    xor2$ xor_cout6_7(arith_of, cout[WIDTH-2], cout[WIDTH-1]);
    mux8 mux8_of(OF, arith_of, 1'b0, arith_of, arith_of, 1'b0, , , , alu_op[0], alu_op[1], alu_op[2]);

    // AF Logic:
    // add/adc: cout[3]
    // sub: ~cout[3]
    // and/or: cleared to 0
    wire add_af, sub_af;
    assign add_af = cout[3];
    inv1$ inv_sub_af(sub_af, cout[3]);
    mux8 mux8_af(AF, add_af, 1'b0, add_af, sub_af, 1'b0, , , , alu_op[0], alu_op[1], alu_op[2]);

endmodule