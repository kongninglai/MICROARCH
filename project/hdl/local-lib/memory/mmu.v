module mmu #(
  parameter MEM_BYTE_CAPACITY = 32768,
  parameter BURST_SIZE=4,
  /* IMPORTANT: All parameters assume DELAY_ADJ < CYCLE_TIME <= 17 */
  // Next few parameters are in units of ns
  parameter DELAY_ADJ         = 7,
  parameter ADDR_SETUP        = 25 + DELAY_ADJ,
  parameter DATA_SETUP        = 25 + DELAY_ADJ,
  parameter CE_SETUP          = 35 + DELAY_ADJ,
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
  parameter V_CT_WR_ADDR      = ADDR_EN_TO_WR_EN - 1,
  parameter V_CT_WR_EN        = WR_CLK_SPACING - 1,
  parameter V_CT_WR_BRST      = (WR_DIS_TO_DATA_EN + ((BURST_SIZE-1) * WR_CLK_SPACING)) - 1
) (
  input               rst, clk, RD, WR,
  inout     [31:0]    DATA_BUS,
  inout     [14:0]    ADDR_BUS
);

wire    [0:0]   CT_HIZ_PROT,CT_RD_EN,CT_RD_BRST,CT_BUS_FREE,CT_WR_ADDR,CT_WR_EN,CT_WR_BRST;

wire    [5:0]   W_CT_HIZ_PROT,W_CT_RD_EN,W_CT_RD_BRST,W_CT_BUS_FREE,W_CT_WR_ADDR,W_CT_WR_EN,W_CT_WR_BRST;
assign          W_CT_HIZ_PROT = V_CT_HIZ_PROT;     
assign          W_CT_RD_EN    = V_CT_RD_EN   ;     
assign          W_CT_RD_BRST  = V_CT_RD_BRST ;     
assign          W_CT_BUS_FREE = V_CT_BUS_FREE;     
assign          W_CT_WR_ADDR  = V_CT_WR_ADDR ;     
assign          W_CT_WR_EN    = V_CT_WR_EN   ;     
assign          W_CT_WR_BRST  = V_CT_WR_BRST ;    

wire    Q2,Q1,Q0;
wire    D2,D1,D0;
wire    OE_out,WR_out,DATA_EN_BAR;

wire    idling;

nor3$   nor3$_idling(idling, Q2, Q1, Q0);

wire    [7:0] counter, inc_counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(inc_counter));

wire    state_change;
neq_3b  neq_3b_state_change(.in0({Q2,Q1,Q0}), .in1({D2,D1,D0}), .neq(state_change));

wire    zero_counter;
or2$    or2$_zero_counter(zero_counter, state_change, idling);

mux2$   mux2$_next_counter[7:0](next_counter, inc_counter, 8'd0, zero_counter);

dff8$   dff_counter(clk, next_counter, counter, , rst, 1'b1);

eq_6b   done_HIZ_PROT     (.in0(counter[5:0]), .in1(W_CT_HIZ_PROT), .eq(CT_HIZ_PROT));
eq_6b   done_RD_EN        (.in0(counter[5:0]), .in1(W_CT_RD_EN   ), .eq(CT_RD_EN   ));
eq_6b   done_RD_BRST      (.in0(counter[5:0]), .in1(W_CT_RD_BRST ), .eq(CT_RD_BRST ));
eq_6b   done_BUS_FREE     (.in0(counter[5:0]), .in1(W_CT_BUS_FREE), .eq(CT_BUS_FREE));
eq_6b   done_WR_ADDR      (.in0(counter[5:0]), .in1(W_CT_WR_ADDR ), .eq(CT_WR_ADDR ));
eq_6b   done_WR_EN        (.in0(counter[5:0]), .in1(W_CT_WR_EN   ), .eq(CT_WR_EN   ));
eq_6b   done_WR_BRST      (.in0(counter[5:0]), .in1(W_CT_WR_BRST ), .eq(CT_WR_BRST ));

main_memory #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .CYCLE_TIME(CYCLE_TIME), .DELAY_ADJ(DELAY_ADJ)) mem_module 
(
  .clk(clk), .rst(rst),
  .A(ADDR_BUS),
	.WR(WR_out), .OE(OE_out),
  .DIO(DATA_BUS)
);

/* Inverters */
wire Q0_bar;
wire CT_WR_ADDR_bar;
inv1$ inv_1(CT_WR_ADDR_bar, CT_WR_ADDR);
wire WR_bar;
inv1$ inv_2(WR_bar, WR);
wire CT_BUS_FREE_bar;
inv1$ inv_3(CT_BUS_FREE_bar, CT_BUS_FREE);
wire CT_HIZ_PROT_bar;
inv1$ inv_4(CT_HIZ_PROT_bar, CT_HIZ_PROT);
wire CT_WR_BRST_bar;
inv1$ inv_5(CT_WR_BRST_bar, CT_WR_BRST);
wire CT_RD_BRST_bar;
inv1$ inv_6(CT_RD_BRST_bar, CT_RD_BRST);
wire Q1_bar;
wire RD_bar;
inv1$ inv_8(RD_bar, RD);
wire Q2_bar;

/* Product Expressions */
wire and_0_0_out;
wire and_0_1_out;
and4$ and_0_0(and_0_0_out,and_0_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_0_1(and_0_1_out,RD_bar,WR);
wire and_1_0_out;
wire and_1_1_out;
and4$ and_1_0(and_1_0_out,and_1_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_1_1(and_1_1_out,RD,WR_bar);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2,Q1,Q0_bar,CT_WR_EN);
wire and_3_0_out;
and4$ and_3_0(and_3_0_out,Q2_bar,Q1,Q0_bar,CT_RD_EN);
wire and_4_0_out;
and4$ and_4_0(and_4_0_out,Q2_bar,Q1_bar,Q0,CT_HIZ_PROT);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q2_bar,Q1_bar,Q0,CT_HIZ_PROT_bar);
wire and_6_0_out;
and4$ and_6_0(and_6_0_out,Q2,Q1_bar,Q0,CT_WR_ADDR);
wire and_7_0_out;
and3$ and_7_0(and_7_0_out,Q2,Q1_bar,CT_BUS_FREE_bar);
wire and_8_0_out;
and4$ and_8_0(and_8_0_out,Q2,Q1_bar,Q0,CT_WR_ADDR_bar);
wire and_9_0_out;
and4$ and_9_0(and_9_0_out,Q2_bar,Q1,Q0,CT_RD_BRST);
wire and_10_0_out;
and4$ and_10_0(and_10_0_out,Q2,Q1,Q0,CT_WR_BRST_bar);
wire and_11_0_out;
and4$ and_11_0(and_11_0_out,Q2_bar,Q1,Q0,CT_RD_BRST_bar);
wire and_12_0_out;
and3$ and_12_0(and_12_0_out,Q2_bar,Q1,Q0_bar);
wire and_13_0_out;
and3$ and_13_0(and_13_0_out,Q2,Q1,Q0_bar);
wire and_14_0_out;
and2$ and_14_0(and_14_0_out,Q2,Q0);
wire and_15_0_out;
buffer$ buffer_and_15_0(and_15_0_out,Q1_bar);

/* Sum Expressions */
wire or_0_1_out;
or4$ or_0_0(D2,or_0_1_out,and_1_0_out,and_6_0_out,and_7_0_out);
or4$ or_0_1(or_0_1_out,and_8_0_out,and_9_0_out,and_10_0_out,and_13_0_out);
wire or_1_1_out;
or4$ or_1_0(D1,or_1_1_out,and_4_0_out,and_6_0_out,and_10_0_out);
or3$ or_1_1(or_1_1_out,and_11_0_out,and_12_0_out,and_13_0_out);
wire or_2_1_out;
wire or_2_2_out;
or4$ or_2_0(D0,or_2_1_out,or_2_2_out,and_0_0_out,and_1_0_out);
or4$ or_2_1(or_2_1_out,and_2_0_out,and_3_0_out,and_5_0_out,and_8_0_out);
or2$ or_2_2(or_2_2_out,and_10_0_out,and_11_0_out);
wire or_3_1_out;
or4$ or_3_0(OE_out,or_3_1_out,and_9_0_out,and_11_0_out,and_13_0_out);
or2$ or_3_1(or_3_1_out,and_14_0_out,and_15_0_out);
wire or_4_1_out;
or4$ or_4_0(WR_out,or_4_1_out,and_9_0_out,and_11_0_out,and_12_0_out);
or2$ or_4_1(or_4_1_out,and_14_0_out,and_15_0_out);
or4$ or_5_0(DATA_EN_BAR,and_12_0_out,and_13_0_out,and_14_0_out,and_15_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule