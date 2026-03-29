module alu_eflags_bh #(
    parameter WIDTH = 32
) (
    input  [31:0] in0,
    input  [31:0] in1,
    input  [31:0] out,
    input  [31:0] cout,
    input  [2:0]  alu_op,

    output OF,
    output SF,
    output ZF,
    output AF,
    output CF,
    output PF
);

    wire is_add;
    wire is_adc;
    wire is_sbb;
    wire is_or;
    wire is_and;

    wire is_add_family;
    wire is_sub_family;
    wire is_logic_family;

    assign is_add = (alu_op == 3'b000);
    assign is_or  = (alu_op == 3'b001);
    assign is_adc = (alu_op == 3'b010);
    assign is_sbb = (alu_op == 3'b011);
    assign is_and = (alu_op == 3'b100);

    assign is_add_family   = is_add | is_adc;
    assign is_sub_family   = is_sbb;
    assign is_logic_family = is_or | is_and;

    // SF, ZF, PF doesn't depend on alu_op
    assign SF = out[WIDTH-1];
    assign ZF = ~(|out[WIDTH-1:0]);
    assign PF = ~^out[7:0];

    // CF Logic:
    // add/adc: cout
    // sbb: borrow = ~cout
    // and/or: cleared to 0
    assign CF = is_add_family ?  cout[WIDTH-1] :
                is_sub_family ? ~cout[WIDTH-1] :
                                1'b0;

    // OF Logic:
    // add/adc/sbb: carry into MSB ~ carry out of MSB
    // and/or: cleared to 0
    assign OF = (is_add_family | is_sub_family) ? (cout[WIDTH-2] ^ cout[WIDTH-1]) :
                                                  1'b0;

    // AF Logic:
    // add/adc: cout[3]
    // sub: ~cout[3]
    // and/or: cleared to 0
    assign AF = is_add_family ?  cout[3] :
                is_sub_family ? ~cout[3] :
                                1'b0;

endmodule