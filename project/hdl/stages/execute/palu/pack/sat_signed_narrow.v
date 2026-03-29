module sat_signed_narrow #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input [IN_WIDTH-1:0] in,
    output [OUT_WIDTH-1:0] out
); 
    localparam EXT_WIDTH = IN_WIDTH - OUT_WIDTH;
    wire [EXT_WIDTH-1:0] sign_ext_expected, sign_mismatch;
    assign sign_ext_expected = {EXT_WIDTH{in[OUT_WIDTH-1]}};

    xor2$ xor_mismatch[EXT_WIDTH-1:0](sign_mismatch, sign_ext_expected, in[IN_WIDTH-1:OUT_WIDTH]);

    wire overflow, pos_overflow, neg_overflow;
    big_or #(.WIDTH(EXT_WIDTH)) or_mismatch(overflow, sign_mismatch);

    wire inv_out;
    inv1$ inv_inst(inv_out, in[IN_WIDTH-1]);
    and2$ and_pos_overflow(pos_overflow, overflow, inv_out);
    and2$ and_neg_overflow(neg_overflow, overflow, in[IN_WIDTH-1]);

    wire [OUT_WIDTH-1:0] neg_out;
    wire buffered_neg_overflow, buffered_pos_overflow;
    bufferH16$ buffer_neg(buffered_neg_overflow, neg_overflow);
    bufferH16$ buffer_pos(buffered_pos_overflow, pos_overflow);
    mux2$ mux2_neg_out[OUT_WIDTH-1:0](neg_out, in[OUT_WIDTH-1:0], {1'b1, {(OUT_WIDTH-1){1'b0}}}, buffered_neg_overflow);
    mux2$ mux2_pos_out[OUT_WIDTH-1:0](out, neg_out, {1'b0, {(OUT_WIDTH-1){1'b1}}}, buffered_pos_overflow);
endmodule