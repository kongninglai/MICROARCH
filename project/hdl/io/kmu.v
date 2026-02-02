module kmu #(
  parameter CYCLES_LOW    = 1,
  parameter CYCLES_VALID  = 1
) (
  input               rst, clk, RD_KBDR, RD_KBSR, WE,
  input     [31:0]    new_data,
  inout     [31:0]    DATA_BUS
);

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
wire Q0_bar;
wire RD_KBDR_bar;
inv1$ inv_1(RD_KBDR_bar, RD_KBDR);
wire RD_KBSR_bar;
inv1$ inv_2(RD_KBSR_bar, RD_KBSR);
wire Q1_bar;

/* Product Expressions */
wire and_0_0_out;
and4$ and_0_0(and_0_0_out,Q1_bar,Q0_bar,RD_KBDR,RD_KBSR_bar);
wire and_1_0_out;
and3$ and_1_0(and_1_0_out,Q1_bar,Q0_bar,RD_KBDR_bar);
wire and_2_0_out;
and2$ and_2_0(and_2_0_out,Q1_bar,Q0_bar);
wire and_3_0_out;
buffer$ buffer_and_3_0(and_3_0_out,Q0_bar);

/* Sum Expressions */
buffer$ buffer_or_0_0(D1,and_0_0_out);
buffer$ buffer_or_1_0(D0,and_1_0_out);
buffer$ buffer_or_2_0(D_ENBAR,and_2_0_out);
buffer$ buffer_or_3_0(CLRBAR,and_3_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);

endmodule