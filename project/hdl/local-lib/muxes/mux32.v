module mux32 (
  output          outb,
  input           in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
                  in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,
                  s0,s1,s2,s3,s4
);

wire    mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out,
        mux4$_4_out, mux4$_5_out, mux4$_6_out, mux4$_7_out,
        mux4$_8_out, mux4$_9_out;

mux4$   mux4$_0(mux4$_0_out, in0, in1, in2, in3, s0, s1);
mux4$   mux4$_1(mux4$_1_out, in4, in5, in6, in7, s0, s1);
mux4$   mux4$_2(mux4$_2_out, in8, in9, in10, in11, s0, s1);
mux4$   mux4$_3(mux4$_3_out, in12, in13, in14, in15, s0, s1);
mux4$   mux4$_4(mux4$_4_out, in16, in17, in18, in19, s0, s1);
mux4$   mux4$_5(mux4$_5_out, in20, in21, in22, in23, s0, s1);
mux4$   mux4$_6(mux4$_6_out, in24, in25, in26, in27, s0, s1);
mux4$   mux4$_7(mux4$_7_out, in28, in29, in30, in31, s0, s1);

mux4$   mux4$_8(mux4$_8_out, mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out, s2, s3);
mux4$   mux4$_9(mux4$_9_out, mux4$_4_out, mux4$_5_out, mux4$_6_out, mux4$_7_out, s2, s3);

mux2$   mux2$_0(outb, mux4$_8_out, mux4$_9_out, s4);

endmodule
