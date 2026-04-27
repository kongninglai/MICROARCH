module mux3_onehot(
    input wire [2:0] in_sel, //one hot select signal
    input wire [31:0] in0, in1, in2, 
    output wire [31:0] out //output
);

    genvar i;       
    generate
        for (i = 0; i < 32; i = i + 1) begin : mux_loop
            mux3_onehot_slice DUT(
                .in_sel(in_sel),
                .in0(in0[i]), .in1(in1[i]), .in2(in2[i]),
                .out(out[i])
            );
        end

    endgenerate


endmodule