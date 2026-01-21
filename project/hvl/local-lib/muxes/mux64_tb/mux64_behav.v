module mux64_behav (
  output reg      outb,
  input           in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
                  in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,
                  in32,in33,in34,in35,in36,in37,in38,in39,in40,in41,in42,in43,in44,in45,in46,in47,
                  in48,in49,in50,in51,in52,in53,in54,in55,in56,in57,in58,in59,in60,in61,in62,in63,
                  s0,s1,s2,s3,s4,s5
);

always @(*) begin
  case ({s5, s4, s3, s2, s1, s0})
    6'b000000: outb = in0;
    6'b000001: outb = in1;
    6'b000010: outb = in2;
    6'b000011: outb = in3;
    6'b000100: outb = in4;
    6'b000101: outb = in5;
    6'b000110: outb = in6;
    6'b000111: outb = in7;
    6'b001000: outb = in8;
    6'b001001: outb = in9;
    6'b001010: outb = in10;
    6'b001011: outb = in11;
    6'b001100: outb = in12;
    6'b001101: outb = in13;
    6'b001110: outb = in14;
    6'b001111: outb = in15;
    6'b010000: outb = in16;
    6'b010001: outb = in17;
    6'b010010: outb = in18;
    6'b010011: outb = in19;
    6'b010100: outb = in20;
    6'b010101: outb = in21;
    6'b010110: outb = in22;
    6'b010111: outb = in23;
    6'b011000: outb = in24;
    6'b011001: outb = in25;
    6'b011010: outb = in26;
    6'b011011: outb = in27;
    6'b011100: outb = in28;
    6'b011101: outb = in29;
    6'b011110: outb = in30;
    6'b011111: outb = in31;
    6'b100000: outb = in32;
    6'b100001: outb = in33;
    6'b100010: outb = in34;
    6'b100011: outb = in35;
    6'b100100: outb = in36;
    6'b100101: outb = in37;
    6'b100110: outb = in38;
    6'b100111: outb = in39;
    6'b101000: outb = in40;
    6'b101001: outb = in41;
    6'b101010: outb = in42;
    6'b101011: outb = in43;
    6'b101100: outb = in44;
    6'b101101: outb = in45;
    6'b101110: outb = in46;
    6'b101111: outb = in47;
    6'b110000: outb = in48;
    6'b110001: outb = in49;
    6'b110010: outb = in50;
    6'b110011: outb = in51;
    6'b110100: outb = in52;
    6'b110101: outb = in53;
    6'b110110: outb = in54;
    6'b110111: outb = in55;
    6'b111000: outb = in56;
    6'b111001: outb = in57;
    6'b111010: outb = in58;
    6'b111011: outb = in59;
    6'b111100: outb = in60;
    6'b111101: outb = in61;
    6'b111110: outb = in62;
    6'b111111: outb = in63;
  endcase
end

endmodule
