module check_dep(
    input [2:0] src_id,
    input [2:0] dst_id,
    input       ld_dst,
    input       ld_src,

    output      dep
);
    wire id_eq;
    big_eq #(.WIDTH(3)) eq_id (.in0(src_id), .in1(dst_id),.eq(id_eq));
    and3$ and_dep(dep, ld_dst, ld_src, id_eq);
endmodule