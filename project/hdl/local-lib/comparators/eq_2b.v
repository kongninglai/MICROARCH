module eq_2b (
    input [1:0] in0,
    input [1:0] in1,
    output eq
); 
    wire [1:0] xnor_out;

    xnor2$ xnor2$_0[1:0](xnor_out, in0, in1);

    and2$  and1_0(eq, xnor_out[0], xnor_out[1]);
endmodule