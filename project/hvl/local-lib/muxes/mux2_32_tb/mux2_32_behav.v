module mux2_32_behav(
    input [31:0] in0,
    input [31:0] in1,
    input s0,
    output [31:0] out
);
    assign out = s0 ? in1 : in0;
endmodule