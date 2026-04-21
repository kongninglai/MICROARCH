/*
 * shf_op: SAL(0), SAR(1)
 * 
*/
module ex_shf(
    input           shf_op,
    input [1:0]     ds, // 00 for 8-bit, 01 for 16-bit, 10 for 32-bit, 11 undefined
    input [31:0]    shf_data,
    input [7:0]     shf_amt,

    output [31:0] shf_out,
    output [31:0] shf_eflags,
    output [31:0] shf_eflags_mask
); 
    wire [4:0] shf_amt_masked;
    assign shf_amt_masked = shf_amt[4:0];

    wire [31:0] se8_shf_data, se16_shf_data, shf_data_extended, shf_data_extended_buf4096;
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se8_shf_data_inst(.in(shf_data[7:0]), .out(se8_shf_data));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se16_shf_data_inst(.in(shf_data[15:0]), .out(se16_shf_data));
    mux4_32 mux4_32_shf_data(shf_data_extended, se8_shf_data, se16_shf_data, shf_data, , ds[0], ds[1]);
    bufferH4096$ bufferH4096$_shf_data_extended_buf4096[31:0](shf_data_extended_buf4096, shf_data_extended);

    wire [31:0] lshf_out, rshf_out;
    lshf_var_32b lshf_out_inst(.in(shf_data_extended_buf4096), .shf_amt(shf_amt_masked), .out(lshf_out));
    rshfa_var_32b rshf_out_inst(.in(shf_data_extended_buf4096), .shf_amt(shf_amt_masked), .out(rshf_out));

    wire [31:0] shf_out_buf16;
    bufferH16$  bufferH16$_shf_out_buf16[31:0](shf_out_buf16, shf_out);    
    mux2_32 mux2_32_shf_out(shf_out, lshf_out, rshf_out, shf_op);

    // EFLAGS

    // CF: last bit shifted out of the destinatin
    // SAL: = shf_data[width-shf_amt]
    // SAR: = shf_data[shf_amt-1]
    wire CF;

    wire [4:0] shf_amt_dec, shf_amt_dec_buf256;
    bufferH256$ bufferH256$_shf_amt_dec_buf256[4:0](shf_amt_dec_buf256, shf_amt_dec);
    big_decrement #(.WIDTH(5)) dec_shf_amt(.a(shf_amt_masked), .s(shf_amt_dec));

    wire [31:0] lshf_dec_out, rshf_dec_out;
    lshf_var_32b lshf_dec_out_inst(.in(shf_data_extended_buf4096), .shf_amt(shf_amt_dec_buf256), .out(lshf_dec_out));
    rshfa_var_32b rshf_dec_out_inst(.in(shf_data_extended_buf4096), .shf_amt(shf_amt_dec_buf256), .out(rshf_dec_out));
    
    wire lshf_cf, rshf_cf;
    mux4$ mux4_lshf_cf(lshf_cf, lshf_dec_out[7], lshf_dec_out[15], lshf_dec_out[31], , ds[0], ds[1]);
    assign rshf_cf = rshf_dec_out[0];

    mux2$ mux2_cf(CF, lshf_cf, rshf_cf, shf_op);

    // OF: only defined for 1-bit shift
    // SAL: = MSB(DEST) XOR CF
    // SAR: = 0
    wire OF;

    wire lshf8_of, lshf16_of, lshf32_of, lshf_of;
    xor2$ xor_lshf8_of(lshf8_of, shf_data[6], shf_data[7]);
    xor2$ xor_lshf16_of(lshf16_of, shf_data[14], shf_data[15]);
    xor2$ xor_lshf32_of(lshf32_of, shf_data[30], shf_data[31]);
    mux4$ mux4_lshf_of(lshf_of, lshf8_of, lshf16_of, lshf32_of, , ds[0], ds[1]);

    mux2$ mux2_of(OF, lshf_of, 1'b0, shf_op);

    // SF, ZF, and PF flags are set according to the result.
    wire SF, ZF, PF;

    wire sf_8, sf_16, sf_32;
    wire zf_8, zf_16, zf_32;
    wire pf_8, pf_16, pf_32;

    set_sf_zf_pf #(.WIDTH(8)) st_sf_zf_pf_8(.out(shf_out_buf16),.SF(sf_8),.ZF(zf_8),.PF(pf_8));
    set_sf_zf_pf #(.WIDTH(16)) st_sf_zf_pf_16(.out(shf_out_buf16),.SF(sf_16),.ZF(zf_16),.PF(pf_16));
    set_sf_zf_pf #(.WIDTH(32)) st_sf_zf_pf_32(.out(shf_out_buf16),.SF(sf_32),.ZF(zf_32),.PF(pf_32));

    mux4$ mux4_sf(SF, sf_8, sf_16, sf_32, , ds[0], ds[1]);
    mux4$ mux4_zf(ZF, zf_8, zf_16, zf_32, , ds[0], ds[1]);
    mux4$ mux4_pf(PF, pf_8, pf_16, pf_32, , ds[0], ds[1]);

    assign shf_eflags = {
        20'b0,   // [31:12]
        OF,      // [11] OF
        3'b0,    // [10:8]
        SF,      // [7] SF
        ZF,      // [6] ZF
        1'b0,    // [5]
        1'b0,    // [4] AF
        1'b0,    // [3]
        PF,      // [2] PF
        1'b0,    // [1]
        CF       // [0] CF
    };

    // TODO: For OF and AF, how should we deal with the "undefined"? Should we clear the mask?
    
    wire shf_amt_non_zero;
    big_or #(.WIDTH(8)) or_shf_amt(shf_amt_non_zero, shf_amt);
    mux2_32 mux2_shf_eflags_mask(shf_eflags_mask, 32'b0, 32'h08C5, shf_amt_non_zero);
endmodule