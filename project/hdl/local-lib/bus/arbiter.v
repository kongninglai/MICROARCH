module arbiter (
  input               rst, clk,
                      DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_MEM_RD_RQ, DC_DMA_RD_RQ, DC_KB_RD_KBDR_RQ, DC_KB_RD_KBSR_RQ, IC_MEM_RD_RQ, DMA_MEM_WR_RQ,
  output              DC_WR_ACK, DC_RD_ACK, IC_RD_ACK, DMA_WR_ACK, 
                      MEM_WR, MEM_RD, DMA_WR, DMA_RD, KB_RD_KBDR, KB_RD_KBSR
);

wire    Q2,Q1,Q0;
wire    D2,D1,D0;

wire    [2:0]   STATE       = {Q2,Q1,Q0};
wire    [2:0]   NEXT_STATE  = {D2,D1,D0};

wire    [5:0]   W_CT_WR_DIS, W_CT_RD_DIS; 
assign          W_CT_WR_DIS     = V_CT_WR_DIS; 
assign          W_CT_RD_DIS     = V_CT_RD_DIS;

wire    [7:0] counter, inc_counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(inc_counter));

wire    state_change;
neq_3b  neq_3b_state_change(.in0({Q2,Q1,Q0}), .in1({D2,D1,D0}), .neq(state_change));

wire    idling;
nor3$   nor3$_idling(idling, Q2, Q1, Q0);

wire    zero_counter;
or2$    or2$_zero_counter(zero_counter, state_change, idling);

mux2$   mux2$_next_counter[7:0](next_counter, inc_counter, 8'd0, zero_counter);

dff8$   dff_counter(clk, next_counter, counter, , rst, 1'b1);

wire    CT_WR, CT_RD;

eq_6b   done_WR (.in0(counter[5:0]), .in1(W_CT_WR_DIS), .eq(CT_WR));
eq_6b   done_RD (.in0(counter[5:0]), .in1(W_CT_RD_DIS), .eq(CT_RD));

/* Inverters */
wire DC_MEM_WR_RQ_bar;
inv1$ inv_0(DC_MEM_WR_RQ_bar, DC_MEM_WR_RQ);
wire Q0_bar;
wire Q2_bar;
wire DC_KB_RD_KBSR_RQ_bar;
inv1$ inv_3(DC_KB_RD_KBSR_RQ_bar, DC_KB_RD_KBSR_RQ);
wire CT_WR_bar;
inv1$ inv_4(CT_WR_bar, CT_WR);
wire Q1_bar;
wire CT_RD_bar;
inv1$ inv_6(CT_RD_bar, CT_RD);
wire DC_DMA_RD_RQ_bar;
inv1$ inv_7(DC_DMA_RD_RQ_bar, DC_DMA_RD_RQ);
wire IC_MEM_RD_RQ_bar;
inv1$ inv_8(IC_MEM_RD_RQ_bar, IC_MEM_RD_RQ);
wire DC_MEM_RD_RQ_bar;
inv1$ inv_9(DC_MEM_RD_RQ_bar, DC_MEM_RD_RQ);
wire DC_KB_RD_KBDR_RQ_bar;
inv1$ inv_10(DC_KB_RD_KBDR_RQ_bar, DC_KB_RD_KBDR_RQ);
wire DC_DMA_WR_RQ_bar;
inv1$ inv_11(DC_DMA_WR_RQ_bar, DC_DMA_WR_RQ);

/* Product Expressions */
wire and_0_0_out;
wire and_0_1_out;
wire and_0_2_out;
wire and_0_3_out;
and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,Q2_bar);
and4$ and_0_1(and_0_1_out,Q1_bar,Q0_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and4$ and_0_2(and_0_2_out,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar,DC_KB_RD_KBDR_RQ_bar,DC_KB_RD_KBSR_RQ_bar);
and2$ and_0_3(and_0_3_out,IC_MEM_RD_RQ_bar,DMA_MEM_WR_RQ);
wire and_1_0_out;
wire and_1_1_out;
wire and_1_2_out;
and4$ and_1_0(and_1_0_out,and_1_1_out,and_1_2_out,Q2_bar,Q1_bar);
and4$ and_1_1(and_1_1_out,Q0_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar,DC_MEM_RD_RQ_bar);
and4$ and_1_2(and_1_2_out,DC_DMA_RD_RQ_bar,DC_KB_RD_KBDR_RQ_bar,DC_KB_RD_KBSR_RQ_bar,IC_MEM_RD_RQ);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2_bar,Q1,DC_KB_RD_KBDR_RQ,DC_KB_RD_KBSR_RQ_bar);
wire and_3_0_out;
wire and_3_1_out;
and4$ and_3_0(and_3_0_out,and_3_1_out,Q2_bar,Q1_bar,Q0_bar);
and3$ and_3_1(and_3_1_out,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar,DC_KB_RD_KBSR_RQ);
wire and_4_0_out;
wire and_4_1_out;
and4$ and_4_0(and_4_0_out,and_4_1_out,Q2_bar,Q1_bar,Q0_bar);
and3$ and_4_1(and_4_1_out,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar,DC_DMA_RD_RQ);
wire and_5_0_out;
wire and_5_1_out;
and4$ and_5_0(and_5_0_out,and_5_1_out,Q2_bar,Q1_bar,Q0_bar);
and3$ and_5_1(and_5_1_out,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar,DC_MEM_RD_RQ);
wire and_6_0_out;
wire and_6_1_out;
and4$ and_6_0(and_6_0_out,and_6_1_out,Q2_bar,Q1_bar,Q0_bar);
and3$ and_6_1(and_6_1_out,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar,DC_KB_RD_KBDR_RQ);
wire and_7_0_out;
and3$ and_7_0(and_7_0_out,Q2,Q1_bar,CT_RD_bar);
wire and_8_0_out;
and3$ and_8_0(and_8_0_out,Q1,Q0_bar,CT_WR_bar);
wire and_9_0_out;
and4$ and_9_0(and_9_0_out,Q2_bar,Q1_bar,Q0_bar,DC_DMA_WR_RQ);
wire and_10_0_out;
and4$ and_10_0(and_10_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_WR_RQ);
wire and_11_0_out;
wire and_11_1_out;
and4$ and_11_0(and_11_0_out,and_11_1_out,Q2_bar,Q1,Q0);
and2$ and_11_1(and_11_1_out,DC_KB_RD_KBDR_RQ_bar,DC_KB_RD_KBSR_RQ);
wire and_12_0_out;
and4$ and_12_0(and_12_0_out,Q2_bar,Q1,Q0,DC_KB_RD_KBDR_RQ);
wire and_13_0_out;
and4$ and_13_0(and_13_0_out,Q2_bar,Q1,Q0,DC_DMA_RD_RQ);
wire and_14_0_out;
and4$ and_14_0(and_14_0_out,Q2_bar,Q1,Q0,DC_MEM_RD_RQ);
wire and_15_0_out;
and4$ and_15_0(and_15_0_out,Q2_bar,Q1_bar,Q0,DC_DMA_WR_RQ);
wire and_16_0_out;
and4$ and_16_0(and_16_0_out,Q2_bar,Q1_bar,Q0,DC_MEM_WR_RQ);
wire and_17_0_out;
and3$ and_17_0(and_17_0_out,Q2,Q1_bar,Q0);
wire and_18_0_out;
and3$ and_18_0(and_18_0_out,Q2,Q1,Q0_bar);
wire and_19_0_out;
and2$ and_19_0(and_19_0_out,Q1_bar,Q0_bar);
wire and_20_0_out;
and2$ and_20_0(and_20_0_out,Q2_bar,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
wire or_0_2_out;
or4$ or_0_0(D2,or_0_1_out,or_0_2_out,and_0_0_out,and_1_0_out);
or4$ or_0_1(or_0_1_out,and_7_0_out,and_11_0_out,and_12_0_out,and_13_0_out);
or2$ or_0_2(or_0_2_out,and_14_0_out,and_17_0_out);
wire or_1_1_out;
wire or_1_2_out;
or4$ or_1_0(D1,or_1_1_out,or_1_2_out,and_0_0_out,and_3_0_out);
or4$ or_1_1(or_1_1_out,and_4_0_out,and_5_0_out,and_6_0_out,and_8_0_out);
or3$ or_1_2(or_1_2_out,and_15_0_out,and_16_0_out,and_18_0_out);
wire or_2_1_out;
or4$ or_2_0(D0,or_2_1_out,and_1_0_out,and_3_0_out,and_4_0_out);
or4$ or_2_1(or_2_1_out,and_5_0_out,and_6_0_out,and_9_0_out,and_10_0_out);
or2$ or_3_0(DC_WR_ACK,and_15_0_out,and_16_0_out);
or4$ or_4_0(DC_RD_ACK,and_11_0_out,and_12_0_out,and_13_0_out,and_14_0_out);
buffer$ buffer_or_5_0(IC_RD_ACK,and_17_0_out);
buffer$ buffer_or_6_0(DMA_WR_ACK,and_18_0_out);
wire or_7_1_out;
wire or_7_2_out;
or4$ or_7_0(MEM_WR,or_7_1_out,or_7_2_out,and_11_0_out,and_12_0_out);
or4$ or_7_1(or_7_1_out,and_13_0_out,and_14_0_out,and_15_0_out,and_17_0_out);
or2$ or_7_2(or_7_2_out,and_19_0_out,and_20_0_out);
wire or_8_1_out;
wire or_8_2_out;
or4$ or_8_0(MEM_RD,or_8_1_out,or_8_2_out,and_11_0_out,and_12_0_out);
or4$ or_8_1(or_8_1_out,and_13_0_out,and_15_0_out,and_16_0_out,and_18_0_out);
or2$ or_8_2(or_8_2_out,and_19_0_out,and_20_0_out);
wire or_9_1_out;
wire or_9_2_out;
or4$ or_9_0(DMA_WR,or_9_1_out,or_9_2_out,and_11_0_out,and_12_0_out);
or4$ or_9_1(or_9_1_out,and_13_0_out,and_14_0_out,and_16_0_out,and_17_0_out);
or3$ or_9_2(or_9_2_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_10_1_out;
wire or_10_2_out;
or4$ or_10_0(DMA_RD,or_10_1_out,or_10_2_out,and_11_0_out,and_12_0_out);
or4$ or_10_1(or_10_1_out,and_14_0_out,and_15_0_out,and_16_0_out,and_17_0_out);
or3$ or_10_2(or_10_2_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_11_1_out;
wire or_11_2_out;
or4$ or_11_0(KB_RD_KBDR,or_11_1_out,or_11_2_out,and_11_0_out,and_13_0_out);
or4$ or_11_1(or_11_1_out,and_14_0_out,and_15_0_out,and_16_0_out,and_17_0_out);
or3$ or_11_2(or_11_2_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_12_1_out;
wire or_12_2_out;
or4$ or_12_0(KB_RD_KBSR,or_12_1_out,or_12_2_out,and_2_0_out,and_13_0_out);
or4$ or_12_1(or_12_1_out,and_14_0_out,and_15_0_out,and_16_0_out,and_17_0_out);
or3$ or_12_2(or_12_2_out,and_18_0_out,and_19_0_out,and_20_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule