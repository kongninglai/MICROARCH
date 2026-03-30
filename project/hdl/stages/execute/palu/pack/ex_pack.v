module ex_pack(
    input [63:0] dest_in,
    input [63:0] src_in,
    input pack_size, // 0 for word_to_byte, 1 for dword to word
    output [63:0] dest_out
);
    wire [63:0] packsswb_out, packssdw_out;
    
    genvar i;
    generate 
        // word to byte:
        for (i=0; i<4; i=i+1) begin 
            sat_signed_narrow #(.IN_WIDTH(16), .OUT_WIDTH(8)) word_to_byte_dest (.in(dest_in[i*16+15:i*16]),.out(packsswb_out[i*8+7:i*8]));
            sat_signed_narrow #(.IN_WIDTH(16), .OUT_WIDTH(8)) word_to_byte_src (.in(src_in[i*16+15:i*16]),.out(packsswb_out[i*8+39:i*8+32]));
        end
        // dword to word:
        for (i=0; i<2; i=i+1) begin 
            sat_signed_narrow #(.IN_WIDTH(32), .OUT_WIDTH(16)) dword_to_word_dest (.in(dest_in[i*32+31:i*32]),.out(packssdw_out[i*16+15:i*16]));
            sat_signed_narrow #(.IN_WIDTH(32), .OUT_WIDTH(16)) dword_to_word_src (.in(src_in[i*32+31:i*32]),.out(packssdw_out[i*16+47:i*16+32]));
        end
    endgenerate
    
    mux2_64 mux2_dest_out(dest_out, packsswb_out, packssdw_out, pack_size);
endmodule