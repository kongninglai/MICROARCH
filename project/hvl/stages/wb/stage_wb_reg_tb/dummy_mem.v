module dummy_mem(
    input clk,
    input rst_n,
    input we,
    input [57:0]     to_mem_control_sigs,
    input [2:0]      to_mem_dstidA,
    input [2:0]      to_mem_dstidB,
    input [31:0]     to_mem_srcregA,
    input [31:0]     to_mem_srcregB,
    input [31:0]     to_mem_srcregC,
    input [15:0]     to_mem_srcSREG,
    input [63:0]     to_mem_MMA,
    input [63:0]     to_mem_MMB,

    input [15:0]     to_mem_target_cs,
    input [31:0]     to_mem_ld_addr,
    input [31:0]     to_mem_ld_offset,
    input [31:0]     to_mem_ld_slim,
    input [31:0]     to_mem_st_addr,
    input [31:0]     to_mem_st_offset,
    input [31:0]     to_mem_st_slim,
    input [31:0]     to_mem_inc_esp,
    input [31:0]     to_mem_dec_esp,
    input [31:0]     to_mem_imm,
    input [31:0]     to_mem_rel_eip,
 
    input [15:0]     to_mem_cs,
    input [31:0]     to_mem_oeip,
    input [31:0]     to_mem_ieip,
    input [31:0]     to_mem_pred_eip,
    input [1:0]      to_mem_exception,
    input            to_mem_valid,
    
    output [55:0]     from_mem_control_sigs,
    output [2:0]      from_mem_dstidA,
    output [2:0]      from_mem_dstidB,
    output [31:0]     from_mem_srcregA,
    output [31:0]     from_mem_srcregB,
    output [31:0]     from_mem_srcregC,
    output [15:0]     from_mem_srcSREG,
    output [63:0]     from_mem_MMA,
    output [63:0]     from_mem_MMB,

    output [15:0]     from_mem_target_cs,

    output [63:0]     from_mem_load_result,

    output [31:0]     from_mem_inc_esp,
    output [31:0]     from_mem_dec_esp,
    output [31:0]     from_mem_imm,

    output            from_mem_store_is_io_line_0,
    output [10:0]     from_mem_store_addr_line_0,
    output [15:0]     from_mem_store_mask_line_0,
    output            from_mem_store_queue_alloc_line_0,
    output [10:0]     from_mem_store_addr_line_1,
    output [15:0]     from_mem_store_mask_line_1,
    output            from_mem_store_queue_alloc_line_1,
    output [4:0]      from_mem_store_data_shf_amt,

    output [31:0]     from_mem_rel_eip,
    output [15:0]     from_mem_cs,
    output [31:0]     from_mem_oeip,
    output [31:0]     from_mem_ieip,
    output [31:0]     from_mem_pred_eip,
    output [1:0]      from_mem_exception,
    output            from_mem_valid,

    output            from_mem_stall
);

    wire [1:0]      ldAB;
    wire [1:0]      dstA_size;
    wire [1:0]      dstB_size;
    wire [2:0]      ldREGS;
    wire            ldEFLAGS;
    wire            ldEIP;
    wire            ldCS;
    wire            alu_srcb_mux;
    wire [1:0]      shf_srcb_mux;
    wire [2:0]      eflags_mux;
    wire [2:0]      eip_mux;
    wire [1:0]      cs_mux;
    wire [1:0]      mmx_op;
    wire [2:0]      alu_op;
    wire            shf_op;
    wire            cmps;
    wire [1:0]      con_jmp;
    wire            cmpxchg;
    wire            cmovc;
    wire [3:0]      gp_dsta_mux;
    wire [2:0]      gp_dstb_mux;
    wire            seg_dst_mux;
    wire [1:0]      mm_dst_mux;
    wire [3:0]      store_data_mux;
    wire [1:0]      rw;
    wire [1:0]      ds;
    wire [1:0]      mem_ds;
    wire            rm, op_ovr, palu_size, sbb_dir;

    mem_sig dut_mem_sig (
        .ucode_sig(to_mem_control_sigs),
        .ldAB(ldAB),
        .dstA_size(dstA_size),
        .dstB_size(dstB_size),
        .ldREGS(ldREGS),
        .ldEFLAGS(ldEFLAGS),
        .ldEIP(ldEIP),
        .ldCS(ldCS),
        .alu_srcb_mux(alu_srcb_mux),
        .shf_srcb_mux(shf_srcb_mux),
        .eflags_mux(eflags_mux),
        .eip_mux(eip_mux),
        .cs_mux(cs_mux),
        .mmx_op(mmx_op),
        .alu_op(alu_op),
        .shf_op(shf_op),
        .cmps(cmps),
        .con_jmp(con_jmp),
        .cmpxchg(cmpxchg),
        .cmovc(cmovc),
        .gp_dsta_mux(gp_dsta_mux),
        .gp_dstb_mux(gp_dstb_mux),
        .seg_dst_mux(seg_dst_mux),
        .mm_dst_mux(mm_dst_mux),
        .store_data_mux(store_data_mux),
        .rw(rw),
        .ds(ds),
        .mem_ds(mem_ds),
        .rm(rm),
        .op_ovr(op_ovr),
        .palu_size(palu_size),
        .sbb_dir(sbb_dir)
    );
    assign from_mem_control_sigs = {
        ldEFLAGS, ldEIP, ldCS, alu_srcb_mux, shf_op, cmps, cmpxchg, cmovc, seg_dst_mux,
        ldAB, dstA_size, dstB_size, cs_mux, mmx_op, con_jmp, mm_dst_mux, rw, ds, shf_srcb_mux,
        ldREGS, eflags_mux, eip_mux, alu_op, gp_dstb_mux,
        gp_dsta_mux, store_data_mux, rm, op_ovr, palu_size, sbb_dir
    };
    assign  from_mem_dstidA = to_mem_dstidA;
    assign  from_mem_dstidB = to_mem_dstidB;
    assign  from_mem_srcregA = to_mem_srcregA;
    assign  from_mem_srcregB = to_mem_srcregB;
    assign  from_mem_srcregC = to_mem_srcregC;
    assign  from_mem_srcSREG = to_mem_srcSREG;
    assign  from_mem_MMA = to_mem_MMA;
    assign  from_mem_MMB = to_mem_MMB;
    assign  from_mem_target_cs = to_mem_target_cs;
    assign  from_mem_load_result = 64'h0123_4567_89ab_cdef;
    assign  from_mem_inc_esp = to_mem_inc_esp;
    assign  from_mem_dec_esp = to_mem_dec_esp;
    assign  from_mem_imm = to_mem_imm;
    assign  from_mem_store_is_io_line_0 = 1'b0;
    assign  from_mem_store_addr_line_0 = to_mem_st_addr[10:0];
    assign  from_mem_store_mask_line_0 = 16'b0;
    assign  from_mem_store_queue_alloc_line_0 = 1'b0;
    assign  from_mem_store_addr_line_1 = 11'b0;
    assign  from_mem_store_mask_line_1 = 16'b0;
    assign  from_mem_store_queue_alloc_line_1 = 1'b0;
    assign  from_mem_store_data_shf_amt = 5'b0;
    assign  from_mem_rel_eip = to_mem_rel_eip;
    assign  from_mem_cs = to_mem_cs;
    assign  from_mem_oeip = to_mem_oeip;
    assign  from_mem_ieip = to_mem_ieip;
    assign  from_mem_pred_eip = to_mem_pred_eip;
    assign  from_mem_exception = to_mem_exception;
    assign  from_mem_valid = to_mem_valid;
    assign  from_mem_stall = 1'b0;

endmodule