module mux2_256_behav(
    input [255:0] in0,
    input [255:0] in1,
    input s0,
    output [255:0] out
);
    assign out = s0 ? in1 : in0;
endmodule