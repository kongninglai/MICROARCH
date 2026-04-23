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
    generate
        if (WIDTH == 32) begin
            wire g0, g1, g2, g3, g4, g5, g6, g7;
            wire h0, h1;

            nor4$ n0(g0, out[0],  out[1],  out[2],  out[3]);
            nor4$ n1(g1, out[4],  out[5],  out[6],  out[7]);
            nor4$ n2(g2, out[8],  out[9],  out[10], out[11]);
            nor4$ n3(g3, out[12], out[13], out[14], out[15]);
            nor4$ n4(g4, out[16], out[17], out[18], out[19]);
            nor4$ n5(g5, out[20], out[21], out[22], out[23]);
            nor4$ n6(g6, out[24], out[25], out[26], out[27]);
            nor4$ n7(g7, out[28], out[29], out[30], out[31]);

            nand4$ n8(h0, g0, g1, g2, g3);
            nand4$ n9(h1, g4, g5, g6, g7);

            nor2$ n10(ZF, h0, h1);
        end else begin 
            wire out_or;
            big_or #(.WIDTH(WIDTH)) or_inst(out_or, out[WIDTH-1:0]);
            inv1$ inv_out_or(ZF, out_or);
        end       
    endgenerate
    

    // PF Logic
    wire xor_low8;
    xor8LL xor8_low8(xor_low8, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
    inv1$ inv_pf(PF, xor_low8);
endmodule