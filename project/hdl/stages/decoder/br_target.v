module br_target(
    input wire [31:0] i_eip,
    input wire [7:0] opcode,
    input wire [31:0] imm, //imm[15:0] for rel16, imm[31:0] for rel32
    input wire op_size_overload, //to determine if rel16 or rel32 for certain instructions
    input wire prefix_ext,
    output wire hit, //is this a branch that can be resolved in decode?
    output wire [31:0] bp_eip_target
);  

    //Compare against Opcode
    //75, 77, 0F85, 0F87, E8, E9, EB
    wire eq_jne_rel8, eq_jnbe_rel8, eq_jmp_rel8;
    wire eq_jne_base, eq_jnbe_base, eq_call_base, eq_jmp_base;
    wire eq_jne_rel16, eq_jne_rel32, eq_jnbe_rel16, eq_jnbe_rel32, eq_call_rel16, eq_call_rel32, eq_jmp_rel16, eq_jmp_rel32;
    big_eq #(.WIDTH(8)) cmp_jne_rel8( .in0(opcode), .in1(8'h75), .eq(eq_jne_rel8));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel8( .in0(opcode), .in1(8'h77), .eq(eq_jnbe_rel8));
    big_eq #(.WIDTH(8)) cmp_jne_rel16_32( .in0(opcode), .in1(8'h85), .eq(eq_jne_base));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel16_32( .in0(opcode), .in1(8'h87), .eq(eq_jnbe_base));
    big_eq #(.WIDTH(8)) cmp_call_rel16_32( .in0(opcode), .in1(8'hE8), .eq(eq_call_base));
    big_eq #(.WIDTH(8)) cmp_jmp_rel16_32( .in0(opcode), .in1(8'hE9), .eq(eq_jmp_base));
    big_eq #(.WIDTH(8)) cmp_jmp_rel8( .in0(opcode), .in1(8'hEB), .eq(eq_jmp_rel8));
    
    //Make sure eq is valid only when prefix_ext is not present (to avoid conflicts with xbegin)
    wire eq_jne_base_valid, eq_jnbe_base_valid;
    and2$ and_jne_base_valid( .out(eq_jne_base_valid), .in0(eq_jne_base), .in1(prefix_ext));
    and2$ and_jnbe_base_valid( .out(eq_jnbe_base_valid), .in0(eq_jnbe_base), .in1(prefix_ext));


    //Find rel16 and rel32 variants based on op size override
    wire op_size_overload_bar;
    inv1$ not_op_size_overload( .out(op_size_overload_bar), .in(op_size_overload));
    and2$ and_jne_rel16( .out(eq_jne_rel16), .in0(eq_jne_base_valid), .in1(op_size_overload));
    and2$ and_jnbe_rel16( .out(eq_jnbe_rel16), .in0(eq_jnbe_base_valid), .in1(op_size_overload));
    and2$ and_call_rel16( .out(eq_call_rel16), .in0(eq_call_base), .in1(op_size_overload));
    and2$ and_jmp_rel16( .out(eq_jmp_rel16), .in0(eq_jmp_base), .in1(op_size_overload));
    
    and2$ and_jne_rel32( .out(eq_jne_rel32), .in0(eq_jne_base_valid), .in1(op_size_overload_bar));
    and2$ and_jnbe_rel32( .out(eq_jnbe_rel32), .in0(eq_jnbe_base_valid), .in1(op_size_overload_bar));
    and2$ and_call_rel32( .out(eq_call_rel32), .in0(eq_call_base), .in1(op_size_overload_bar));
    and2$ and_jmp_rel32( .out(eq_jmp_rel32), .in0(eq_jmp_base), .in1(op_size_overload_bar));
    
    //Find if rel8, rel16, or rel32 instruction is hit
    wire is_rel8, is_rel16, is_rel32;
    nor3$ or_rel8( .out(is_rel8), .in0(eq_jne_rel8), .in1(eq_jnbe_rel8), .in2(eq_jmp_rel8));
    nor4$ or_rel16( .out(is_rel16), .in0(eq_jne_rel16), .in1(eq_jnbe_rel16), .in2(eq_call_rel16), .in3(eq_jmp_rel16));
    nor4$ or_rel32( .out(is_rel32), .in0(eq_jne_rel32), .in1(eq_jnbe_rel32), .in2(eq_call_rel32), .in3(eq_jmp_rel32));
    nand3$ or_hit( .out(hit), .in0(is_rel8), .in1(is_rel16), .in2(is_rel32));

    wire [31:0] bp_eip_target_prebuf;
    PA_32b TARGET_rel32_adder(.in0(i_eip), .in1(imm), .s(bp_eip_target_prebuf));
    bufferH16$    bufferH16$_bp_eip_target[31:0](bp_eip_target, bp_eip_target_prebuf);
endmodule