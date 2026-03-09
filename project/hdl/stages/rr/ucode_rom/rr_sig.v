module rr_sig(
    input [63:0] ucode_sig,
    output [1:0] ldAB,
    output [2:0] dstidA_mux,
    output [1:0] dstidB_mux,
    output srcregA_mux,
    output srcregB_mux,
    output [2:0] gprd0_mux,
    output [1:0] gprd2_mux,
    output [2:0] ldREGS,
    output [10:0] needREGS,
    output ldEFLAGS,
    output alu_srcb_mux,
    output [1:0] shf_srcb_mux,
    output ldEIP,
    output ldCS,
    output [2:0] eflags_mux,
    output [2:0] eip_mux,
    output [1:0] cs_mux,
    output [3:0] gp_dsta_mux,
    output [2:0] gp_dstb_mux,
    output seg_dst_mux,
    output [1:0] mm_dst_mux,
    output [3:0] store_data_mux,
    output [1:0] rw
); 
    wire [5:0] dummy;
    assign {ldAB, dstidA_mux, dstidB_mux, srcregA_mux, srcregB_mux, gprd0_mux, gprd2_mux, 
            ldREGS, needREGS, ldEFLAGS, alu_srcb_mux, shf_srcb_mux, ldEIP, ldCS, eflags_mux, eip_mux,
            cs_mux, gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux, store_data_mux, rw, dummy} = ucode_sig;
endmodule