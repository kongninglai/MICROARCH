module mux3_32(
    output [31:0] out,
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] in2,
    input s0,
    input s1
); 
    mux3_16$ mux0(.IN0(in0[15:0]), .IN1(in1[15:0]), .IN2(in2[15:0]), .S0(s0), .S1(s1), .Y(out[15:0]));
    mux3_16$ mux1(.IN0(in0[31:16]), .IN1(in1[31:16]), .IN2(in2[31:16]), .S0(s0), .S1(s1), .Y(out[31:16]));
endmodule