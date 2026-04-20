module mux3_onehot_tb_behav (
    input wire [2:0] in_sel, //one hot select signal
    input wire [31:0] in0, in1, in2, //inputs
    output reg [31:0] out
);

  always @(*) begin
    case (in_sel)
      3'b001: out = in0;
      3'b010: out = in1;
      3'b100: out = in2;
      default: out = 32'd0; 
    endcase
  end

endmodule

