module ex_control(
    input [31:0] r_m,
    input [31:0] imm,
    input [63:0] load_result,
    input [31:0] rel_eip,
    input [31:0] pred_eip,
    input pred_dir, //predicted direction of branch in decode stage
    input [31:0] ieip,
    input [31:0] iret_eip,
    input [1:0] sig_con_jump,
    input [2:0] sig_eip_mux,
    input sig_op_ovr,
    input eflags_zf,
    input eflags_cf,

    output [31:0] jump_eip,
    output [31:0] new_eip,
    output branch_taken,
    output mispredict_bar
); 
    wire [31:0] unmasked_eip, eip_mask, masked_eip;

    mux16_32 mux_eip
    (
      masked_eip,
      r_m, imm, rel_eip, load_result[31:0], {load_result[63:48], load_result[15:0]}, iret_eip, , ,
      {16'd0, r_m[15:0]}, {16'd0, imm[15:0]}, {16'd0, rel_eip[15:0]}, {16'd0, load_result[15:0]}, {16'd0, load_result[15:0]}, {16'd0, iret_eip[15:0]}, , ,
      sig_eip_mux[0], sig_eip_mux[1], sig_eip_mux[2], sig_op_ovr
    );

    // mux8_32 mux_eip(unmasked_eip, r_m, imm, rel_eip, load_result[31:0], {load_result[63:48], load_result[15:0]}, iret_eip, , , sig_eip_mux[0], sig_eip_mux[1], sig_eip_mux[2]);
    // mux2_32 mux_eip_mask(eip_mask, 32'hffff_ffff, 32'h0000_ffff, sig_op_ovr);
    // and2$ and2_masked_eip[31:0](masked_eip, unmasked_eip, eip_mask);

    wire ne, nbe, jne, jnbe, uncond_jmp, jmp;
    // ne = (ZF==0), nbe = ((CF==0) & (ZF==0))
    inv1$ inv_ne(ne, eflags_zf);
    nor2$ nor_nbe(nbe, eflags_cf, eflags_zf);
    and2$ and_jne(jne, sig_con_jump[0], ne);
    and2$ and_jnbe(jnbe, sig_con_jump[1], nbe);
    nor2$ nor_uncond(uncond_jmp, sig_con_jump[0], sig_con_jump[1]);

    // ldEIP_out = ldEIP & (uncond_jmp | jne | jnbe) & mispredict
    wire branch_taken_bar;
    nor3$ or_jmp(branch_taken_bar, uncond_jmp, jne, jnbe);
    bufferHInv64$ bufferHInv64$_branch_taken(branch_taken, branch_taken_bar);
    assign jump_eip = masked_eip;
    mux2_32 mux2_t_nt_eip(new_eip, ieip, masked_eip, branch_taken);
    wire accurate_predict_eip, accurate_predict_dir;
    big_eq #(.WIDTH(32)) eq_pred_eip(.eq(accurate_predict_eip), .in0(pred_eip), .in1(new_eip));
    big_eq #(.WIDTH(1)) eq_pred_dir(.eq(accurate_predict_dir), .in0(pred_dir), .in1(branch_taken));
    and2$ and_accurate_predict(accurate_predict, accurate_predict_eip, accurate_predict_dir);

    inv1$ inv_mispredict(mispredict, accurate_predict);
endmodule 