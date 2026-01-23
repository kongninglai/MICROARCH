module eq_3b (
    input [2:0] in0,
    input [2:0] in1,
    output eq
); 
    wire [2:0] xnor_out;

    xnor2$ xnor2$_0[2:0](xnor_out, in0, in1);

    and3$  and3_0(eq, xnor_out[0], xnor_out[1], xnor_out[2]);
endmodule