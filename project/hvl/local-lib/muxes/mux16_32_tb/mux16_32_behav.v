module mux16_32_behav(
    output reg  [31:0] out, 
    input  wire [31:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input  wire [31:0] in8, in9, in10, in11, in12, in13, in14, in15,
    input  wire        s0, s1, s2, s3 
);

    always @(*) begin
        case({s3, s2, s1, s0})
            4'b0000: Y = in0;  
            4'b0001: Y = in1;
            4'b0010: Y = in2;
            4'b0011: Y = in3;
            4'b0100: Y = in4;
            4'b0101: Y = in5;
            4'b0110: Y = in6;
            4'b0111: Y = in7;
            4'b1000: Y = in8;
            4'b1001: Y = in9;
            4'b1010: Y = in10;
            4'b1011: Y = in11;
            4'b1100: Y = in12;
            4'b1101: Y = in13;
            4'b1110: Y = in14;
            4'b1111: Y = in15;
            default: Y = 32'bx; 
        endcase
    end

endmodule