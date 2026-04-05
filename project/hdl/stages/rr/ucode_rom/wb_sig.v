module wb_sig(
    input [11:0] ucode_sig,
    output gpwr0_en,
    output gpwr1_en,
    output segwr_en,
    output mmxwr_en,
    output [1:0] dstA_size,
    output [1:0] dstB_size,
    output [1:0] rw,
    output [1:0] ds
); 
    assign {
        gpwr0_en, gpwr1_en, segwr_en, mmxwr_en, dstA_size, dstB_size, rw, ds
    } = ucode_sig;
endmodule