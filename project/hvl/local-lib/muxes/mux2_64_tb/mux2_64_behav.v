module mux2_64_behav(
    input [63:0] in0,
    input [63:0] in1,
    input s0,
    output [63:0] out
);
    assign out = s0 ? in1 : in0;
endmodule