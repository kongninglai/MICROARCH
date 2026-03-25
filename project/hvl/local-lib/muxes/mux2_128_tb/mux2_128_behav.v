module mux2_128_behav(
    input [127:0] in0,
    input [127:0] in1,
    input s0,
    output [127:0] out
);
    assign out = s0 ? in1 : in0;
endmodule