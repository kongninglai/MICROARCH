module mux11_onehot_slice_behav (
    input wire [10:0] in_sel, //one hot select signal
    input wire in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, //inputs
    output reg out
);

always @(*) begin
  case (in_sel)
    11'b00000000001: out = in0;
    11'b00000000010: out = in1;
    11'b00000000100: out = in2;
    11'b00000001000: out = in3;
    11'b00000010000: out = in4;
    11'b00000100000: out = in5;
    11'b00001000000: out = in6;
    11'b00010000000: out = in7;
    11'b00100000000: out = in8;
    11'b01000000000: out = in9;
    11'b10000000000: out = in10;
    default:         out = 1'b0; 
  endcase
end

endmodule

