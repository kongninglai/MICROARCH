module mux16_32_behav(
    output reg  [31:0] Y, 
    input  wire [31:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7,
    input  wire [31:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15,
    input  wire        S0, S1, S2, S3 
);

    always @(*) begin
        case({S3, S2, S1, S0})
            4'b0000: Y = IN0;  
            4'b0001: Y = IN1;
            4'b0010: Y = IN2;
            4'b0011: Y = IN3;
            4'b0100: Y = IN4;
            4'b0101: Y = IN5;
            4'b0110: Y = IN6;
            4'b0111: Y = IN7;
            4'b1000: Y = IN8;
            4'b1001: Y = IN9;
            4'b1010: Y = IN10;
            4'b1011: Y = IN11;
            4'b1100: Y = IN12;
            4'b1101: Y = IN13;
            4'b1110: Y = IN14;
            4'b1111: Y = IN15;
            default: Y = 32'bx; 
        endcase
    end

endmodule