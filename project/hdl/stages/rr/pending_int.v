module pending_int(
    input clk,
    input rst_n,
    input set_int,
    input clear_int,

    output pending_int
); 
    // set_int, clear_int: 00(q), 01(0), 10(1), 11(1)
    wire din, q, qbar;
    assign pending_int = q;
    mux4$ mux4_din(din, q, 1'b0, 1'b1, 1'b1, clear_int, set_int);
    dff$ dff_int(clk, din, q, qbar, rst_n, 1'b1);

endmodule