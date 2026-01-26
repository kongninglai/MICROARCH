module mmu(
  input           rst, clk, RD, WR,
  inout   [31:0]  DATA_BUS,
  inout   [14:0]  ADDR_BUS
);

wire RD_out,WR_out,OE_out,V;
wire Q1,Q0;
wire D1,D0;

wire    not_idling;
or2$    or2$_0(not_idling, Q1, Q0);

wire    [7:0] counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(next_counter));
dff8$   dff_counter(clk, next_counter, counter, , not_idling, 1'b1);

wire    MAX;
eq_6b   done_reading(.in0(counter[5:0]), .in1(6'd50), .eq(MAX));

// AUTO GENERATED CODE FOR FSM

/* Inverters */
wire WR_bar;
inv1$ inv_0(WR_bar, WR);
wire RD_bar;
inv1$ inv_1(RD_bar, RD);
wire Q0_bar;
wire Q1_bar;

/* Product Expressions */
wire and_0_0_out;
and3$ and_0_0(and_0_0_out,Q0_bar,RD_bar,WR);
wire and_1_0_out;
and3$ and_1_0(and_1_0_out,Q1,Q0_bar,MAX);
wire and_2_0_out;
and3$ and_2_0(and_2_0_out,Q1_bar,Q0_bar,WR_bar);
wire and_3_0_out;
and2$ and_3_0(and_3_0_out,Q1,Q0);
wire and_4_0_out;
buffer$ buffer_and_4_0(and_4_0_out,Q1_bar);
wire and_5_0_out;
and2$ and_5_0(and_5_0_out,Q1,Q0_bar);
wire and_6_0_out;
and2$ and_6_0(and_6_0_out,Q1_bar,Q0_bar);

/* Sum Expressions */
or2$ or_0_0(D1,and_0_0_out,and_5_0_out);
or2$ or_1_0(D0,and_1_0_out,and_2_0_out);
buffer$ buffer_or_2_0(RD_out,and_6_0_out);
or3$ or_3_0(WR_out,and_3_0_out,and_5_0_out,and_6_0_out);
buffer$ buffer_or_4_0(OE_out,and_4_0_out);
buffer$ buffer_or_5_0(V,and_3_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);

endmodule