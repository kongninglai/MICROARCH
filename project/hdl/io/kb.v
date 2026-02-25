module kb #(
  parameter MEM_BYTE_CAPACITY = 32768,
  parameter BURST_SIZE=4,
  /* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
  // Next few parameters are in units of ns
  parameter DELAY_ADJ         = 7,
  parameter ADDR_SETUP        = 25 + DELAY_ADJ,
  parameter DATA_SETUP        = 25 + DELAY_ADJ,
  parameter CE_SETUP          = 35,
  parameter DOE_TIME          = 64,
  parameter HZ_TIME           = 18,

  parameter CYCLE_TIME        = 10,

  // Next few parameters are in units of cycles
  parameter ADDR_HIZ_PROT     = 1, // Don't enable RD when ADDR comparator can still be HiZ after clock edge
  parameter RD_EN_DURATION    = ((DOE_TIME    / CYCLE_TIME)   + 1),
  parameter RD_DIS_TO_DATA_V  = CYCLE_TIME <= 17 ? 1 : 1, // This will fail miserably if you have a bad cycle time (>= 18 ns)
  parameter RD_TO_BUS_FREE    = CYCLE_TIME <= 8 ? 2 : 1, // Needed due to tHz

  // Yes, the extra + 1 should be there below in RD_CLK_SPACING
  // Need + 1 cycle for data to be valid, and then extra time to let DIO become HiZ
  parameter RD_CLK_SPACING    = ((HZ_TIME     / CYCLE_TIME)   + 1) + 1,

  parameter ADDR_EN_TO_WR_EN  = ((ADDR_SETUP  / CYCLE_TIME)   + 1),
  parameter DATA_EN_TO_WR_DIS = ((DATA_SETUP  / CYCLE_TIME)   + 1),
  parameter WR_DIS_TO_DATA_EN = 1, // Protect against DIO -> posedge WR violations   
  parameter WR_CLK_SPACING    = ((CE_SETUP    / CYCLE_TIME)   + 1) + WR_DIS_TO_DATA_EN,


  parameter V_CT_HIZ_PROT     = ADDR_HIZ_PROT - 1,
  parameter V_CT_RD_EN        = RD_EN_DURATION - 1,
  parameter V_CT_RD_BRST      = (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1,
  parameter V_CT_BUS_FREE     = RD_TO_BUS_FREE - 1,

  parameter V_CT_DRIVE_STAT   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) + RD_TO_BUS_FREE - 1,
  parameter V_CT_DRIVE_DATA   = ADDR_HIZ_PROT + RD_EN_DURATION + (RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1,
  parameter V_CT_CLR_RDY      = RD_TO_BUS_FREE - 1
) (
  input               rst, clk, RD_KBDR, RD_KBSR, WE,
  input     [31:0]    new_data,
  inout     [31:0]    DATA_BUS
);

wire    [0:0]   CT_DRIVE_STAT,CT_DRIVE_DATA,CT_CLR_RDY;
wire    [5:0]   W_CT_DRIVE_STAT,W_CT_DRIVE_DATA,W_CT_CLR_RDY;

assign          W_CT_DRIVE_STAT = V_CT_DRIVE_STAT;     
assign          W_CT_DRIVE_DATA = V_CT_DRIVE_DATA;     
assign          W_CT_CLR_RDY    = V_CT_CLR_RDY;

wire    idling;
nor2$   nor3$_idling(idling, Q1, Q0);
wire    [7:0] counter, inc_counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(inc_counter));
wire    state_change;
neq_2b  neq_2b_state_change(.in0({Q1,Q0}), .in1({D1,D0}), .neq(state_change));
wire    zero_counter;
or2$    or2$_zero_counter(zero_counter, state_change, idling);
mux2$   mux2$_next_counter[7:0](next_counter, inc_counter, 8'd0, zero_counter);
dff8$   dff_counter(clk, next_counter, counter, , rst, 1'b1);

eq_6b   done_DRIVE_STAT   (.in0(counter[5:0]), .in1(W_CT_DRIVE_STAT), .eq(CT_DRIVE_STAT));
eq_6b   done_DRIVE_DATA   (.in0(counter[5:0]), .in1(W_CT_DRIVE_DATA), .eq(CT_DRIVE_DATA));
eq_6b   done_CLR_RDY      (.in0(counter[5:0]), .in1(W_CT_CLR_RDY),    .eq(CT_CLR_RDY));

wire            CLR_READY, CLRBAR;
and2$           and2$(CLR_READY, rst, CLRBAR);

wire    [31:0]  KB_REG_DATA;

tristate_bus_driver16$  DATA_BUS_DRIVER_H(.enbar(D_ENBAR), .in(KB_REG_DATA[31:16]), .out(DATA_BUS[31:16]));
tristate_bus_driver16$  DATA_BUS_DRIVER_L(.enbar(D_ENBAR), .in(KB_REG_DATA[15:0]),  .out(DATA_BUS[15:0]));

dff32 KBSR_KBDR (
  .WE({4{WE}}), .CLR({{2{CLR_READY}},{2{rst}}}), .D(new_data), .PRE(1'b1),
  .Q(KB_REG_DATA), .QBAR()
);

wire Q1,Q0,D1,D0;

wire [1:0]  STATE       = {Q1,Q0};
wire [1:0]  NEXT_STATE  = {D1,D0};

/* Inverters */
wire Q1_bar;
wire RD_KBDR_bar;
inv1$ inv_1(RD_KBDR_bar, RD_KBDR);
wire RD_KBSR_bar;
inv1$ inv_2(RD_KBSR_bar, RD_KBSR);
wire CT_DRIVE_STAT_bar;
inv1$ inv_3(CT_DRIVE_STAT_bar, CT_DRIVE_STAT);
wire CT_CLR_RDY_bar;
inv1$ inv_4(CT_CLR_RDY_bar, CT_CLR_RDY);
wire Q0_bar;

/* Product Expressions */
wire and_0_0_out;
and4$ and_0_0(and_0_0_out,Q1_bar,Q0_bar,RD_KBDR,RD_KBSR_bar);
wire and_1_0_out;
and3$ and_1_0(and_1_0_out,Q1,Q0_bar,CT_DRIVE_STAT_bar);
wire and_2_0_out;
and3$ and_2_0(and_2_0_out,Q1_bar,Q0,CT_DRIVE_DATA);
wire and_3_0_out;
and3$ and_3_0(and_3_0_out,Q1,Q0,CT_CLR_RDY_bar);
wire and_4_0_out;
and2$ and_4_0(and_4_0_out,Q1_bar,RD_KBDR_bar);
wire and_5_0_out;
and2$ and_5_0(and_5_0_out,Q1,Q0);
wire and_6_0_out;
and2$ and_6_0(and_6_0_out,Q1_bar,Q0_bar);
wire and_7_0_out;
and2$ and_7_0(and_7_0_out,Q1_bar,Q0);
wire and_8_0_out;
buffer$ buffer_and_8_0(and_8_0_out,Q0_bar);

/* Sum Expressions */
or4$ or_0_0(D1,and_0_0_out,and_1_0_out,and_2_0_out,and_3_0_out);
or3$ or_1_0(D0,and_3_0_out,and_4_0_out,and_7_0_out);
or2$ or_2_0(D_ENBAR,and_5_0_out,and_6_0_out);
or2$ or_3_0(CLRBAR,and_7_0_out,and_8_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);

endmodule