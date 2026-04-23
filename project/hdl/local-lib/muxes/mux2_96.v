module mux2_96(
    output [95:0] out,
    input [95:0] in0,
    input [95:0] in1,
    input s0
);  
    wire [31:0] lower_mux_out;
    wire [63:0] upper_mux_out;
    mux2_32 mux2_32_low(.out(lower_mux_out),.in0(in0[31:0]),.in1(in1[31:0]),.s0(s0)); 
    mux2_64 mux2_64_high(.out(upper_mux_out),.in0(in0[95:32]),.in1(in1[95:32]),.s0(s0)); 
    assign out = {upper_mux_out, lower_mux_out};
endmodule