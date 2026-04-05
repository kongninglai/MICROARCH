module ex_not_bh(
    input [31:0] not_in,
    output [31:0] not_out
);
    assign not_out = ~not_in;
endmodule