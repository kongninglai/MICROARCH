module mux2_64(
    output [63:0] out,
    input [63:0] in0,
    input [63:0] in1,
    input s0
); 
    mux2_16$ mux0(.IN0(in0[15:0]), .IN1(in1[15:0]), .S0(s0), .Y(out[15:0]));
    mux2_16$ mux1(.IN0(in0[31:16]), .IN1(in1[31:16]), .S0(s0), .Y(out[31:16]));
    mux2_16$ mux2(.IN0(in0[47:32]), .IN1(in1[47:32]), .S0(s0), .Y(out[47:32]));
    mux2_16$ mux3(.IN0(in0[63:48]), .IN1(in1[63:48]), .S0(s0), .Y(out[63:48]));
endmodule