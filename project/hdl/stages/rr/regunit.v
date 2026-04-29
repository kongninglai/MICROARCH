module regunit(
    input clk,
    input rst_n,

    input [7:0]  from_rr_opcode,
    input [5:0]  from_rr_modrm,
    input [5:0]  from_rr_sib,
    input        from_rr_has_sib,
    input [1:0]  from_rr_sig_gprd0_mux,
    input        from_rr_sig_gprd1_mux,
    input [1:0]  from_rr_sig_gprd2_mux,
    input        from_rr_sig_srcregA_mux,
    input        from_rr_sig_srcregB_mux,
    input [1:0]  from_rr_sig_ds,

    output [31:0] to_rr_srcregA,
    output [31:0] to_rr_srcregB,
    output [31:0] to_rr_srcregC,
    output [31:0] to_rr_basereg1,
    output [31:0] to_rr_indexreg1,
    output [31:0] to_rr_basereg2,

    output [2:0] to_dep_srcregA_idx,
    output [1:0] to_dep_srcA_size,
    output [2:0] to_dep_srcregB_idx,
    output [1:0] to_dep_srcB_size,
    output [2:0] to_dep_srcregC_idx,
    output [1:0] to_dep_srcC_size,
    output [2:0] to_dep_basereg1_idx,
    output [2:0] to_dep_indexreg1_idx,
    output [2:0] to_dep_basereg2_idx,

    input  from_rr_sig_srcsreg_mux,
    input [2:0] from_rr_seg_prefix,
    input from_rr_has_seg_prefix,
    input from_rr_sig_segrd0_mux,
    input from_rr_sig_segrd1_mux,
    output [15:0] to_rr_srcSREG,
    output [15:0] to_rr_SREG1,
    output [15:0] to_rr_SREG2,
    output [31:0] to_rr_SLIM1,
    output [31:0] to_rr_SLIM2,
    output [15:0] CS,
    output [31:0] CS_LIMIT,
    output [2:0] to_dep_srcSREG_idx,
    output [2:0] to_dep_SREG1_idx,
    output [2:0] to_dep_SREG2_idx,

    output [63:0] to_rr_MMA,
    output [63:0] to_rr_MMB,

    output [2:0] to_dep_MMA_idx,
    output [2:0] to_dep_MMB_idx,

    input [2:0]  from_wb_gpwr0_idx,
    input [31:0] from_wb_gpwr0_data,
    input [1:0]  from_wb_gpwr0_size,
    input        from_wb_gpwr0_en,
    input [2:0]  from_wb_gpwr1_idx,
    input [31:0] from_wb_gpwr1_data,
    input [1:0]  from_wb_gpwr1_size,
    input        from_wb_gpwr1_en,

    input [2:0]  from_wb_segwr_idx,
    input [15:0] from_wb_segwr_data,
    input from_wb_segwr_en,
    input [15:0] from_ex_cs_wr_data,
    input from_ex_cs_wr_en,

    input [2:0]  from_wb_mmxwr_idx,
    input [63:0] from_wb_mmxwr_data,
    input from_wb_mmxwr_en
);
    wire [2:0] gprd0_idx, gprd0_idx_prebuf, gprd1_idx, gprd2_idx, gprd2_idx_prebuf, gprd3_idx;
    wire [31:0] gprd0_data, gprd1_data, gprd2_data, gprd3_data;
    wire [1:0] gprd0_ds, gprd0_ds_prebuf, gprd1_ds, gprd2_ds, gprd3_ds;
    wire [2:0] gp_base;
    mux2$ mux2_base[2:0](gp_base, from_rr_modrm[2:0], from_rr_sib[2:0], from_rr_has_sib);
    // gprd0_idx: 0(EAX/000), 1(ECX/001), 2(EDI/111), 3(ESP/100)
    // gprd1_idx: 0(reg(modrm[5:3])), 1(opr[2:0])
    // gprd2_idx: 0(mod=modrm[2:0]), 1(ESI/110), 2(base)
    // gprd3_idx: index(sib[5:3])
    bufferH16$  bufferH16$_gprd0_idx[2:0](gprd0_idx, gprd0_idx_prebuf);
    bufferH16$  bufferH16$_gprd0_ds[1:0](gprd0_ds, gprd0_ds_prebuf);

    wire [2:0] dummy_gprd0_idx_ds;
    mux4_8$ mux4_gprd0_idx_ds
    (
      {dummy_gprd0_idx_ds, gprd0_idx_prebuf, gprd0_ds_prebuf},
      {3'd0, 3'b000, from_rr_sig_ds},
      {3'd0, 3'b001, 2'b10},
      {3'd0, 3'b111, 2'b10},
      {3'd0, 3'b100, 2'b10},
      from_rr_sig_gprd0_mux[0], 
      from_rr_sig_gprd0_mux[1]
    );
    
    mux2$  mux2_gprd1_idx[2:0](gprd1_idx, from_rr_modrm[5:3], from_rr_opcode[2:0], from_rr_sig_gprd1_mux);
    assign gprd1_ds = from_rr_sig_ds;
    
    bufferH16$  bufferH16$_gprd2_idx[2:0](gprd2_idx, gprd2_idx_prebuf);
        
    wire [2:0] dummy_gprd2_idx_ds;
    mux4_8$ mux4_gprd2_idx_ds
    (
      {dummy_gprd2_idx_ds, gprd2_idx_prebuf, gprd2_ds},
      {3'd0, from_rr_modrm[2:0], from_rr_sig_ds},
      {3'd0, 3'b110, 2'b10},
      {3'd0, gp_base, 2'b10},
      {3'd0, 3'b000, 2'b10},
      from_rr_sig_gprd2_mux[0], 
      from_rr_sig_gprd2_mux[1]
    );


    bufferH16$  bufferH16$_gprd3_idx[2:0](gprd3_idx, from_rr_sib[5:3]);
    assign gprd3_ds = 2'b10;

    // wire [1:0] srcregA_ds, srcregB_ds, srcregC_ds;
    // srcregA: 0(gprd0), 1(gprd2)
    // srcregB: 0(gprd0), 1(gprd1)
    // srcregC: gprd0
    // base1: gprd2
    // index1: gprd3
    // base2: gprd0
    mux2_32 mux2_32_srcregA(.out(to_rr_srcregA), .in0(gprd0_data), .in1(gprd2_data), .s0(from_rr_sig_srcregA_mux));
    // mux2$ mux2_sregA_ds[1:0](srcregA_ds, gprd0_ds, gprd2_ds, from_rr_sig_srcregA_mux);

    wire [2:0] dummy_srcregA_idx_size, to_dep_srcregA_idx_prebuf;
    mux2_8$ mux2_8$_srcregA_idx_size
    (
      {dummy_srcregA_idx_size, to_dep_srcregA_idx_prebuf, to_dep_srcA_size},
      {3'd0, gprd0_idx, gprd0_ds},
      {3'd0, gprd2_idx, gprd2_ds},
      from_rr_sig_srcregA_mux
    );

    bufferH16$  bufferH16$_to_dep_srcregA_idx[2:0](to_dep_srcregA_idx, to_dep_srcregA_idx_prebuf);

    mux2_32 mux2_32_srcregB(.out(to_rr_srcregB), .in0(gprd0_data), .in1(gprd1_data), .s0(from_rr_sig_srcregB_mux));
    // mux2$ mux2_sregB_ds[1:0](srcregB_ds, gprd0_ds, gprd1_ds, from_rr_sig_srcregB_mux);

    wire [2:0] dummy_srcregB_idx_size, to_dep_srcregB_idx_prebuf;
    mux2_8$ mux2_8$_srcregB_idx_size
    (
      {dummy_srcregB_idx_size, to_dep_srcregB_idx_prebuf, to_dep_srcB_size},
      {3'd0, gprd0_idx, gprd0_ds},
      {3'd0, gprd1_idx, gprd1_ds},
      from_rr_sig_srcregB_mux
    );

    bufferH16$  bufferH16$_to_dep_srcregB_idx[2:0](to_dep_srcregB_idx, to_dep_srcregB_idx_prebuf);

    assign to_rr_srcregC = gprd0_data;
    // assign srcregC_ds = gprd0_ds;
    assign to_dep_srcregC_idx = gprd0_idx;
    assign to_dep_srcC_size = gprd0_ds;
    
    assign to_rr_basereg1 = gprd2_data;
    assign to_dep_basereg1_idx = gprd2_idx;

    assign to_rr_indexreg1 = gprd3_data;
    assign to_dep_indexreg1_idx = gprd3_idx;

    assign to_rr_basereg2 = gprd0_data;
    assign to_dep_basereg2_idx = gprd0_idx;

    regfile_gp gprf (
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(gprd0_idx),
        .rd_reg1_idx(gprd1_idx),
        .rd_reg2_idx(gprd2_idx),
        .rd_reg3_idx(gprd3_idx),

        .rd_reg0_data(gprd0_data),
        .rd_reg1_data(gprd1_data),
        .rd_reg2_data(gprd2_data),
        .rd_reg3_data(gprd3_data),

        .rd_reg0_ds(gprd0_ds),
        .rd_reg1_ds(gprd1_ds),
        .rd_reg2_ds(gprd2_ds),
        .rd_reg3_ds(gprd3_ds),
        
        .wr_reg0_idx(from_wb_gpwr0_idx),
        .wr_reg0_data(from_wb_gpwr0_data),
        .wr_reg0_ds(from_wb_gpwr0_size),
        .wr0_en(from_wb_gpwr0_en),

        .wr_reg1_idx(from_wb_gpwr1_idx),
        .wr_reg1_data(from_wb_gpwr1_data),
        .wr_reg1_ds(from_wb_gpwr1_size),
        .wr1_en(from_wb_gpwr1_en)
    ); 

    wire [2:0] segrd0_idx, segrd0_idx_prebuf, segrd1_idx, segrd1_idx_prebuf;
    wire [15:0] segrd0_data, segrd1_data;
    wire [19:0] segrd0_limit, segrd1_limit;
    // sregrd0_idx: According to srcsreg_mux: 0(based on base1_idx), 1(opcode[5:3])
    // sregrd1_idx: srcsreg_mux = 1 ? modrm[5:3] : (gprd0_mux==010? ES : SS), means if base1=edi, use es
    wire [2:0] base1_seg_idx;
    get_segreg_idx get_base1_seg(.seg_idx(base1_seg_idx), .base_reg_idx(to_dep_basereg1_idx), .seg_override(from_rr_seg_prefix), .has_seg_override(from_rr_has_seg_prefix));
    mux2$ mux2_sregrd0_idx[2:0](segrd0_idx_prebuf, base1_seg_idx, from_rr_opcode[5:3], from_rr_sig_segrd0_mux);
    bufferH64$  bufferH64$_segrd0_idx[2:0](segrd0_idx, segrd0_idx_prebuf);

    wire gprd0_mux_1_inv, gprd0_is_edi;
    inv1$ inv_gprd0_mux1(gprd0_mux_1_inv, from_rr_sig_gprd0_mux[1]);
    nor2$ nor_gprd0_is_edi(gprd0_is_edi, gprd0_mux_1_inv, from_rr_sig_gprd0_mux[0]);

    wire [2:0] es_ss_idx;
    mux2$ mux2_es_ss[2:0](es_ss_idx, 3'b010, 3'b000, gprd0_is_edi);
    mux2$ mux2_sregrd1_idx[2:0](segrd1_idx_prebuf, from_rr_modrm[5:3], es_ss_idx, from_rr_sig_segrd1_mux);
    bufferH64$  bufferH64$_segrd1_idx[2:0](segrd1_idx, segrd1_idx_prebuf);

    mux2_16$ mux2_srcsreg(to_rr_srcSREG, segrd0_data, segrd1_data, from_rr_sig_srcsreg_mux);

    wire [2:0]  to_dep_srcSREG_idx_prebuf;
    mux2$ mux2_srcsreg_idx[2:0](to_dep_srcSREG_idx_prebuf, segrd0_idx, segrd1_idx, from_rr_sig_srcsreg_mux);
    bufferH16$  bufferH16$_to_dep_srcSREG_idx[2:0](to_dep_srcSREG_idx, to_dep_srcSREG_idx_prebuf);

    wire [31:0] seg_slim1_out, seg_slim2_out;
    wire sreg1_is_ss, sreg2_is_ss, inv_segrd0_idx1_out, inv_segrd1_idx1_out;
    inv1$ inv_sreg0_idx1(inv_segrd0_idx1_out, segrd0_idx[1]);
    nor2$ nor_sreg1_is_ss(sreg1_is_ss, inv_segrd0_idx1_out, segrd0_idx[0]);

    assign to_rr_SREG1 = segrd0_data;
    assign seg_slim1_out = {12'b0, segrd0_limit};
    mux2_32 mux2_slim1_ignore_ss(to_rr_SLIM1, seg_slim1_out, 32'hffff_ffff, sreg1_is_ss);
    assign to_dep_SREG1_idx = segrd0_idx;

    inv1$ inv_sreg1_idx1(inv_segrd1_idx1_out, segrd1_idx[1]);
    nor2$ nor_sreg2_is_ss(sreg2_is_ss, inv_segrd1_idx1_out, segrd1_idx[0]);

    assign to_rr_SREG2 = segrd1_data;
    assign seg_slim2_out = {12'b0, segrd1_limit};
    mux2_32 mux2_slim2_ignore_ss(to_rr_SLIM2, seg_slim2_out, 32'hffff_ffff, sreg2_is_ss);
    assign to_dep_SREG2_idx = segrd1_idx;

    wire [19:0] cs_limit_out;
    assign CS_LIMIT = {12'b0, cs_limit_out};
    regfile_seg segrf(  
        .clk(clk),
        .rst_n(rst_n),

        .segrd0_idx(segrd0_idx),
        .segrd1_idx(segrd1_idx),
        .segrd0_data(segrd0_data),
        .segrd1_data(segrd1_data),
        .segrd0_limit(segrd0_limit),
        .segrd1_limit(segrd1_limit),
        .cs(CS),
        .cs_limit(cs_limit_out),
        .segwr_idx(from_wb_segwr_idx),
        .segwr_data(from_wb_segwr_data),
        .segwr_en(from_wb_segwr_en),
        .cs_wr_data(from_ex_cs_wr_data),
        .cs_wr_en(from_ex_cs_wr_en)
    );

    wire [2:0] mmxrd0_idx, mmxrd1_idx;
    bufferH64$  bufferH64$_mmxrd0_idx[2:0](mmxrd0_idx, from_rr_modrm[5:3]);
    bufferH64$  bufferH64$_mmxrd1_idx[2:0](mmxrd1_idx, from_rr_modrm[2:0]);
    regfile_mmx mmxrf(
        .clk(clk),
        .rst_n(rst_n),
        .mmxrd0_idx(mmxrd0_idx),
        .mmxrd1_idx(mmxrd1_idx),
        .mmxrd0_data(to_rr_MMA),
        .mmxrd1_data(to_rr_MMB),
        .mmxwr_idx(from_wb_mmxwr_idx),
        .mmxwr_data(from_wb_mmxwr_data),
        .mmxwr_en(from_wb_mmxwr_en)
    );
    assign to_dep_MMA_idx = mmxrd0_idx;
    assign to_dep_MMB_idx = mmxrd1_idx;
    
endmodule