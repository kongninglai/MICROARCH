/* AUTO GENERATED MOORE LOGIC */
module lru_store_per_set
(
  input     rst, clk, T1, T0, valid,
  output              V1, V0
);

wire Q4,Q3,Q2,Q1,Q0;
wire D4,D3,D2,D1,D0;

wire Q4_prebuf,Q3_prebuf,Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire Q4_bar_prebuf,Q3_bar_prebuf,Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;

bufferH16$  bufferH16$_V1(V1, Q4_prebuf);
bufferH16$  bufferH16$_V0(V0, Q3_prebuf);
bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

bufferH16$  bufferH16$_Q4(Q4, V1);
bufferH16$  bufferH16$_Q3(Q3, V0);

wire T1_buf16, T0_buf16;

bufferH16$  bufferH16$_T1_buf16(T1_buf16, T1);
bufferH16$  bufferH16$_T0_buf16(T0_buf16, T0);

/* Inverters */
wire Q4_bar;
wire valid_bar;
bufferHInv16$ bufferHInv16$_valid_bar(valid_bar, valid);
wire valid_buf64;
bufferHInv64$ bufferHInv64$_valid_buf64(valid_buf64, valid_bar);
wire Q0_bar;
wire T1_bar;
bufferHInv64$ bufferHInv64$_T1_bar(T1_bar, T1_buf16);
wire T0_bar;
bufferHInv64$ bufferHInv64$_T0_bar(T0_bar, T0_buf16);
wire Q2_bar;
wire Q3_bar;
wire Q1_bar;

/* Product Expressions */
wire nand_0_0_0_out;
wire nand_0_1_0_out;
wire nand_0_2_0_out;
nand2$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,nand_0_2_0_out);
and4$ nand_0_1_0(nand_0_1_0_out,Q1,Q0,T1_buf16,Q4_bar);
and4$ nand_0_2_0(nand_0_2_0_out,T0_bar,valid_buf64,Q3,Q2_bar);
wire nand_1_0_0_out;
wire nand_1_1_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,nand_1_1_0_out,Q4,Q3,Q2_bar);
and4$ nand_1_1_0(nand_1_1_0_out,Q0,T1_buf16,T0_buf16,valid_buf64);
wire nand_2_0_0_out;
wire nand_2_1_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,nand_2_1_0_out,Q4,Q3_bar,Q2_bar);
and4$ nand_2_1_0(nand_2_1_0_out,Q0,T1_buf16,T0_bar,valid_buf64);
wire nand_3_0_0_out;
wire nand_3_1_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,nand_3_1_0_out,Q4_bar,Q3_bar,Q2_bar);
and4$ nand_3_1_0(nand_3_1_0_out,Q1,Q0,T0_bar,valid_buf64);
wire nand_4_0_0_out;
wire nand_4_1_0_out;
nand4$ nand_4_0_0(nand_4_0_0_out,nand_4_1_0_out,Q4_bar,Q3_bar,Q1_bar);
and4$ nand_4_1_0(nand_4_1_0_out,Q0_bar,T1_bar,T0_bar,valid_buf64);
wire nand_5_0_0_out;
wire nand_5_1_0_out;
nand4$ nand_5_0_0(nand_5_0_0_out,nand_5_1_0_out,Q3,Q2_bar,Q1);
and4$ nand_5_1_0(nand_5_1_0_out,Q0,T1_bar,T0_buf16,valid_buf64);
wire nand_6_0_0_out;
wire nand_6_1_0_out;
nand4$ nand_6_0_0(nand_6_0_0_out,nand_6_1_0_out,Q4,Q2_bar,Q1);
and4$ nand_6_1_0(nand_6_1_0_out,Q0,T1_bar,T0_buf16,valid_buf64);
wire nand_7_0_0_out;
wire nand_7_1_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,nand_7_1_0_out,Q4_bar,Q3_bar,Q2);
and4$ nand_7_1_0(nand_7_1_0_out,Q1_bar,T1_bar,T0_buf16,valid_buf64);
wire nand_8_0_0_out;
wire nand_8_1_0_out;
nand4$ nand_8_0_0(nand_8_0_0_out,nand_8_1_0_out,Q2,Q1_bar,Q0);
and3$ nand_8_1_0(nand_8_1_0_out,T1_buf16,T0_buf16,valid_buf64);
wire nand_9_0_0_out;
wire nand_9_1_0_out;
nand4$ nand_9_0_0(nand_9_0_0_out,nand_9_1_0_out,Q4,Q2,Q1_bar);
and3$ nand_9_1_0(nand_9_1_0_out,Q0,T1_buf16,valid_buf64);
wire nand_10_0_0_out;
wire nand_10_1_0_out;
nand4$ nand_10_0_0(nand_10_0_0_out,nand_10_1_0_out,Q4_bar,Q3,Q2_bar);
and3$ nand_10_1_0(nand_10_1_0_out,Q1,T1_buf16,T0_buf16);
wire nand_11_0_0_out;
wire nand_11_1_0_out;
nand4$ nand_11_0_0(nand_11_0_0_out,nand_11_1_0_out,Q4,Q2,Q1_bar);
and3$ nand_11_1_0(nand_11_1_0_out,T1_buf16,T0_bar,valid_buf64);
wire nand_12_0_0_out;
wire nand_12_1_0_out;
nand4$ nand_12_0_0(nand_12_0_0_out,nand_12_1_0_out,Q3_bar,Q2,Q1_bar);
and3$ nand_12_1_0(nand_12_1_0_out,T1_bar,T0_bar,valid_buf64);
wire nand_13_0_0_out;
wire nand_13_1_0_out;
nand4$ nand_13_0_0(nand_13_0_0_out,nand_13_1_0_out,Q3,Q2_bar,Q1);
and3$ nand_13_1_0(nand_13_1_0_out,T1_bar,T0_buf16,valid_buf64);
wire nand_14_0_0_out;
wire nand_14_1_0_out;
nand4$ nand_14_0_0(nand_14_0_0_out,nand_14_1_0_out,Q4,Q2_bar,Q1);
and3$ nand_14_1_0(nand_14_1_0_out,T1_buf16,T0_bar,valid_buf64);
wire nand_15_0_0_out;
wire nand_15_1_0_out;
nand4$ nand_15_0_0(nand_15_0_0_out,nand_15_1_0_out,Q3,Q2,Q1_bar);
and3$ nand_15_1_0(nand_15_1_0_out,T1_bar,T0_buf16,valid_buf64);
wire nand_16_0_0_out;
wire nand_16_1_0_out;
nand4$ nand_16_0_0(nand_16_0_0_out,nand_16_1_0_out,Q3_bar,Q2_bar,Q1);
and2$ nand_16_1_0(nand_16_1_0_out,T1_buf16,T0_buf16);
wire nand_17_0_0_out;
wire nand_17_1_0_out;
nand4$ nand_17_0_0(nand_17_0_0_out,nand_17_1_0_out,Q4_bar,Q2_bar,Q1_bar);
and3$ nand_17_1_0(nand_17_1_0_out,Q0_bar,T1_bar,valid_buf64);
wire nand_18_0_0_out;
wire nand_18_1_0_out;
nand4$ nand_18_0_0(nand_18_0_0_out,nand_18_1_0_out,Q4_bar,Q3_bar,Q2_bar);
and2$ nand_18_1_0(nand_18_1_0_out,Q1,T0_buf16);
wire nand_19_0_0_out;
wire nand_19_1_0_out;
nand4$ nand_19_0_0(nand_19_0_0_out,nand_19_1_0_out,Q4_bar,Q2,Q1_bar);
and2$ nand_19_1_0(nand_19_1_0_out,T1_buf16,T0_bar);
wire nand_20_0_0_out;
wire nand_20_1_0_out;
nand4$ nand_20_0_0(nand_20_0_0_out,nand_20_1_0_out,Q4_bar,Q3,Q2_bar);
and3$ nand_20_1_0(nand_20_1_0_out,Q0_bar,T0_bar,valid_buf64);
wire nand_21_0_0_out;
wire nand_21_1_0_out;
nand4$ nand_21_0_0(nand_21_0_0_out,nand_21_1_0_out,Q3_bar,Q2_bar,Q1);
and3$ nand_21_1_0(nand_21_1_0_out,T1_bar,T0_bar,valid_buf64);
wire nand_22_0_0_out;
wire nand_22_1_0_out;
nand4$ nand_22_0_0(nand_22_0_0_out,nand_22_1_0_out,Q3,Q2,Q1_bar);
and2$ nand_22_1_0(nand_22_1_0_out,T1_bar,T0_bar);
wire nand_23_0_0_out;
wire nand_23_1_0_out;
nand4$ nand_23_0_0(nand_23_0_0_out,nand_23_1_0_out,Q3_bar,Q2_bar,Q0_bar);
and2$ nand_23_1_0(nand_23_1_0_out,T0_bar,valid_buf64);
wire nand_24_0_0_out;
wire nand_24_1_0_out;
nand4$ nand_24_0_0(nand_24_0_0_out,nand_24_1_0_out,Q4_bar,Q1_bar,Q0_bar);
and2$ nand_24_1_0(nand_24_1_0_out,T1_bar,valid_buf64);
wire nand_25_0_0_out;
wire nand_25_1_0_out;
nand4$ nand_25_0_0(nand_25_0_0_out,nand_25_1_0_out,Q4_bar,Q1_bar,Q0);
and2$ nand_25_1_0(nand_25_1_0_out,T1_bar,valid_buf64);
wire nand_26_0_0_out;
wire nand_26_1_0_out;
nand4$ nand_26_0_0(nand_26_0_0_out,nand_26_1_0_out,Q4,Q2_bar,Q1);
and2$ nand_26_1_0(nand_26_1_0_out,T1_bar,T0_bar);
wire nand_27_0_0_out;
wire nand_27_1_0_out;
nand4$ nand_27_0_0(nand_27_0_0_out,nand_27_1_0_out,Q4,Q3,Q2_bar);
and2$ nand_27_1_0(nand_27_1_0_out,Q1,T0_bar);
wire nand_28_0_0_out;
wire nand_28_1_0_out;
nand4$ nand_28_0_0(nand_28_0_0_out,nand_28_1_0_out,Q4_bar,Q3_bar,Q2_bar);
and2$ nand_28_1_0(nand_28_1_0_out,T1_bar,valid_buf64);
wire nand_29_0_0_out;
wire nand_29_1_0_out;
nand4$ nand_29_0_0(nand_29_0_0_out,nand_29_1_0_out,Q2_bar,Q0_bar,T1_bar);
and2$ nand_29_1_0(nand_29_1_0_out,T0_bar,valid_buf64);
wire nand_30_0_0_out;
wire nand_30_1_0_out;
nand4$ nand_30_0_0(nand_30_0_0_out,nand_30_1_0_out,Q3,Q2_bar,Q1);
and3$ nand_30_1_0(nand_30_1_0_out,T1_bar,T0_bar,valid_buf64);
wire nand_31_0_0_out;
wire nand_31_1_0_out;
nand4$ nand_31_0_0(nand_31_0_0_out,nand_31_1_0_out,Q4_bar,Q1_bar,T1_bar);
and2$ nand_31_1_0(nand_31_1_0_out,T0_bar,valid_buf64);
wire nand_32_0_0_out;
nand4$ nand_32_0_0(nand_32_0_0_out,Q4,Q3_bar,Q2_bar,T0_buf16);
wire nand_33_0_0_out;
nand4$ nand_33_0_0(nand_33_0_0_out,Q4_bar,Q3,Q1_bar,T1_buf16);
wire nand_34_0_0_out;
wire nand_34_1_0_out;
nand4$ nand_34_0_0(nand_34_0_0_out,nand_34_1_0_out,Q4_bar,Q2_bar,Q1_bar);
and2$ nand_34_1_0(nand_34_1_0_out,T0_bar,valid_buf64);
wire nand_35_0_0_out;
wire nand_35_1_0_out;
nand4$ nand_35_0_0(nand_35_0_0_out,nand_35_1_0_out,Q1_bar,Q0,T1_bar);
and2$ nand_35_1_0(nand_35_1_0_out,T0_bar,valid_buf64);
wire nand_36_0_0_out;
nand4$ nand_36_0_0(nand_36_0_0_out,Q4,Q2,Q1_bar,T1_bar);
wire nand_37_0_0_out;
wire nand_37_1_0_out;
nand4$ nand_37_0_0(nand_37_0_0_out,nand_37_1_0_out,Q4,Q1_bar,T1_bar);
and2$ nand_37_1_0(nand_37_1_0_out,T0_bar,valid_buf64);
wire nand_38_0_0_out;
nand4$ nand_38_0_0(nand_38_0_0_out,Q4,Q3,Q2_bar,Q1);
wire nand_39_0_0_out;
nand4$ nand_39_0_0(nand_39_0_0_out,Q4,Q3,Q1_bar,T0_bar);
wire nand_40_0_0_out;
nand4$ nand_40_0_0(nand_40_0_0_out,Q2_bar,Q0_bar,T1_bar,valid_buf64);
wire nand_41_0_0_out;
nand4$ nand_41_0_0(nand_41_0_0_out,Q4,Q3,Q1_bar,T1_bar);
wire nand_42_0_0_out;
nand3$ nand_42_0_0(nand_42_0_0_out,Q2,Q1_bar,valid_bar);
wire nand_43_0_0_out;
nand3$ nand_43_0_0(nand_43_0_0_out,Q1_bar,Q0,valid_bar);
wire nand_44_0_0_out;
nand3$ nand_44_0_0(nand_44_0_0_out,Q3,Q1_bar,valid_bar);
wire nand_45_0_0_out;
nand3$ nand_45_0_0(nand_45_0_0_out,Q2_bar,Q0,valid_bar);
wire nand_46_0_0_out;
nand3$ nand_46_0_0(nand_46_0_0_out,Q4,Q2_bar,valid_bar);
wire nand_47_0_0_out;
nand3$ nand_47_0_0(nand_47_0_0_out,Q4,Q2,Q1_bar);
wire nand_48_0_0_out;
nand3$ nand_48_0_0(nand_48_0_0_out,Q2_bar,Q1,valid_bar);
wire nand_49_0_0_out;
nand3$ nand_49_0_0(nand_49_0_0_out,Q3,Q2_bar,valid_bar);
wire nand_50_0_0_out;
nand4$ nand_50_0_0(nand_50_0_0_out,Q2_bar,Q1_bar,T1_bar,valid_buf64);

/* Sum Expressions */
wire nand_0_1_1_out;
wire nand_0_2_1_out;
wire nand_0_3_1_out;
nand4$ nand_0_0_1(D4,nand_0_1_1_out,nand_0_2_1_out,nand_0_3_1_out,nand_15_0_0_out);
and4$ nand_0_1_1(nand_0_1_1_out,nand_12_0_0_out,nand_21_0_0_out,nand_27_0_0_out,nand_32_0_0_out);
and4$ nand_0_2_1(nand_0_2_1_out,nand_13_0_0_out,nand_37_0_0_out,nand_39_0_0_out,nand_41_0_0_out);
and2$ nand_0_3_1(nand_0_3_1_out,nand_46_0_0_out,nand_47_0_0_out);
wire nand_1_1_1_out;
wire nand_1_2_1_out;
wire nand_1_3_1_out;
wire nand_1_4_1_out;
nand4$ nand_1_0_1(D3,nand_1_1_1_out,nand_1_2_1_out,nand_1_3_1_out,nand_1_4_1_out);
and4$ nand_1_1_1(nand_1_1_1_out,nand_0_0_0_out,nand_14_0_0_out,nand_15_0_0_out,nand_20_0_0_out);
and4$ nand_1_2_1(nand_1_2_1_out,nand_10_0_0_out,nand_30_0_0_out,nand_31_0_0_out,nand_33_0_0_out);
and4$ nand_1_3_1(nand_1_3_1_out,nand_11_0_0_out,nand_38_0_0_out,nand_39_0_0_out,nand_41_0_0_out);
and2$ nand_1_4_1(nand_1_4_1_out,nand_44_0_0_out,nand_49_0_0_out);
wire nand_2_1_1_out;
wire nand_2_2_1_out;
wire nand_2_3_1_out;
nand4$ nand_2_0_1(D2,nand_2_1_1_out,nand_2_2_1_out,nand_2_3_1_out,nand_3_0_0_out);
and4$ nand_2_1_1(nand_2_1_1_out,nand_0_0_0_out,nand_5_0_0_out,nand_6_0_0_out,nand_7_0_0_out);
and4$ nand_2_2_1(nand_2_2_1_out,nand_2_0_0_out,nand_19_0_0_out,nand_22_0_0_out,nand_25_0_0_out);
and3$ nand_2_3_1(nand_2_3_1_out,nand_35_0_0_out,nand_36_0_0_out,nand_42_0_0_out);
wire nand_3_1_1_out;
wire nand_3_2_1_out;
wire nand_3_3_1_out;
nand4$ nand_3_0_1(D1,nand_3_1_1_out,nand_3_2_1_out,nand_3_3_1_out,nand_8_0_0_out);
and4$ nand_3_1_1(nand_3_1_1_out,nand_1_0_0_out,nand_9_0_0_out,nand_10_0_0_out,nand_16_0_0_out);
and4$ nand_3_2_1(nand_3_2_1_out,nand_4_0_0_out,nand_17_0_0_out,nand_18_0_0_out,nand_26_0_0_out);
and4$ nand_3_3_1(nand_3_3_1_out,nand_27_0_0_out,nand_29_0_0_out,nand_30_0_0_out,nand_48_0_0_out);
wire nand_4_1_1_out;
wire nand_4_2_1_out;
wire nand_4_3_1_out;
wire nand_4_4_1_out;
nand4$ nand_4_0_1(D0,nand_4_1_1_out,nand_4_2_1_out,nand_4_3_1_out,nand_4_4_1_out);
and4$ nand_4_1_1(nand_4_1_1_out,nand_7_0_0_out,nand_23_0_0_out,nand_24_0_0_out,nand_28_0_0_out);
and4$ nand_4_2_1(nand_4_2_1_out,nand_20_0_0_out,nand_30_0_0_out,nand_34_0_0_out,nand_35_0_0_out);
and4$ nand_4_3_1(nand_4_3_1_out,nand_21_0_0_out,nand_37_0_0_out,nand_40_0_0_out,nand_43_0_0_out);
and2$ nand_4_4_1(nand_4_4_1_out,nand_45_0_0_out,nand_50_0_0_out);

/* State Flip Flops */
wire  D0_gated_rst,
      D1_gated_rst,
      D2_gated_rst,
      D3_gated_rst,
      D4_gated_rst;

mux2$   mux2$_D0_gated_rst(D0_gated_rst, 1'b0, D0, rst);
mux2$   mux2$_D1_gated_rst(D1_gated_rst, 1'b0, D1, rst);
mux2$   mux2$_D2_gated_rst(D2_gated_rst, 1'b0, D2, rst);
mux2$   mux2$_D3_gated_rst(D3_gated_rst, 1'b0, D3, rst);
mux2$   mux2$_D4_gated_rst(D4_gated_rst, 1'b0, D4, rst);

dff$ dff_0(clk, D0_gated_rst, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1_gated_rst, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2_gated_rst, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);
dff$ dff_3(clk, D3_gated_rst, Q3_prebuf, Q3_bar_prebuf, rst, 1'b1);
dff$ dff_4(clk, D4_gated_rst, Q4_prebuf, Q4_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q4_bar(Q4_bar, Q4_bar_prebuf);
bufferH16$  bufferH16$_Q3_bar(Q3_bar, Q3_bar_prebuf);
bufferH64$  bufferH64$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH64$  bufferH64$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule