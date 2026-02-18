module mmu #(
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
  parameter V_CT_WR_ADDR      = ADDR_EN_TO_WR_EN - 1,
  parameter V_CT_WR_EN        = WR_CLK_SPACING - 1,
  parameter V_CT_WR_BRST      = (WR_DIS_TO_DATA_EN + ((BURST_SIZE-1) * WR_CLK_SPACING)) - 1
) (
  input               rst, clk, RD, WR,
  input     [15:0]    WR_mask,
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

wire    [31:0]  DIO;
wire    not_writing, not_wr_addr, not_wr_en, not_wr_brst;

wire    Q2,Q1,Q0;
wire    D2,D1,D0;
wire    OE_out,WR_out,DATA_EN_BAR;

wire    [15:0]  WR_mask_out;
or2$    or2$_WR_mask_out[15:0](WR_mask_out, WR_mask, {16{WR_out}});

neq_3b  neq_3b_not_wr_addr(.in0(3'b101), .in1({Q2,Q1,Q0}), .neq(not_wr_addr));
neq_3b  neq_3b_not_wr_en  (.in0(3'b110), .in1({Q2,Q1,Q0}), .neq(not_wr_en));
neq_3b  neq_3b_not_wr_brst(.in0(3'b111), .in1({Q2,Q1,Q0}), .neq(not_wr_brst));

and3$   and3$_not_writing(not_writing, not_wr_addr, not_wr_en, not_wr_brst);

// If we need to use tristate_bus_driver16$ even for the internal memory bus, it still works, last I checked
// tristate_bus_driver16$  DIO_BUS_DRIVER_H(.enbar(not_writing), .in(DATA_BUS[31:16]), .out(DIO[31:16]));
// tristate_bus_driver16$  DIO_BUS_DRIVER_L(.enbar(not_writing), .in(DATA_BUS[15:0]),  .out(DIO[15:0]));

tristate16L$  DIO_DRIVER_H(.enbar(not_writing), .in(DATA_BUS[31:16]), .out(DIO[31:16]));
tristate16L$  DIO_DRIVER_L(.enbar(not_writing), .in(DATA_BUS[15:0]), .out(DIO[15:0]));

wire    not_reading;

neq_3b  neq_3b_not_reading(.in0(3'b011), .in1({Q2,Q1,Q0}), .neq(not_reading));

tristate_bus_driver16$  DATA_BUS_DRIVER_H(.enbar(not_reading), .in(DIO[31:16]), .out(DATA_BUS[31:16]));
tristate_bus_driver16$  DATA_BUS_DRIVER_L(.enbar(not_reading), .in(DIO[15:0]),  .out(DATA_BUS[15:0]));

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


endmodule