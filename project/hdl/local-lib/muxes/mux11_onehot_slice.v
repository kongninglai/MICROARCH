module mux11_onehot_slice(
    input wire [10:0] in_sel, //one hot select signal
    input wire in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, //inputs
    output wire out
);

    genvar i;
    wire [10:0] in_wire, and_wire;
    assign in_wire = {in10, in9, in8, in7, in6, in5, in4, in3, in2, in1, in0};
    generate 
        for (i = 0; i < 11; i = i + 1) begin: MUX_LOOP
            and2$ AND(.out(and_wire[i]), .in0(in_sel[i]), .in1(in_wire[i]));
        end
    endgenerate

    wire or_out0, or_out1, or_out2;
    or4$ OR0(.out(or_out0), .in0(and_wire[0]), .in1(and_wire[1]), .in2(and_wire[2]), .in3(and_wire[3]));
    or4$ OR1(.out(or_out1), .in0(and_wire[4]), .in1(and_wire[5]), .in2(and_wire[6]), .in3(and_wire[7]));
    or3$ OR2(.out(or_out2), .in0(and_wire[8]), .in1(and_wire[9]), .in2(and_wire[10]));
    or3$ FINAL_MUX_VALUE(.out(out), .in0(or_out0), .in1(or_out1), .in2(or_out2));
endmodule