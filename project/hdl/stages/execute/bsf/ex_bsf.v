module ex_bsf(
    input [31:0] bsf_data,
    input [1:0]     ds, // 00 for 8-bit, 01 for 16-bit, 10 for 32-bit, 11 undefined
    output [31:0] bsf_out,
    output [31:0] bsf_eflags,
    output [31:0] bsf_eflags_mask
);
    wire [3:0] idx16;
    wire [4:0] idx32;
    wire zf16, zf32, zf;

    bsf #(.WIDTH(16)) bsf16(.src(bsf_data[15:0]), .idx(idx16), .ZF(zf16));
    bsf #(.WIDTH(32)) bsf32(.src(bsf_data[31:0]), .idx(idx32), .ZF(zf32));

    mux4_32 mux4_bsf_out(bsf_out, 32'b0, {28'b0, idx16}, {27'b0, idx32}, 32'b0, ds[0], ds[1]);
    mux4$ mux4_zf(zf, 1'b0, zf16, zf32, 1'b0, ds[0], ds[1]);

    assign bsf_eflags = {
        25'b0,   // [31:7]
        zf,      // [6] ZF
        6'b0
    };

    assign bsf_eflags_mask = 32'h040;
endmodule