module wb_sig(
    input [16:0] ucode_sig,
    output gpwr0_en,
    output gpwr1_en,
    output segwr_en,
    output mmxwr_en,
    output [1:0] dstA_size,
    output [1:0] dstB_size,
    output [1:0] rw,
    output [1:0] ds,
    output movs0,
    output movs1,
    output cmps0,
    output cmps1,
    output cmps2
); 
    assign {
        gpwr0_en, gpwr1_en, segwr_en, mmxwr_en, dstA_size, dstB_size, rw, ds,
        movs0, movs1, cmps0, cmps1, cmps2
    } = ucode_sig;
endmodule