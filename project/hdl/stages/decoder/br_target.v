module br_target(
    input wire [31:0] o_eip,
    input wire [7:0] opcode,
    input wire [47:0] imm, //imm[15:0] for rel16, imm[31:0] for rel32
    input wire op_size_overload, //to determine if rel16 or rel32 for certain instructions
    output wire hit, //is this a branch that can be resolved in decode?
    output wire [31:0] bp_eip_target
);  

    //Compare against Opcode
    //75, 77, 0F85, 0F87, E8, E9, EB
    wire eq_jne_rel8, eq_jnbe_rel8, eq_jmp_rel8;
    wire eq_jne_rel16, eq_jne_rel32, eq_jnbe_rel16, eq_jnbe_rel32, eq_call_rel16, eq_call_rel32, eq_jmp_rel16, eq_jmp_rel32;
    wire [10:0] in_sel;
    big_eq #(.WIDTH(8)) cmp_jne_rel8( .in0(opcode), .in1(8'h75), .eq(eq_jne_rel8));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel8( .in0(opcode), .in1(8'h77), .eq(eq_jnbe_rel8));
    big_eq #(.WIDTH(8)) cmp_jne_rel16_32( .in0(opcode), .in1(8'h85), .eq(eq_jne_rel32));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel16_32( .in0(opcode), .in1(8'h87), .eq(eq_jnbe_rel32));
    big_eq #(.WIDTH(8)) cmp_call_rel16_32( .in0(opcode), .in1(8'hE8), .eq(eq_call_rel32));
    big_eq #(.WIDTH(8)) cmp_jmp_rel16_32( .in0(opcode), .in1(8'hE9), .eq(eq_jmp_rel32));
    big_eq #(.WIDTH(8)) cmp_jmp_rel8( .in0(opcode), .in1(8'hEB), .eq(eq_jmp_rel8));
    and2$ and_jne_rel16( .out(eq_jne_rel16), .in0(eq_jne_rel32), .in1(op_size_overload));
    and2$ and_jnbe_rel16( .out(eq_jnbe_rel16), .in0(eq_jnbe_rel32), .in1(op_size_overload));
    and2$ and_call_rel16( .out(eq_call_rel16), .in0(eq_call_rel32), .in1(op_size_overload));
    and2$ and_jmp_rel16( .out(eq_jmp_rel16), .in0(eq_jmp_rel32), .in1(op_size_overload));
    
    //{0x75, 0x77, 0x85_16, 0x85_32, 0x87_16, 0x87_32, 0xE8_16, 0xE8_32, 0xE9_16, 0xE9_32, 0xEB}
    assign in_sel = {eq_jne_rel8, eq_jnbe_rel8, eq_jne_rel16, eq_jne_rel32, eq_jnbe_rel16, eq_jnbe_rel32, eq_call_rel16, eq_call_rel32, eq_jmp_rel16, eq_jmp_rel32, eq_jmp_rel8};

    //Derive Branch Target from EIP + offset
    wire [7:0] target_rel8;
    wire [15:0] target_rel16;
    wire [31:0] target_rel32, target_rel16_ext, target_rel8_ext;
    assign target_rel_8 = imm[7:0];
    assign target_rel_16 = imm[15:0];
    assign target_rel_32 = imm[31:0];

    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) sign_extend_rel8(.in(target_rel8), .out(target_rel8_ext));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) sign_extend_rel16(.in(target_rel16), .out(target_rel16_ext));

    PA_32b (.in0(), .in1(), .s());
);

    //Select the Correct Branch Target 
    mux11_onehot DUT(
        .in_sel(in_sel),
        .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), 
        .in6(in6), .in7(in7), .in8(in8), .in9(in9), .in10(in10),
        .out(out)
    );
endmodule