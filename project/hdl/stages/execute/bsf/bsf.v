module bsf #(
    parameter WIDTH=32
) (
    input  wire [WIDTH-1:0] src,
    output wire [$clog2(WIDTH)-1:0] idx,
    output wire       ZF
);
    wire src_not_all_zero;
    big_or #(.WIDTH(WIDTH)) or_src(src_not_all_zero, src[WIDTH-1:0]);
    inv1$ inv_zf(ZF, src_not_all_zero);

    generate
        if (WIDTH==32) begin : WIDTH_32_GEN
            wire low_16_has1;
            big_or #(.WIDTH(16)) or_low16(low_16_has1, src[15:0]);
            wire [15:0] nibble16;
            mux2_16$ mux2_nibble16(nibble16, src[31:16], src[15:0], low_16_has1);

            wire low_8_has1;
            big_or #(.WIDTH(8)) or_low8(low_8_has1, nibble16[7:0]);
            wire [7:0] nibble8;
            mux2_8$ mux2_nibble8(nibble8, nibble16[15:8], nibble16[7:0], low_8_has1);

            wire low_4_has1_bar, low_4_has1;
            nor4$   nor4$_low_4_has1_bar(low_4_has1_bar, nibble8[0], nibble8[1], nibble8[2], nibble8[3]);
            bufferHInv16$ bufferHInv16$_low_4_has1(low_4_has1, low_4_has1_bar);
            wire [3:0] nibble4;
            mux2$ mux2_nibble4[3:0](nibble4, nibble8[7:4], nibble8[3:0], low_4_has1);

            wire low_2_has1;
            or2$ or_low2(low_2_has1, nibble4[1], nibble4[0]);
            wire [1:0] nibble2;
            mux2$ mux2_nibble2[1:0](nibble2, nibble4[3:2], nibble4[1:0], low_2_has1);

            inv1$ inv_idx0(idx[0], nibble2[0]);
            inv1$ inv_idx1(idx[1], low_2_has1);
            inv1$ inv_idx2(idx[2], low_4_has1);
            inv1$ inv_idx3(idx[3], low_8_has1);
            inv1$ inv_idx4(idx[4], low_16_has1);
            
        end else if (WIDTH==16) begin : WIDTH_16_GEN
            wire low_8_has1;
            big_or #(.WIDTH(8)) or_low8(low_8_has1, src[7:0]);
            wire [7:0] nibble8;
            mux2_8$ mux2_nibble8(nibble8, src[15:8], src[7:0], low_8_has1);

            wire low_4_has1_bar, low_4_has1;
            nor4$   nor4$_low_4_has1_bar(low_4_has1_bar, nibble8[0], nibble8[1], nibble8[2], nibble8[3]);
            bufferHInv16$ bufferHInv16$_low_4_has1(low_4_has1, low_4_has1_bar);
            wire [3:0] nibble4;
            mux2$ mux2_nibble4[3:0](nibble4, nibble8[7:4], nibble8[3:0], low_4_has1);

            wire low_2_has1;
            or2$ or_low2(low_2_has1, nibble4[1], nibble4[0]);
            wire [1:0] nibble2;
            mux2$ mux2_nibble2[1:0](nibble2, nibble4[3:2], nibble4[1:0], low_2_has1);

            inv1$ inv_idx0(idx[0], nibble2[0]);
            inv1$ inv_idx1(idx[1], low_2_has1);
            inv1$ inv_idx2(idx[2], low_4_has1);
            inv1$ inv_idx3(idx[3], low_8_has1);

        end else if (WIDTH==8) begin : WIDTH_8_GEN
            wire low_4_has1_bar, low_4_has1;
            nor4$   nor4$_low_4_has1_bar(low_4_has1_bar, nibble8[0], nibble8[1], nibble8[2], nibble8[3]);
            bufferHInv16$ bufferHInv16$_low_4_has1(low_4_has1, low_4_has1_bar);
            wire [3:0] nibble4;
            mux2$ mux2_nibble4[3:0](nibble4, src[7:4], src[3:0], low_4_has1);

            wire low_2_has1;
            or2$ or_low2(low_2_has1, nibble4[1], nibble4[0]);
            wire [1:0] nibble2;
            mux2$ mux2_nibble2[1:0](nibble2, nibble4[3:2], nibble4[1:0], low_2_has1);

            inv1$ inv_idx0(idx[0], nibble2[0]);
            inv1$ inv_idx1(idx[1], low_2_has1);
            inv1$ inv_idx2(idx[2], low_4_has1);

        end
    endgenerate
endmodule