module mux8_16(
    output [15:0] out,
    input [15:0] in0,
    input [15:0] in1,
    input [15:0] in2,
    input [15:0] in3,
    input [15:0] in4,
    input [15:0] in5,
    input [15:0] in6,
    input [15:0] in7,
    input s0, 
    input s1,
    input s2
); 

    wire [15:0] mux4_32_out0, mux4_32_out1;

    mux4_16$ mux4_32_0(mux4_32_out0, in0, in1, in2, in3, s0, s1);
    mux4_16$ mux4_32_1(mux4_32_out1, in4, in5, in6, in7, s0, s1);
    mux2_16$ mux2_32_out(out, mux4_32_out0, mux4_32_out1, s2);
endmodule