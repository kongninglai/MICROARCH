module get_pid(
    input   [2:0] idx,
    input   [1:0] size,
    output  [2:0] pidx
); 
    wire size_is_8;
    nor2$ nor2_size_is_8(size_is_8, size[1], size[0]);

    wire [2:0] shifted_idx;
    assign shifted_idx = {1'b0, idx[1:0]};
    mux2$ mux2_pidx[2:0](pidx, idx, shifted_idx, size_is_8);

endmodule

module gp_dep(
    input   [2:0]   dstA_id,
    input   [2:0]   dstB_id,
    input           ld_dstA,
    input           ld_dstB,
    input   [1:0]   dstA_size,
    input   [1:0]   dstB_size,
    input   [2:0]   src_id,
    input   [1:0]   src_size,
    input           ld_src,

    output          dep,
    output  [1:0]   fw_mux
);  
    wire [2:0] dstA_pid, dstB_pid, src_pid;
    get_pid get_pid_dstA(dstA_id, dstA_size, dstA_pid);
    get_pid get_pid_dstB(dstB_id, dstB_size, dstB_pid);
    get_pid get_pid_src(src_id, src_size, src_pid);

    wire depA, depB;
    check_dep_bar check_depA(
        .src_id(src_pid),
        .dst_id(dstA_pid),
        .ld_dst(ld_dstA),
        .ld_src(ld_src),
        .dep_bar(depA)
    );

    check_dep_bar check_depB(
        .src_id(src_pid),
        .dst_id(dstB_pid),
        .ld_dst(ld_dstB),
        .ld_src(ld_src),
        .dep_bar(depB)
    );
    
    nand2$ nand_depAB(dep, depA, depB);
    inv1$ inv1$_fw_mux[1:0](fw_mux, {depB, depA});
    
endmodule