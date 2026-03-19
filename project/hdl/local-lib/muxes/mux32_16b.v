// Author: VR

module mux32_16b #(
  parameter WIDTH=16
) (
  output [WIDTH-1:0]   outb,
  input  [WIDTH-1:0]   in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
                       in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,
  input                s0,s1,s2,s3,s4
);

wire    [WIDTH-1:0] mux4_16$_0_out, mux4_16$_1_out, mux4_16$_2_out, mux4_16$_3_out,
                    mux4_16$_4_out, mux4_16$_5_out, mux4_16$_6_out, mux4_16$_7_out,
                    mux4_16$_8_out, mux4_16$_9_out;

wire    s0_buf16, s1_buf16;

bufferH16$    bufferH16$_s0_buf16(s0_buf16, s0);
bufferH16$    bufferH16$_s1_buf16(s1_buf16, s1);

mux4_16$   mux4_16$_0(mux4_16$_0_out, in0, in1, in2, in3, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_1(mux4_16$_1_out, in4, in5, in6, in7, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_2(mux4_16$_2_out, in8, in9, in10, in11, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_3(mux4_16$_3_out, in12, in13, in14, in15, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_4(mux4_16$_4_out, in16, in17, in18, in19, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_5(mux4_16$_5_out, in20, in21, in22, in23, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_6(mux4_16$_6_out, in24, in25, in26, in27, s0_buf16, s1_buf16);
mux4_16$   mux4_16$_7(mux4_16$_7_out, in28, in29, in30, in31, s0_buf16, s1_buf16);

mux4_16$   mux4_16$_8(mux4_16$_8_out, mux4_16$_0_out, mux4_16$_1_out, mux4_16$_2_out, mux4_16$_3_out, s2, s3);
mux4_16$   mux4_16$_9(mux4_16$_9_out, mux4_16$_4_out, mux4_16$_5_out, mux4_16$_6_out, mux4_16$_7_out, s2, s3);

mux2_16$   mux2_16$_0(outb, mux4_16$_8_out, mux4_16$_9_out, s4);

endmodule
