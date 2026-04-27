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
    wire [31:0] bp_eip_target_ungated;
    assign bp_eip_target[31:20] = 12'd0;
    assign bp_eip_target[15:0] = bp_eip_target_ungated[15:0];
    
    wire [3:0] dummy;
    mux2_8$ mux2_8$_clr_top_16
    (
      {dummy, bp_eip_target[19:16]},
      {4'd0, bp_eip_target_ungated[19:16]},
      {8'd0},
      op_size_overload
    );
    PA_32b TARGET_rel32_adder(.in0(i_eip), .in1(imm), .s(bp_eip_target_ungated));
endmodule