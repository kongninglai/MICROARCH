module arbiter (
  input               rst, clk,
                      MEM_BUSY,
                      DMAC_BUSY,
                      KB_BUSY,
                      DC_MEM_RD_RQ,
                      DC_DMA_RD_RQ,
                      DC_KB_RD_RQ,
                      DC_MEM_WR_RQ,
                      DC_DMA_WR_RQ,
                      DC_KB_WR_RQ,
                      IC_MEM_RD_RQ,
                      DMA_MEM_WR_RQ,
  output              DC_MEM_RD_ACK_BUS   ,
                      DC_DMA_RD_ACK_BUS   ,
                      DC_KB_RD_ACK_BUS    ,
                      DC_MEM_WR_ACK_BUS   ,
                      DC_DMA_WR_ACK_BUS   ,
                      DC_KB_WR_ACK_BUS    ,
                      IC_MEM_RD_ACK_BUS   ,
                      DMA_MEM_WR_ACK_BUS   
);

wire    Q2,Q1,Q0;
wire    D2,D1,D0;

wire    [2:0]   STATE       = {Q2,Q1,Q0};
wire    [2:0]   NEXT_STATE  = {D2,D1,D0};

wire        Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;

bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

wire    NOBODY_BUSY;

nor3$   nor3$_NOBODY_BUSY(NOBODY_BUSY,
                          MEM_BUSY,
                          DMAC_BUSY,
                          KB_BUSY);

tristate_bus_driver1$ tristate_bus_driver1$_DC_MEM_RD_ACK_BUS     (.enbar(1'b0), .in(DC_MEM_RD_ACK ), .out(DC_MEM_RD_ACK_BUS ));
tristate_bus_driver1$ tristate_bus_driver1$_DC_DMA_RD_ACK_BUS     (.enbar(1'b0), .in(DC_DMA_RD_ACK ), .out(DC_DMA_RD_ACK_BUS ));
tristate_bus_driver1$ tristate_bus_driver1$_DC_KB_RD_ACK_BUS      (.enbar(1'b0), .in(DC_KB_RD_ACK  ), .out(DC_KB_RD_ACK_BUS  ));
tristate_bus_driver1$ tristate_bus_driver1$_DC_MEM_WR_ACK_BUS     (.enbar(1'b0), .in(DC_MEM_WR_ACK ), .out(DC_MEM_WR_ACK_BUS ));
tristate_bus_driver1$ tristate_bus_driver1$_DC_DMA_WR_ACK_BUS     (.enbar(1'b0), .in(DC_DMA_WR_ACK ), .out(DC_DMA_WR_ACK_BUS ));
tristate_bus_driver1$ tristate_bus_driver1$_DC_KB_WR_ACK_BUS      (.enbar(1'b0), .in(DC_KB_WR_ACK  ), .out(DC_KB_WR_ACK_BUS  ));
tristate_bus_driver1$ tristate_bus_driver1$_IC_MEM_RD_ACK_BUS     (.enbar(1'b0), .in(IC_MEM_RD_ACK ), .out(IC_MEM_RD_ACK_BUS ));
tristate_bus_driver1$ tristate_bus_driver1$_DMA_MEM_WR_ACK_BUS    (.enbar(1'b0), .in(DMA_MEM_WR_ACK), .out(DMA_MEM_WR_ACK_BUS));

/* Inverters */
wire Q0_bar;
wire DC_KB_RD_RQ_bar;
inv1$ inv_1(DC_KB_RD_RQ_bar, DC_KB_RD_RQ);
wire DC_MEM_RD_RQ_bar;
inv1$ inv_2(DC_MEM_RD_RQ_bar, DC_MEM_RD_RQ);
wire IC_MEM_RD_RQ_bar;
inv1$ inv_3(IC_MEM_RD_RQ_bar, IC_MEM_RD_RQ);
wire DC_MEM_WR_RQ_bar;
inv1$ inv_4(DC_MEM_WR_RQ_bar, DC_MEM_WR_RQ);
wire Q1_bar;
wire DC_KB_WR_RQ_bar;
inv1$ inv_6(DC_KB_WR_RQ_bar, DC_KB_WR_RQ);
wire DC_DMA_RD_RQ_bar;
inv1$ inv_7(DC_DMA_RD_RQ_bar, DC_DMA_RD_RQ);
wire DC_DMA_WR_RQ_bar;
inv1$ inv_8(DC_DMA_WR_RQ_bar, DC_DMA_WR_RQ);
wire Q2_bar;

/* Product Expressions */
wire nand_0_0_0_out;
wire nand_0_1_0_out;
wire nand_0_2_0_out;
wire nand_0_3_0_out;
nand4$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and4$ nand_0_1_0(nand_0_1_0_out,nand_0_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);
and4$ nand_0_2_0(nand_0_2_0_out,nand_0_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and3$ nand_0_3_0(nand_0_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ_bar,DMA_MEM_WR_RQ);
wire nand_1_0_0_out;
wire nand_1_1_0_out;
wire nand_1_2_0_out;
wire nand_1_3_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,nand_1_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and4$ nand_1_1_0(nand_1_1_0_out,nand_1_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);
and4$ nand_1_2_0(nand_1_2_0_out,nand_1_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and2$ nand_1_3_0(nand_1_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ);
wire nand_2_0_0_out;
wire nand_2_1_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,nand_2_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_2_1_0(nand_2_1_0_out,NOBODY_BUSY,DC_KB_WR_RQ);
wire nand_3_0_0_out;
wire nand_3_1_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,nand_3_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_3_1_0(nand_3_1_0_out,NOBODY_BUSY,DC_DMA_WR_RQ);
wire nand_4_0_0_out;
wire nand_4_1_0_out;
nand4$ nand_4_0_0(nand_4_0_0_out,nand_4_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_4_1_0(nand_4_1_0_out,NOBODY_BUSY,DC_MEM_WR_RQ);
wire nand_5_0_0_out;
nand4$ nand_5_0_0(nand_5_0_0_out,Q2_bar,Q1,Q0,DC_MEM_RD_RQ);
wire nand_6_0_0_out;
nand4$ nand_6_0_0(nand_6_0_0_out,Q2_bar,Q1,Q0,DC_DMA_RD_RQ);
wire nand_7_0_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1,Q0,DC_KB_RD_RQ);
wire nand_8_0_0_out;
nand3$ nand_8_0_0(nand_8_0_0_out,Q2,Q1,Q0_bar);
wire nand_9_0_0_out;
nand4$ nand_9_0_0(nand_9_0_0_out,Q2_bar,Q1_bar,Q0,DC_MEM_WR_RQ);
wire nand_10_0_0_out;
nand4$ nand_10_0_0(nand_10_0_0_out,Q2_bar,Q1_bar,Q0,DC_DMA_WR_RQ);
wire nand_11_0_0_out;
nand4$ nand_11_0_0(nand_11_0_0_out,Q2_bar,Q1_bar,Q0,DC_KB_WR_RQ);
wire nand_12_0_0_out;
nand3$ nand_12_0_0(nand_12_0_0_out,Q2,Q1_bar,Q0);
wire nand_13_0_0_out;
wire nand_13_1_0_out;
nand4$ nand_13_0_0(nand_13_0_0_out,nand_13_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_13_1_0(nand_13_1_0_out,NOBODY_BUSY,DC_KB_RD_RQ);
wire nand_14_0_0_out;
wire nand_14_1_0_out;
nand4$ nand_14_0_0(nand_14_0_0_out,nand_14_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_14_1_0(nand_14_1_0_out,NOBODY_BUSY,DC_DMA_RD_RQ);
wire nand_15_0_0_out;
wire nand_15_1_0_out;
nand4$ nand_15_0_0(nand_15_0_0_out,nand_15_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and2$ nand_15_1_0(nand_15_1_0_out,NOBODY_BUSY,DC_MEM_RD_RQ);

/* Sum Expressions */
nand2$ nand_0_0_1(D2,nand_0_0_0_out,nand_1_0_0_out);
nand4$ nand_1_0_1(D1,nand_0_0_0_out,nand_13_0_0_out,nand_14_0_0_out,nand_15_0_0_out);
wire nand_2_1_1_out;
nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_1_0_0_out,nand_2_0_0_out,nand_3_0_0_out);
and4$ nand_2_1_1(nand_2_1_1_out,nand_4_0_0_out,nand_13_0_0_out,nand_14_0_0_out,nand_15_0_0_out);
inv1$ nand_3_0_1(DC_MEM_RD_ACK, nand_5_0_0_out);
inv1$ nand_4_0_1(DC_DMA_RD_ACK, nand_6_0_0_out);
inv1$ nand_5_0_1(DC_KB_RD_ACK, nand_7_0_0_out);
inv1$ nand_6_0_1(DC_MEM_WR_ACK, nand_9_0_0_out);
inv1$ nand_7_0_1(DC_DMA_WR_ACK, nand_10_0_0_out);
inv1$ nand_8_0_1(DC_KB_WR_ACK, nand_11_0_0_out);
inv1$ nand_9_0_1(IC_MEM_RD_ACK, nand_12_0_0_out);
inv1$ nand_10_0_1(DMA_MEM_WR_ACK, nand_8_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule