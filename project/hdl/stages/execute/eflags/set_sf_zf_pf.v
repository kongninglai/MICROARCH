module set_sf_zf_pf #(
    parameter WIDTH=32
) (
    input [31:0] out,
    output SF,
    output ZF,
    output PF
); 
    // SF Logic
    buffer$ buffer$_SF(SF, out[WIDTH-1]);

    // ZF Logic
    wire out_or;
    big_or #(.WIDTH(WIDTH)) or_inst(out_or, out[WIDTH-1:0]);
    inv1$ inv_out_or(ZF, out_or);

    // PF Logic
    wire xor_low8;
    xor8LL xor8_low8(xor_low8, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
    inv1$ inv_pf(PF, xor_low8);
endmodule