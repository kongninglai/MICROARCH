module mux4_32_behav(
    input [31:0] in0,
    input [31:0] in1,
    input [31:0] in2,
    input [31:0] in3,   
    input s0, s1,
    output [31:0] out
);
    assign out = s1 ? (s0 ? in3 : in2) : (s0 ? in1 : in0);
endmodule