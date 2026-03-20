module SUB_32b_behav (
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire        cin,
    output wire [31:0] s,
    output wire [31:0] cout
);

    wire [31:0] in1_inv;
    wire [32:0] c;

    assign in1_inv = ~in1;
    assign c[0] = ~cin;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign {c[i+1], s[i]} = in0[i] + in1_inv[i] + c[i];
            assign cout[i] = c[i+1];
        end
    endgenerate

endmodule