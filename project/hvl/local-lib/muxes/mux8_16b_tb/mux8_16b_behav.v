module mux8_16b_behav #(
  parameter WIDTH=16
) (
  output  reg [WIDTH-1:0] outb,
  input       [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7,
  input                   s0,s1,s2
);

always @(*) begin
  case ({s2, s1, s0})
    3'b000: outb = in0;
    3'b001: outb = in1;
    3'b010: outb = in2;
    3'b011: outb = in3;
    3'b100: outb = in4;
    3'b101: outb = in5;
    3'b110: outb = in6;
    3'b111: outb = in7;
  endcase
end

endmodule