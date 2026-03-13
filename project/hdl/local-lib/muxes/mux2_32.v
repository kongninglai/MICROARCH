module mux2_32(
    output [31:0] out,
    input [31:0] in0,
    input [31:0] in1,
    input s0
); 
    mux2_16$ mux0(.IN0(in0[15:0]), .IN1(in1[15:0]), .S0(s0), .Y(out[15:0]));
    mux2_16$ mux1(.IN0(in0[31:16]), .IN1(in1[31:16]), .S0(s0), .Y(out[31:16]));
endmodule