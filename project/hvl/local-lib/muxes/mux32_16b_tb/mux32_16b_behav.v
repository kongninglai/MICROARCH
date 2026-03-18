module mux32_16b_behav #(
  parameter WIDTH=16
) (
  output  reg [WIDTH-1:0] outb,
  input       [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
                          in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,
  input                   s0,s1,s2,s3,s4
);

always @(*) begin
  case ({s4, s3, s2, s1, s0})
    5'b00000: outb = in0;
    5'b00001: outb = in1;
    5'b00010: outb = in2;
    5'b00011: outb = in3;
    5'b00100: outb = in4;
    5'b00101: outb = in5;
    5'b00110: outb = in6;
    5'b00111: outb = in7;
    5'b01000: outb = in8;
    5'b01001: outb = in9;
    5'b01010: outb = in10;
    5'b01011: outb = in11;
    5'b01100: outb = in12;
    5'b01101: outb = in13;
    5'b01110: outb = in14;
    5'b01111: outb = in15;
    5'b10000: outb = in16;
    5'b10001: outb = in17;
    5'b10010: outb = in18;
    5'b10011: outb = in19;
    5'b10100: outb = in20;
    5'b10101: outb = in21;
    5'b10110: outb = in22;
    5'b10111: outb = in23;
    5'b11000: outb = in24;
    5'b11001: outb = in25;
    5'b11010: outb = in26;
    5'b11011: outb = in27;
    5'b11100: outb = in28;
    5'b11101: outb = in29;
    5'b11110: outb = in30;
    5'b11111: outb = in31;
  endcase
end

endmodule