module mux11_onehot(
    input wire [10:0] in_sel, //one hot select signal
    input wire [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, //inputs
    output wire [31:0] out //output
);

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : mux_loop
            mux11_onehot_slice DUT(
                .in_sel(in_sel),
                .in0(in0[i]), .in1(in1[i]), .in2(in2[i]), .in3(in3[i]), .in4(in4[i]), .in5(in5[i]), 
                .in6(in6[i]), .in7(in7[i]), .in8(in8[i]), .in9(in9[i]), .in10(in10[i]),
                .out(out[i])
            );
        end

    endgenerate


endmodule