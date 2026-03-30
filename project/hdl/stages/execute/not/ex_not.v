module ex_not(
    input [31:0] not_in,
    output [31:0] not_out
);
    inv1$ inv_not[31:0](not_out, not_in);
endmodule