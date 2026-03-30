module wb_sig(
    input [12:0] ucode_sig,
    output [1:0] ldAB,
    output [1:0] dstA_size,
    output [1:0] dstB_size,
    output [2:0] ldREGS,
    output [1:0] rw,
    output [1:0] ds
); 
    assign {
        ldAB, dstA_size, dstB_size, ldREGS, rw, ds
    } = ucode_sig;
endmodule