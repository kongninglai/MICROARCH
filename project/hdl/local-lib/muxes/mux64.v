module mux64 (
  output          outb,
  input           in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,
                  in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,in30,in31,
                  in32,in33,in34,in35,in36,in37,in38,in39,in40,in41,in42,in43,in44,in45,in46,in47,
                  in48,in49,in50,in51,in52,in53,in54,in55,in56,in57,in58,in59,in60,in61,in62,in63,
                  s0,s1,s2,s3,s4,s5
);

wire    mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out,
        mux4$_4_out, mux4$_5_out, mux4$_6_out, mux4$_7_out,
        mux4$_8_out, mux4$_9_out, mux4$_10_out, mux4$_11_out,
        mux4$_12_out, mux4$_13_out, mux4$_14_out, mux4$_15_out,
        mux4$_16_out, mux4$_17_out;

wire    s0_buf16, s1_buf16;

bufferH16$    bufferH16$_s0_buf16(s0_buf16, s0);
bufferH16$    bufferH16$_s1_buf16(s1_buf16, s1);

mux4$   mux4$_0(mux4$_0_out, in0, in1, in2, in3, s0_buf16, s1_buf16);
mux4$   mux4$_1(mux4$_1_out, in4, in5, in6, in7, s0_buf16, s1_buf16);
mux4$   mux4$_2(mux4$_2_out, in8, in9, in10, in11, s0_buf16, s1_buf16);
mux4$   mux4$_3(mux4$_3_out, in12, in13, in14, in15, s0_buf16, s1_buf16);
mux4$   mux4$_4(mux4$_4_out, in16, in17, in18, in19, s0_buf16, s1_buf16);
mux4$   mux4$_5(mux4$_5_out, in20, in21, in22, in23, s0_buf16, s1_buf16);
mux4$   mux4$_6(mux4$_6_out, in24, in25, in26, in27, s0_buf16, s1_buf16);
mux4$   mux4$_7(mux4$_7_out, in28, in29, in30, in31, s0_buf16, s1_buf16);
mux4$   mux4$_8(mux4$_8_out, in32, in33, in34, in35, s0_buf16, s1_buf16);
mux4$   mux4$_9(mux4$_9_out, in36, in37, in38, in39, s0_buf16, s1_buf16);
mux4$   mux4$_10(mux4$_10_out, in40, in41, in42, in43, s0_buf16, s1_buf16);
mux4$   mux4$_11(mux4$_11_out, in44, in45, in46, in47, s0_buf16, s1_buf16);
mux4$   mux4$_12(mux4$_12_out, in48, in49, in50, in51, s0_buf16, s1_buf16);
mux4$   mux4$_13(mux4$_13_out, in52, in53, in54, in55, s0_buf16, s1_buf16);
mux4$   mux4$_14(mux4$_14_out, in56, in57, in58, in59, s0_buf16, s1_buf16);
mux4$   mux4$_15(mux4$_15_out, in60, in61, in62, in63, s0_buf16, s1_buf16);

mux4$   mux4$_16(mux4$_16_out, mux4$_0_out, mux4$_1_out, mux4$_2_out, mux4$_3_out, s2, s3);
mux4$   mux4$_17(mux4$_17_out, mux4$_4_out, mux4$_5_out, mux4$_6_out, mux4$_7_out, s2, s3);
mux4$   mux4$_18(mux4$_18_out, mux4$_8_out, mux4$_9_out, mux4$_10_out, mux4$_11_out, s2, s3);
mux4$   mux4$_19(mux4$_19_out, mux4$_12_out, mux4$_13_out, mux4$_14_out, mux4$_15_out, s2, s3);

mux4$   mux4$_20(mux4$_20_out, mux4$_16_out, mux4$_17_out, mux4$_18_out, mux4$_19_out, s4, s5);

mux2$   mux2$_0(outb, mux4$_20_out, 1'b0, 1'b0); // final selection

endmodule
