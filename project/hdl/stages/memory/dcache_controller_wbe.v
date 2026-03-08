module dcache_controller_wbe #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15,
  parameter   CHIPS_PER_RANK=16
) (
  input                                         clk, rst,
  input                                         DC_MEM_WR_ACK, DC_DMA_WR_ACK, DC_KB_WR_ACK, DCACHE_NEED_WR_BUS,
  input     [RANK_BIT_WIDTH-1:0]                DCACHE_WBE_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  DCACHE_PHYS_ADDR,
  input     [CHIPS_PER_RANK-1:0]                DCACHE_WR_MASK,
  input     [2:0]                               KB_PFN, DMA_PFN,

  output    [CHIPS_PER_RANK-1:0]                WR_mask,
  output    [MEM_ADDR_WIDTH-1:0]                ADDR_BUS,
  output    [BUS_BIT_WIDTH-1:0]                 DATA_BUS,
  output                                        DC_MEM_WR_RQ, DC_DMA_WR_RQ, DC_KB_WR_RQ, WBE_BUSY
);

/*** STATE BITS ***/
wire  [1:0] STATE, NEXT_STATE;
wire        Q1,Q0;
wire        D1,D0;

assign STATE        = {Q1, Q0};
assign NEXT_STATE   = {D1, D0};

/*** STATE MACHINE OUTPUTS ***/

/* OUTPUT DECLARATIONS */
wire          FSM_LD_REGS, FSM_BUS_ENBAR, WBE_FSM_BUSY, FSM_CLR_CTR, FSM_GATE_RQ;

/* COUNTER */
wire  [1:0] counter, inc_counter, next_counter;

big_increment #(
  .WIDTH(2)
) big_increment_inc_counter (
  .a(counter),
  .s(inc_counter)
);

mux2$   mux2$_next_counter[1:0](next_counter, inc_counter, 2'd0, FSM_CLR_CTR);

reg_n #(
  .WIDTH(2),
  .USE_EN_BAR(0)
) reg_n_counter (
  .clk(clk), .rst(rst),
  .en({2{1'b1}}), .d(next_counter),
  .q(counter)
);

/*** STATE MACHINE INPUTS ***/

wire ARB_ACK_RECV, WB_DONE;

or3$    or3$_ARB_ACK_RECV(ARB_ACK_RECV, DC_MEM_WR_ACK, DC_DMA_WR_ACK, DC_KB_WR_ACK);
and2$   and2$_WB_DONE(WB_DONE, counter[0], counter[1]);
or2$    or2$_WBE_BUSY(WBE_BUSY, Q1, Q0);

/*** REGISTERS ***/

wire  [2:0] D_DC_WR_RQ;
wire  [2:0] Q_DC_WR_RQ;

io_addr_logic_block io_addr_logic_block_inst (
  .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN), .PFN(DCACHE_PHYS_ADDR[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-3]),
  .WHICH_IO(D_DC_WR_RQ)
);

reg_n #(
  .WIDTH(3),
  .USE_EN_BAR(0)
) reg_n_Q_DC_WR_RQ (
  .clk(clk), .rst(rst),
  .en({(3){FSM_LD_REGS}}), .d(D_DC_WR_RQ),
  .q(Q_DC_WR_RQ)
);

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      D_WBE_ADDR_OUT;
wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      Q_WBE_ADDR_OUT;

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_Q_WBE_ADDR_OUT (
  .clk(clk), .rst(rst),
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){FSM_LD_REGS}}), .d(DCACHE_PHYS_ADDR),
  .q(Q_WBE_ADDR_OUT)
);

wire  [CHIPS_PER_RANK-1:0]      Q_WBE_WR_MASK;

reg_n #(
  .WIDTH(CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_Q_WBE_WR_MASK (
  .clk(clk), .rst(rst),
  .en({(CHIPS_PER_RANK){FSM_LD_REGS}}), .d(DCACHE_WR_MASK),
  .q(Q_WBE_WR_MASK)
);

wire  [RANK_BIT_WIDTH-1:0]   Q_WBE_DATA;

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_Q_WBE_DATA (
  .clk(clk), .rst(rst),
  .en({(RANK_BIT_WIDTH){FSM_LD_REGS}}), .d(DCACHE_WBE_DATA),
  .q(Q_WBE_DATA)
);

wire  [BUS_BIT_WIDTH-1:0]   WBE_BUS_DATA;

mux4$   mux4$_WBE_BUS_DATA[BUS_BIT_WIDTH-1:0](WBE_BUS_DATA,
                                              Q_WBE_DATA[31:0],
                                              Q_WBE_DATA[63:32],
                                              Q_WBE_DATA[95:64],
                                              Q_WBE_DATA[127:96],
                                              counter[0],
                                              counter[1]);

/*** BUS DRIVERS ***/

tristate_bus_driver16$   tristate_bus_driver16$_WR_mask[CHIPS_PER_RANK-1:0]
                                                       (
                                                          .enbar(FSM_BUS_ENBAR),
                                                          .in(Q_WBE_WR_MASK),
                                                          .out(WR_mask)
                                                       );

tristate_bus_driver1$   tristate_bus_driver1$_DATA_BUS[BUS_BIT_WIDTH-1:0]
                                                       (
                                                          .enbar(FSM_BUS_ENBAR),
                                                          .in(WBE_BUS_DATA),
                                                          .out(DATA_BUS)
                                                       );

tristate_bus_driver1$   tristate_bus_driver1$_ADDR_BUS[MEM_ADDR_WIDTH-1:0]
                                                       (
                                                          .enbar(FSM_BUS_ENBAR),
                                                          .in({Q_WBE_ADDR_OUT, 4'b0000}),
                                                          .out(ADDR_BUS)
                                                       );

and2$   and2$_DC_MEM_WR_RQ_GATED(DC_MEM_WR_RQ_GATED, Q_DC_WR_RQ[2], FSM_GATE_RQ);

tristate_bus_driver1$   tristate_bus_driver1$_DC_MEM_WR_RQ
                                                       (
                                                          .enbar(1'b0),
                                                          .in(DC_MEM_WR_RQ_GATED),
                                                          .out(DC_MEM_WR_RQ)
                                                       );

and2$   and2$_DC_DMA_WR_RQ_GATED(DC_DMA_WR_RQ_GATED, Q_DC_WR_RQ[1], FSM_GATE_RQ);

tristate_bus_driver1$   tristate_bus_driver1$_DC_DMA_WR_RQ
                                                       (
                                                          .enbar(1'b0),
                                                          .in(DC_DMA_WR_RQ_GATED),
                                                          .out(DC_DMA_WR_RQ)
                                                       );

and2$   and2$_DC_KB_WR_RQ_GATED(DC_KB_WR_RQ_GATED, Q_DC_WR_RQ[0], FSM_GATE_RQ);

tristate_bus_driver1$   tristate_bus_driver1$_DC_KB_WR_RQ
                                                       (
                                                          .enbar(1'b0),
                                                          .in(DC_KB_WR_RQ_GATED),
                                                          .out(DC_KB_WR_RQ)
                                                       );

/* Inverters */
wire Q0_bar;
wire WB_DONE_bar;
inv1$ inv_1(WB_DONE_bar, WB_DONE);
wire Q1_bar;
wire ARB_ACK_RECV_bar;
inv1$ inv_3(ARB_ACK_RECV_bar, ARB_ACK_RECV);

/* Product Expressions */
wire and_0_0_out;
and3$ and_0_0(and_0_0_out,Q1,Q0_bar,WB_DONE_bar);
wire and_1_0_out;
and3$ and_1_0(and_1_0_out,Q1_bar,Q0_bar,DCACHE_NEED_WR_BUS);
wire and_2_0_out;
and2$ and_2_0(and_2_0_out,Q1,Q0_bar);
wire and_3_0_out;
and3$ and_3_0(and_3_0_out,Q1_bar,Q0,ARB_ACK_RECV);
wire and_4_0_out;
and3$ and_4_0(and_4_0_out,Q1_bar,Q0,ARB_ACK_RECV_bar);
wire and_5_0_out;
assign and_5_0_out = Q1_bar;

/* Sum Expressions */
or2$ or_0_0(D1,and_0_0_out,and_3_0_out);
or2$ or_1_0(D0,and_1_0_out,and_4_0_out);
assign FSM_LD_REGS = and_1_0_out;
assign FSM_BUS_ENBAR = and_5_0_out;
or3$ or_4_0(WBE_FSM_BUSY,and_2_0_out,and_3_0_out,and_4_0_out);
assign FSM_CLR_CTR = and_5_0_out;
or2$ or_6_0(FSM_GATE_RQ,and_3_0_out,and_4_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);

endmodule