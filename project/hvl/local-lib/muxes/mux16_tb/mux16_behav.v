module mux16_behav (
  output  reg     outb,
  input           in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,s0,s1,s2,s3
);

always @(*) begin
  case ({s3, s2, s1, s0})
    4'b0000: outb = in0;
    4'b0001: outb = in1;
    4'b0010: outb = in2;
    4'b0011: outb = in3;
    4'b0100: outb = in4;
    4'b0101: outb = in5;
    4'b0110: outb = in6;
    4'b0111: outb = in7;
    4'b1000: outb = in8;
    4'b1001: outb = in9;
    4'b1010: outb = in10;
    4'b1011: outb = in11;
    4'b1100: outb = in12;
    4'b1101: outb = in13;
    4'b1110: outb = in14;
    4'b1111: outb = in15;
  endcase
end

endmodule