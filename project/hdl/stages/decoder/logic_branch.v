/*
Branch Type: 00 (not a branch), 01 (unconditional near), 10 (conditional near), 11(far)
*/

module logic_branch(
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
    big_eq #(.WIDTH(8)) IS_CALL_REL( .in0(opcode), .in1(8'hE8), .eq(call_rel) );
    big_eq #(.WIDTH(8)) IS_JMP_REL( .in0(opcode), .in1(8'hE9), .eq(jmp_rel) );
    big_eq #(.WIDTH(8)) IS_JMP_REL8( .in0(opcode), .in1(8'hEB), .eq(jmp_rel8) );
    big_eq #(.WIDTH(8)) IS_CALL_JMP_R_MEM( .in0(opcode), .in1(8'hFF), .eq(call_jmp_r_mem) );
    big_eq #(.WIDTH(8)) IS_RET_IMM_NEAR( .in0(opcode), .in1(8'hC2), .eq(ret_imm_near) );
    big_eq #(.WIDTH(8)) IS_RET_NEAR( .in0(opcode), .in1(8'hC3), .eq(ret_near) );

    // 10: Conditional near
    big_eq #(.WIDTH(8)) IS_JNE_REL8( .in0(opcode), .in1(8'h75), .eq(jne_rel8) );
    big_eq #(.WIDTH(8)) IS_JNBE_REL8( .in0(opcode), .in1(8'h77), .eq(jnbe_rel8) );
    big_eq #(.WIDTH(8)) IS_JNE( .in0(opcode), .in1(8'h85), .eq(jne) );
    big_eq #(.WIDTH(8)) IS_JNBE( .in0(opcode), .in1(8'h87), .eq(jnbe) );

    // 11: Far
    big_eq #(.WIDTH(8)) IS_CALL_PTR( .in0(opcode), .in1(8'h9A), .eq(call_ptr) );
    big_eq #(.WIDTH(8)) IS_JMP_PTR( .in0(opcode), .in1(8'hEA), .eq(jmp_ptr) );
    big_eq #(.WIDTH(8)) IS_IRETD( .in0(opcode), .in1(8'hCF), .eq(iRETd) );
    big_eq #(.WIDTH(8)) IS_RET_IMM_FAR( .in0(opcode), .in1(8'hCA), .eq(ret_imm_far) );
    big_eq #(.WIDTH(8)) IS_RET_FAR( .in0(opcode), .in1(8'hCB), .eq(ret_far) );

    // FF is only a branch if the opcode extention is /2 or /4
    wire is_valid_ff_branch, ext_opcode_ff_2, ext_opcode_ff_4, ext_opcode_ff_v;
    big_eq #(.WIDTH(8)) op_extention_2( .in0({5'd0, modrm[5:3]}), .in1(8'h02), .eq(ext_opcode_ff_2) );
    big_eq #(.WIDTH(8)) op_extention_4( .in0({5'd0, modrm[5:3]}), .in1(8'h04), .eq(ext_opcode_ff_4) );
    or2$ valid_opcode_ext(.out(ext_opcode_ff_v), .in0(ext_opcode_ff_2), .in1(ext_opcode_ff_4) );
    and3$ valid_ff(is_valid_ff_branch, v_modrm, ext_opcode_ff_v, call_jmp_r_mem);

    //Group
    wire is_uncond_l, is_uncond_u, is_uncond_candidate, is_uncond, ext_opcode_bar; 
    inv1$ EXT_OP_INV(ext_opcode_bar, ext_opcode);
    or3$ OR_UNCOND_lower(is_uncond_l, call_rel, jmp_rel, jmp_rel8);
    or3$ OR_UNCOND_upper(is_uncond_u, is_valid_ff_branch, ret_imm_near, ret_near);
    or2$ OR_UNCOND(is_uncond_candidate, is_uncond_l, is_uncond_u);
    and2$ AND_UNCOND(is_uncond, is_uncond_candidate, ext_opcode_bar); //opcode only uncond if no 0F
    
    wire is_far_and, is_far_or1, is_far_or2, is_far_or3, is_far;
    or3$ is_far_or_1(.out(is_far_or1), .in0(call_ptr), .in1(jmp_ptr), .in2(ret_far));
    or2$ is_far_or_2(.out(is_far_or2), .in0(iRETd), .in1(ret_imm_far));
    or2$ is_far_or_3(.out(is_far_or3), .in0(is_far_or1), .in1(is_far_or2));
    and2$ is_far_final(.out(is_far), .in0(ext_opcode_bar), .in1(is_far_or3));

    wire is_cond_p, is_cond_np, is_cond, is_cond_np_candidate, is_cond_p_candidate; //no prefix vs prefix
    or2$ is_cond_no_prefix_or(.out(is_cond_np_candidate), .in0(jne_rel8), .in1(jnbe_rel8));
    and2$ is_cond_no_prefix_and(.out(is_cond_np), .in0(ext_opcode_bar), .in1(is_cond_np_candidate));
    or2$ is_cond_prefix_or(.out(is_cond_p_candidate), .in0(jne), .in1(jnbe));
    and2$ is_cond_prefix_and(.out(is_cond_p), .in0(ext_opcode), .in1(is_cond_p_candidate));

    or2$ is_cond_final(.out(is_cond), .in0(is_cond_np), .in1(is_cond_p));

    // drive out
    or2$ bit1(.out(branch_type[1]), .in0(is_cond), .in1(is_far));
    or2$ bit0(.out(branch_type[0]), .in0(is_uncond), .in1(is_far));
    or3$ BRANCH(.out(is_branch), .in0(is_uncond), .in1(is_cond), .in2(is_far));

endmodule