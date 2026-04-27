module mux3_onehot_slice(
    input wire [2:0] in_sel, //one hot select signal
    input wire in0, in1, in2,
    output wire out
);

    genvar i;
    wire [2:0] in_wire, and_wire;
    assign in_wire = {in2, in1, in0};
    generate 
        for (i = 0; i < 3; i = i + 1) begin: MUX_LOOP
            and2$ AND(.out(and_wire[i]), .in0(in_sel[i]), .in1(in_wire[i]));
        end
    endgenerate

    or3$ FINAL_MUX_VALUE(.out(out), .in0(and_wire[0]), .in1(and_wire[1]), .in2(and_wire[2]));
endmodule