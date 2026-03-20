module mux8_32_behav(
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] in2,
    input [31:0] in3,
    input [31:0] in4,
    input [31:0] in5,
    input [31:0] in6,
    input [31:0] in7,
    input s0, s1, s2,
    output [31:0] out
);
    assign out = s2 ? (s1 ? (s0 ? in7 : in6) : (s0 ? in5 : in4)) : (s1 ? (s0 ? in3 : in2) : (s0 ? in1 : in0));
endmodule