module ex_sig #(
    parameter EX_CONTROL_SIGS_WIDTH=59
)(
    input [EX_CONTROL_SIGS_WIDTH-1:0] ucode_sig,
    output [1:0] ldAB,
    output [1:0] dstA_size,
    output [1:0] dstB_size,
    output [2:0] ldREGS,
    output ldEFLAGS,
    output ldEIP,
    output ldCS,
    output alu_srcb_mux,
    output [1:0] shf_srcb_mux,
    output [2:0] eflags_mux,
    output [2:0] eip_mux,
    output [1:0] cs_mux,
    output [1:0] mmx_op,
    output [2:0] alu_op,
    output shf_op,
    output movs0,
    output movs1,
    output cmps0,
    output cmps1,
    output cmps2,
    output [1:0] con_jmp,
    output cmpxchg,
    output cmovc,
    output [3:0] gp_dsta_mux,
    output [2:0] gp_dstb_mux,
    output seg_dst_mux,
    output [1:0] mm_dst_mux,
    output [3:0] store_data_mux,
    output [1:0] rw,
    output [1:0] ds,
    output rm, 
    output op_ovr,
    output palu_size,
    output sbb_dir,
    output iret0,
    output [11:0] EX_FW_CONTROL_SIGS
);
    assign {
        ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, movs0, movs1, cmps0, cmps1, cmps2, cmpxchg, cmovc, seg_dst_mux,
        ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux,
        ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux,
        gp_dsta_mux, store_data_mux, rm, op_ovr, palu_size, sbb_dir, iret0,
        EX_FW_CONTROL_SIGS
    } = ucode_sig;
endmodule