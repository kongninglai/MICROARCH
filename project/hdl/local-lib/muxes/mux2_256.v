module mux2_256(
    output wire [255:0] out,
    input  wire [255:0] in0,
    input  wire [255:0] in1,
    input  wire s0
);
    wire [127:0] lower_mux_out, upper_mux_out;
    
    mux2_128 mux_lower(
        .out(lower_mux_out),
        .in0(in0[127:0]),
        .in1(in1[127:0]),
        .s0(s0)
    ); 
    
    mux2_128 mux_upper(
        .out(upper_mux_out),
        .in0(in0[255:128]),
        .in1(in1[255:128]),
        .s0(s0)
    ); 
    
    assign out = {upper_mux_out, lower_mux_out};

endmodule