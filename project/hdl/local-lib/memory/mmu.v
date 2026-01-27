module mmu #(
  parameter   CLK_PERIOD        = 10,
  parameter   MEM_LATENCY       = 64,
  parameter   RD_PERIODS        = ((MEM_LATENCY + CLK_PERIOD - 1) / CLK_PERIOD),
  parameter   RD_CMP            = RD_PERIODS - 2,
  parameter   BRST_CMP          = 10 - 1, // Depends on t_Hz and CLK_PERIOD
  parameter   WR_CMP            = 4 - 1,  // Depends on write_pulse_low and CLK_PERIOD
  parameter   WR_TOTAL_CMP      = 8 - 1   // Depends on cycle_time and CLK_PERIOD
) (
  input               rst, clk, RD, WR,
  inout     [31:0]    DATA_BUS,
  inout     [14:0]    ADDR_BUS
);

wire    [5:0]   RD_CMP_WIRE, BRST_CMP_WIRE, WR_CMP_WIRE, WR_TOTAL_CMP_WIRE;
assign          RD_CMP_WIRE         = RD_CMP;
assign          BRST_CMP_WIRE       = BRST_CMP;
assign          WR_CMP_WIRE         = WR_CMP;
assign          WR_TOTAL_CMP_WIRE   = WR_TOTAL_CMP;

wire    Q2,Q1,Q0;
wire    D2,D1,D0;
wire    MAX_RD,MAX_BRST,MAX_WR,MAX_WRTOT,CE,OE,WR_out,CT,DATAN;

wire    [7:0] counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(next_counter));
dff8$   dff_counter(clk, next_counter, counter, , CT, 1'b1);

eq_6b   done_reading(.in0(counter[5:0]), .in1(RD_CMP_WIRE),        .eq(MAX_RD));
eq_6b   done_readbst(.in0(counter[5:0]), .in1(BRST_CMP_WIRE),      .eq(MAX_BRST));
eq_6b   done_writing(.in0(counter[5:0]), .in1(WR_CMP_WIRE),        .eq(MAX_WR));
eq_6b   done_cooling(.in0(counter[5:0]), .in1(WR_TOTAL_CMP_WIRE),  .eq(MAX_WRTOT));

main_memory #(.MEM_BYTE_CAPACITY(32768)) mem_module (
  .mem_clk(clk), .rst(rst),
  .A(ADDR_BUS),
	.WR(WR_out), .OE(OE), .CE(CE),
  .DIO(DATA_BUS)
);

/* Inverters */
wire Q1_bar;
wire Q2_bar;
wire RD_bar;
inv1$ inv_2(RD_bar, RD);
wire Q0_bar;
wire WR_bar;
inv1$ inv_4(WR_bar, WR);
wire MAX_RD_bar;
inv1$ inv_5(MAX_RD_bar, MAX_RD);
wire MAX_WRTOT_bar;
inv1$ inv_6(MAX_WRTOT_bar, MAX_WRTOT);
wire MAX_BRST_bar;
inv1$ inv_7(MAX_BRST_bar, MAX_BRST);

/* Product Expressions */
wire and_0_0_out;
and4$ and_0_0(and_0_0_out,Q1_bar,Q0_bar,RD,WR_bar);
wire and_1_0_out;
and4$ and_1_0(and_1_0_out,Q2_bar,Q0_bar,RD_bar,WR);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2,Q1_bar,Q0_bar,MAX_WR);
wire and_3_0_out;
and3$ and_3_0(and_3_0_out,Q2_bar,Q1,MAX_BRST_bar);
wire and_4_0_out;
and4$ and_4_0(and_4_0_out,Q2,Q1_bar,Q0,MAX_WRTOT_bar);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q2_bar,Q1_bar,Q0,MAX_RD);
wire and_6_0_out;
and3$ and_6_0(and_6_0_out,Q2_bar,Q1,Q0_bar);
wire and_7_0_out;
and4$ and_7_0(and_7_0_out,Q2_bar,Q1_bar,Q0,MAX_RD_bar);
wire and_8_0_out;
and3$ and_8_0(and_8_0_out,Q2_bar,Q1,Q0);
wire and_9_0_out;
and3$ and_9_0(and_9_0_out,Q2,Q1_bar,Q0_bar);
wire and_10_0_out;
and3$ and_10_0(and_10_0_out,Q2_bar,Q1_bar,Q0_bar);
wire and_11_0_out;
and3$ and_11_0(and_11_0_out,Q2,Q1_bar,Q0);

/* Sum Expressions */
or3$ or_0_0(D2,and_0_0_out,and_4_0_out,and_9_0_out);
or3$ or_1_0(D1,and_3_0_out,and_5_0_out,and_6_0_out);
wire or_2_1_out;
or4$ or_2_0(D0,or_2_1_out,and_1_0_out,and_2_0_out,and_3_0_out);
or3$ or_2_1(or_2_1_out,and_4_0_out,and_6_0_out,and_7_0_out);
or3$ or_3_0(CE,and_8_0_out,and_10_0_out,and_11_0_out);
or4$ or_4_0(OE,and_8_0_out,and_9_0_out,and_10_0_out,and_11_0_out);
wire or_5_1_out;
or4$ or_5_0(WR_out,or_5_1_out,and_5_0_out,and_6_0_out,and_7_0_out);
or3$ or_5_1(or_5_1_out,and_8_0_out,and_10_0_out,and_11_0_out);
wire or_6_1_out;
or4$ or_6_0(CT,or_6_1_out,and_5_0_out,and_7_0_out,and_8_0_out);
or2$ or_6_1(or_6_1_out,and_9_0_out,and_11_0_out);
wire or_7_1_out;
or4$ or_7_0(DATAN,or_7_1_out,and_5_0_out,and_7_0_out,and_9_0_out);
or2$ or_7_1(or_7_1_out,and_10_0_out,and_11_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule