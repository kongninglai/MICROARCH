// Author: VR

module mux8_16b #(
  parameter WIDTH=16
) (
  output  [WIDTH-1:0] outb,
  input   [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7,
  input               s0,s1,s2
);

wire    [WIDTH-1:0] mux4$_0_out, mux4$_1_out;

mux4_16$   mux4$_0(mux4$_0_out, in0, in1, in2, in3, s0, s1);
mux4_16$   mux4$_1(mux4$_1_out, in4, in5, in6, in7, s0, s1);
mux2_16$   mux2$_0(outb, mux4$_0_out, mux4$_1_out, s2);

endmodule