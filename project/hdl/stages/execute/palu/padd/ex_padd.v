module ex_padd(
    input [63:0] dest_in,
    input [63:0] src_in,
    input padd_size, // 0 for paddw, 1 for paddd
    output [63:0] dest_out
);
    wire [63:0] paddw_out, paddd_out;
    genvar i;

    generate 
        for (i=0; i<4; i=i+1) begin 
            PA_16b paddw(.in0(dest_in[i*16+15:i*16]), .in1(src_in[i*16+15:i*16]), .s(paddw_out[i*16+15:i*16]));
        end

        for (i=0; i<2; i=i+1) begin 
            PA_32b paddd(.in0(dest_in[i*32+31:i*32]), .in1(src_in[i*32+31:i*32]), .s(paddd_out[i*32+31:i*32]));
        end
    endgenerate

    mux2_64 mux2_dest_out(dest_out, paddw_out, paddd_out, padd_size);
endmodule