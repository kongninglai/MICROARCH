module mux2_128(
    output [127:0] out,
    input [127:0] in0,
    input [127:0] in1,
    input s0
);
    wire [63:0] lower_mux_out, upper_mux_out;
    mux2_64 LOWER(.out(lower_mux_out),.in0(in0[63:0]),.in1(in1[63:0]),.s0(s0)); 
    mux2_64 UPPER(.out(upper_mux_out),.in0(in0[127:64]),.in1(in1[127:64]),.s0(s0)); 
    assign out = {upper_mux_out, lower_mux_out};
endmodule