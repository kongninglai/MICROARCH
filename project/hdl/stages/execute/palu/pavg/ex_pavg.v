module ex_pavg(
    input [63:0] dest_in,
    input [63:0] src_in,
    input pavg_size, // 0 for pavgb, 1 for pavgw
    output [63:0] dest_out
);
    wire [63:0] pavgb_out, pavgw_out;
    genvar i;

    generate 
        for (i=0; i<8; i=i+1) begin 
            wire [15:0] paddb_out;
            FA_16b paddb(.in0({8'b0, dest_in[i*8+7:i*8]}), .in1({8'b0, src_in[i*8+7:i*8]}), .cin(1'b1), .s(paddb_out), .cout());
            assign pavgb_out[i*8+7:i*8] = paddb_out[8:1];
        end

        for (i=0; i<4; i=i+1) begin 
            wire [31:0] paddw_out;
            FA_32b paddw(.in0({16'b0, dest_in[i*16+15:i*16]}), .in1({16'b0, src_in[i*16+15:i*16]}), .cin(1'b1), .s(paddw_out), .cout());
            assign pavgw_out[i*16+15:i*16] = paddw_out[16:1];
        end
    endgenerate

    mux2_64 mux2_dest_out(dest_out, pavgb_out, pavgw_out, pavg_size);
endmodule