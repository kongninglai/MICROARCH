module mux3_onehot_slice_behav (
    input wire [2:0] in_sel, //one hot select signal
    input wire in0, in1, in2, //inputs
    output reg out
);

  always @(*) begin
    case (in_sel)
      3'b001: out = in0;
      3'b010: out = in1;
      3'b100: out = in2;
      default: out = 1'b0; 
    endcase
  end
endmodule

