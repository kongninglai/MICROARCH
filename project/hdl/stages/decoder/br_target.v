module br_target(
    input wire [31:0] i_eip,
    input wire [7:0] opcode,
    input wire [31:0] imm, //imm[15:0] for rel16, imm[31:0] for rel32
    input wire op_size_overload, //to determine if rel16 or rel32 for certain instructions
    input wire prefix_ext,
    output wire hit, //is this a branch that can be resolved in decode?
    output wire [31:0] bp_eip_target
);  
    assign hit = 0;
    PA_32b TARGET_rel32_adder(.in0(i_eip), .in1(imm), .s(bp_eip_target));
endmodule