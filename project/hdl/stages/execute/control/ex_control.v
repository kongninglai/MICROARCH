module ex_control(
    input [31:0] r_m,
    input [31:0] imm,
    input [63:0] load_result,
    input [31:0] rel_eip,
    input [31:0] pred_eip,
    input [31:0] ieip,
    input [31:0] iret_eip,
    input [1:0] sig_con_jump,
    input [2:0] sig_eip_mux,
    input sig_op_ovr,
    input eflags_zf,
    input eflags_cf,

    output [31:0] new_eip,
    output branch_taken,
    output mispredict
); 
    wire [31:0] unmasked_eip, eip_mask, masked_eip;
    mux8_32 mux_eip(unmasked_eip, r_m, imm, rel_eip, load_result[31:0], {load_result[63:48], load_result[15:0]}, iret_eip, , , sig_eip_mux[0], sig_eip_mux[1], sig_eip_mux[2]);
    mux2_32 mux_eip_mask(eip_mask, 32'hffff_ffff, 32'h0000_ffff, sig_op_ovr);
    and2$ and2_masked_eip[31:0](masked_eip, unmasked_eip, eip_mask);

    wire ne, nbe, jne, jnbe, uncond_jmp, jmp;
    // ne = (ZF==0), nbe = ((CF==0) & (ZF==0))
    inv1$ inv_ne(ne, eflags_zf);
    nor2$ nor_nbe(nbe, eflags_cf, eflags_zf);
    and2$ and_jne(jne, sig_con_jump[0], ne);
    and2$ and_jnbe(jnbe, sig_con_jump[1], nbe);
    nor2$ nor_uncond(uncond_jmp, sig_con_jump[0], sig_con_jump[1]);

    // ldEIP_out = ldEIP & (uncond_jmp | jne | jnbe) & mispredict
    or3$ or_jmp(branch_taken, uncond_jmp, jne, jnbe);
    mux2_32 mux2_t_nt_eip(new_eip, ieip, masked_eip, branch_taken);
    wire accurate_predict;
    big_eq #(.WIDTH(32)) eq_pred_eip(.eq(accurate_predict), .in0(pred_eip), .in1(new_eip));
    inv1$ inv_mispredict(mispredict, accurate_predict);
endmodule 