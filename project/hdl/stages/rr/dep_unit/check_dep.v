module check_dep(
    input [2:0] src_id,
    input [2:0] dst_id,
    input       ld_dst,
    input       ld_src,

    output      dep
);
    wire id_eq;
    wire [2:0] xnor_out;
    xnor2$	xnor2$_0[2:0](xnor_out, src_id, dst_id);
    wire w1;
    and2$ and_w1(w1, ld_dst, ld_src);
    and4$ and_dep(dep, w1, xnor_out[0], xnor_out[1], xnor_out[2]);
endmodule

module check_dep_bar(
    input [2:0] src_id,
    input [2:0] dst_id,
    input       ld_dst,
    input       ld_src,

    output      dep_bar
);
    wire id_eq;
    wire [2:0] xnor_out;
    xnor2$	xnor2$_0[2:0](xnor_out, src_id, dst_id);
    wire w1;
    and2$ and_w1(w1, ld_dst, ld_src);
    nand4$ nand_dep(dep_bar, w1, xnor_out[0], xnor_out[1], xnor_out[2]);
endmodule