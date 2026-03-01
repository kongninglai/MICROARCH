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
wire Q1_bar;
wire Q2_bar;
wire DC_MEM_RD_RQ_bar;
inv1$ inv_3(DC_MEM_RD_RQ_bar, DC_MEM_RD_RQ);
wire DC_MEM_WR_RQ_bar;
inv1$ inv_4(DC_MEM_WR_RQ_bar, DC_MEM_WR_RQ);
wire DC_KB_RD_RQ_bar;
inv1$ inv_5(DC_KB_RD_RQ_bar, DC_KB_RD_RQ);
wire DC_DMA_WR_RQ_bar;
inv1$ inv_6(DC_DMA_WR_RQ_bar, DC_DMA_WR_RQ);
wire IC_MEM_RD_RQ_bar;
inv1$ inv_7(IC_MEM_RD_RQ_bar, IC_MEM_RD_RQ);
wire DC_DMA_RD_RQ_bar;
inv1$ inv_8(DC_DMA_RD_RQ_bar, DC_DMA_RD_RQ);
wire DC_KB_WR_RQ_bar;
inv1$ inv_9(DC_KB_WR_RQ_bar, DC_KB_WR_RQ);

/* Product Expressions */
wire and_0_0_out;
wire and_0_1_out;
wire and_0_2_out;
wire and_0_3_out;
and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,Q2_bar);
and4$ and_0_1(and_0_1_out,Q1_bar,Q0_bar,NOBODY_BUSY,DC_MEM_RD_RQ_bar);
and4$ and_0_2(and_0_2_out,DC_DMA_RD_RQ_bar,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and3$ and_0_3(and_0_3_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ_bar,DMA_MEM_WR_RQ);
wire and_1_0_out;
wire and_1_1_out;
wire and_1_2_out;
wire and_1_3_out;
and4$ and_1_0(and_1_0_out,and_1_1_out,and_1_2_out,and_1_3_out,Q2_bar);
and4$ and_1_1(and_1_1_out,Q1_bar,Q0_bar,NOBODY_BUSY,DC_MEM_RD_RQ_bar);
and4$ and_1_2(and_1_2_out,DC_DMA_RD_RQ_bar,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and2$ and_1_3(and_1_3_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ);
wire and_2_0_out;
wire and_2_1_out;
and4$ and_2_0(and_2_0_out,and_2_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_2_1(and_2_1_out,NOBODY_BUSY,DC_KB_WR_RQ);
wire and_3_0_out;
wire and_3_1_out;
and4$ and_3_0(and_3_0_out,and_3_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_3_1(and_3_1_out,NOBODY_BUSY,DC_DMA_WR_RQ);
wire and_4_0_out;
wire and_4_1_out;
and4$ and_4_0(and_4_0_out,and_4_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_4_1(and_4_1_out,NOBODY_BUSY,DC_MEM_WR_RQ);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q2_bar,Q1,Q0,DC_MEM_RD_RQ);
wire and_6_0_out;
and4$ and_6_0(and_6_0_out,Q2_bar,Q1,Q0,DC_DMA_RD_RQ);
wire and_7_0_out;
and4$ and_7_0(and_7_0_out,Q2_bar,Q1,Q0,DC_KB_RD_RQ);
wire and_8_0_out;
and3$ and_8_0(and_8_0_out,Q2,Q1,Q0_bar);
wire and_9_0_out;
and4$ and_9_0(and_9_0_out,Q2_bar,Q1_bar,Q0,DC_MEM_WR_RQ);
wire and_10_0_out;
and4$ and_10_0(and_10_0_out,Q2_bar,Q1_bar,Q0,DC_DMA_WR_RQ);
wire and_11_0_out;
and4$ and_11_0(and_11_0_out,Q2_bar,Q1_bar,Q0,DC_KB_WR_RQ);
wire and_12_0_out;
and3$ and_12_0(and_12_0_out,Q2,Q1_bar,Q0);
wire and_13_0_out;
wire and_13_1_out;
and4$ and_13_0(and_13_0_out,and_13_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_13_1(and_13_1_out,NOBODY_BUSY,DC_KB_RD_RQ);
wire and_14_0_out;
wire and_14_1_out;
and4$ and_14_0(and_14_0_out,and_14_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_14_1(and_14_1_out,NOBODY_BUSY,DC_DMA_RD_RQ);
wire and_15_0_out;
wire and_15_1_out;
and4$ and_15_0(and_15_0_out,and_15_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_15_1(and_15_1_out,NOBODY_BUSY,DC_MEM_RD_RQ);

/* Sum Expressions */
or2$ or_0_0(D2,and_0_0_out,and_1_0_out);
or4$ or_1_0(D1,and_0_0_out,and_13_0_out,and_14_0_out,and_15_0_out);
wire or_2_1_out;
or4$ or_2_0(D0,or_2_1_out,and_1_0_out,and_2_0_out,and_3_0_out);
or4$ or_2_1(or_2_1_out,and_4_0_out,and_13_0_out,and_14_0_out,and_15_0_out);
assign DC_MEM_RD_ACK = and_5_0_out;
assign DC_DMA_RD_ACK = and_6_0_out;
assign DC_KB_RD_ACK = and_7_0_out;
assign DC_MEM_WR_ACK = and_9_0_out;
assign DC_DMA_WR_ACK = and_10_0_out;
assign DC_KB_WR_ACK = and_11_0_out;
assign IC_MEM_RD_ACK = and_12_0_out;
assign DMA_MEM_WR_ACK = and_8_0_out;

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule