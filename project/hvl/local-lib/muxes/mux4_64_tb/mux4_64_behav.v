module mux4_64_behav(
    input [63:0] in0,
    input [63:0] in1,
    input [63:0] in2,
    input [63:0] in3,
    input s0, 
    input s1,
    output reg [63:0] out
);
    always @(*) begin
        case ({s1, s0})
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
        endcase
    end
endmodule