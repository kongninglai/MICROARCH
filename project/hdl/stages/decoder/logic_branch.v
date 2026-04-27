/*
Branch Type: 00 (not a branch), 01 (unconditional near), 10 (conditional near), 11(far)
*/

module logic_branch #(
    parameter BP_EN=1'b1
)(
    input wire [7:0] opcode,
    input wire [7:0] modrm, 
    input wire v_modrm,
    input wire ext_opcode,       
    output wire is_branch,
    output wire [1:0] branch_type
);

    wire call_rel, jmp_rel, jmp_rel8, call_jmp_r_mem, ret_imm_near, ret_near; //01: Unconditional near
    wire jne_rel8, jnbe_rel8, jne, jnbe; //10: Conditional near
    wire call_ptr, jmp_ptr, iRETd, ret_imm_far, ret_far; //11: Far
    
    // 01: Unconditional near
    big_neq #(.WIDTH(8)) IS_CALL_REL( .in0(opcode), .in1(8'hE8), .neq(call_rel) );
    big_neq #(.WIDTH(8)) IS_JMP_REL( .in0(opcode), .in1(8'hE9), .neq(jmp_rel) );
    big_neq #(.WIDTH(8)) IS_JMP_REL8( .in0(opcode), .in1(8'hEB), .neq(jmp_rel8) );

    // 10: Conditional near
    big_eq #(.WIDTH(8)) IS_JNE_REL8( .in0(opcode), .in1(8'h75), .eq(jne_rel8) );
    big_eq #(.WIDTH(8)) IS_JNBE_REL8( .in0(opcode), .in1(8'h77), .eq(jnbe_rel8) );
    big_neq #(.WIDTH(8)) IS_JNE( .in0(opcode), .in1(8'h85), .neq(jne) );
    big_neq #(.WIDTH(8)) IS_JNBE( .in0(opcode), .in1(8'h87), .neq(jnbe) );

    //Group
    wire is_uncond, ext_opcode_bar; 
    inv1$ EXT_OP_INV(ext_opcode_bar, ext_opcode);
    nand3$ OR_UNCOND_lower(is_uncond, call_rel, jmp_rel, jmp_rel8);

    wire is_cond_p, is_cond_np, is_cond; //no prefix vs prefix
    nor2$ is_cond_no_prefix_or(.out(is_cond_np), .in0(jne_rel8), .in1(jnbe_rel8));
    
    wire is_cond_p_candidate;
    nand2$ is_cond_prefix_or(.out(is_cond_p_candidate), .in0(jne), .in1(jnbe));
    nand2$ is_cond_prefix_and(.out(is_cond_p), .in0(ext_opcode), .in1(is_cond_p_candidate));

    nand2$ is_cond_final(.out(is_cond), .in0(is_cond_np), .in1(is_cond_p));

    // drive out
    generate 
        if (BP_EN) begin 
            assign branch_type[1] = is_cond;
            assign branch_type[0] = is_uncond;

            wire is_branch_bar;
            nor2$ BRANCH(.out(is_branch_bar), .in0(is_uncond), .in1(is_cond));
            bufferHInv64$ bufferHInv64$_is_branch(is_branch, is_branch_bar);
        end else begin 
            assign branch_type = 2'b0;
            assign is_branch = 1'b0;
        end
    endgenerate
   

endmodule