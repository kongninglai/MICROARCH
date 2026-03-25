module ex_palu(
    input [63:0] dest_in,
    input [63:0] src_in,
    input palu_size,
    input [1:0] mmx_op,
    output [63:0] dest_out
);  
    wire [63:0] pack_out, padd_out, pavg_out;
    ex_pack pack (
        .dest_in(dest_in),
        .src_in(src_in),
        .pack_size(palu_size),
        .dest_out(pack_out)
    );

    ex_padd padd (
        .dest_in(dest_in),
        .src_in(src_in),
        .padd_size(palu_size),
        .dest_out(padd_out)
    );

    ex_pavg pavg (
        .dest_in(dest_in),
        .src_in(src_in),
        .pavg_size(palu_size),
        .dest_out(pavg_out)
    );

    mux4_64 mux4_palu_out(dest_out, pack_out, pavg_out, 32'bx, padd_out, mmx_op[0], mmx_op[1]);
endmodule