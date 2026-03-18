module mux8_64(
    output [63:0] out,
    input [63:0] in0,
    input [63:0] in1,
    input [63:0] in2,
    input [63:0] in3,
    input [63:0] in4,
    input [63:0] in5,
    input [63:0] in6,
    input [63:0] in7,
    input s0, 
    input s1,
    input s2
); 

    wire [63:0] mux4_64_out0, mux4_64_out1;
    wire s0_buffered, s1_buffered;
    bufferH16$ buffer16_s0(s0_buffered, s0);
    bufferH16$ buffer16_s1(s1_buffered, s1);
    mux4_64 mux4_64_0(mux4_64_out0, in0, in1, in2, in3, s0_buffered, s1_buffered);
    mux4_64 mux4_64_1(mux4_64_out1, in4, in5, in6, in7, s0_buffered, s1_buffered);
    mux2_64 mux2_64_out(out, mux4_64_out0, mux4_64_out1, s2);
endmodule