module ex_inc(
    input [31:0]    inc_in,
    input [1:0]     ds,
    input           eflags_df,
    output [31:0]   inc_out
); 
    wire [31:0] inc_amt, dec_amt, amt;
    mux4_32 mux4_inc_amt(inc_amt, 32'h1, 32'h2, 32'h4, 32'bx, ds[0], ds[1]);
    mux4_32 mux4_dec_amt(dec_amt, 32'hFFFFFFFF, 32'hFFFFFFFE, 32'hFFFFFFFC, 32'bx, ds[0], ds[1]);
    mux2_32 mux2_amt(amt, inc_amt, dec_amt, eflags_df);

    PA_32b HA32_ADD(.in0(inc_in), .in1(amt), .s(inc_out));
endmodule