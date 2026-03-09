module mux4_64(
    input [63:0] in0,
    input [63:0] in1,
    input [63:0] in2,
    input [63:0] in3,
    input s0, 
    input s1,
    output [63:0] out
); 
    mux4_16$ mux0(.IN0(in0[15:0]), .IN1(in1[15:0]), .IN2(in2[15:0]), .IN3(in3[15:0]), .S0(s0), .S1(s1), .Y(out[15:0]));
    mux4_16$ mux1(.IN0(in0[31:16]), .IN1(in1[31:16]), .IN2(in2[31:16]), .IN3(in3[31:16]), .S0(s0), .S1(s1), .Y(out[31:16]));
    mux4_16$ mux2(.IN0(in0[47:32]), .IN1(in1[47:32]), .IN2(in2[47:32]), .IN3(in3[47:32]), .S0(s0), .S1(s1), .Y(out[47:32]));
    mux4_16$ mux3(.IN0(in0[63:48]), .IN1(in1[63:48]), .IN2(in2[63:48]), .IN3(in3[63:48]), .S0(s0), .S1(s1), .Y(out[63:48]));
    
endmodule