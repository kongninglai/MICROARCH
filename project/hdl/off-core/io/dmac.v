module dmac #(
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
  parameter V_CT_RD_BRST      = (RD_EN_DURATION - 1 + RD_DIS_TO_DATA_V + ((BURST_SIZE-1) * RD_CLK_SPACING)) - 1,
  parameter V_CT_BUS_FREE     = RD_TO_BUS_FREE - 1,
  parameter V_CT_WR_ADDR      = ADDR_EN_TO_WR_EN - 1,
  parameter V_CT_WR_EN        = WR_CLK_SPACING - 1,
  parameter V_CT_WR_BRST      = (WR_DIS_TO_DATA_EN + ((BURST_SIZE-1) * WR_CLK_SPACING)) - 1,

  parameter V_CT_WR_ACK       = ADDR_EN_TO_WR_EN + WR_CLK_SPACING + WR_DIS_TO_DATA_EN - 1
) (
  input               rst, clk, DMA_RD, DMA_WR,
  inout     [15:0]    WR_mask,
  inout     [31:0]    DATA_BUS,
  inout     [14:0]    ADDR_BUS,
  input               DMA_WR_ACK,
  output              DMA_MEM_WR_RQ, DMA_INT
);

/* STATE MACHINE STATE BITS */
wire        [2:0]     STATE, NEXT_STATE;
wire                  Q2, Q1, Q0;
wire                  D2, D1, D0;

assign                STATE       = {Q2, Q1, Q0};
assign                NEXT_STATE  = {D2, D1, D0};

wire                  IN_000, IN_001, IN_010, IN_011,
                      IN_100, IN_101, IN_110, IN_111;

wire                  TRANSFERRING_N;
inv1$     inv1$(TRANSFERRING_N, Q2);

/* State Duration Logic */
wire    [0:0]   CT_WR_ACK,CT_WR_EN;

wire    [5:0]   W_CT_WR_ACK,W_CT_WR_EN;
assign          W_CT_WR_ACK = V_CT_WR_ACK;    
assign          W_CT_WR_EN  = V_CT_WR_EN;

wire    [7:0] counter, inc_counter, next_counter;
PA_8b   inc_adder(.in0(counter), .in1(8'd1), .s(inc_counter));

wire    state_change;
neq_3b  neq_3b_state_change(.in0({Q2,Q1,Q0}), .in1({D2,D1,D0}), .neq(state_change));

mux2$   mux2$_next_counter[7:0](next_counter, inc_counter, 8'd0, state_change);
dff8$   dff_counter(clk, next_counter, counter, , rst, 1'b1);

eq_6b   done_WR_ACK     (.in0(counter[5:0]), .in1(W_CT_WR_ACK), .eq(CT_WR_ACK));
eq_6b   done_WR_EN      (.in0(counter[5:0]), .in1(W_CT_WR_EN ), .eq(CT_WR_EN ));

/* DMA_config provided by the 4 DMA registers in dmu.v */
wire      [127:0]     DMA_config, buf_data;

/* I/O signals for dma_disk_buffer.v */
wire                  start_xfer;

wire       [31:0]     disk_addr, disk_addr_config, disk_addr_next;
assign                disk_addr_config = DMA_config[31:0];

mux2$   mux2$_disk_addr[31:0](disk_addr_next, disk_addr, disk_addr_config, IN_001);
dff32           dff_disk_addr(.WE({4{clk}}), .D(disk_addr_next), .Q(disk_addr), .QBAR(), .CLR({4{rst}}), .PRE(1'b1));


wire       [31:0]     start_mem_addr, start_mem_addr_config, start_mem_addr_next;
assign                start_mem_addr_config = DMA_config[63:32];

mux2$   mux2$_start_mem_addr[31:0](start_mem_addr_next, start_mem_addr, start_mem_addr_config, IN_001);
dff32           dff_start_mem_addr(.WE({4{clk}}), .D(start_mem_addr_next), .Q(start_mem_addr), .QBAR(), .CLR({4{rst}}), .PRE(1'b1));


wire        [7:0]     buf_addr, buf_addr_next;
wire        [7:0]     buf_addr_inc;

PA_8b     PA_8b_buf_addr_incrementer(
  .in0(buf_addr), .in1(8'h01),
	.s(buf_addr_inc)
);
wire                  inc_trig;
and2$   and2$_inc_trig(inc_trig, IN_011, D2);
mux3$   mux3$_buf_addr[7:0](buf_addr_next, buf_addr, {8{1'b1}}, buf_addr_inc, IN_010, inc_trig);
dff8$          dff_buf_addr(clk, buf_addr_next, buf_addr, , rst, 1'b1);

/* Control counters for the looping DMAC state machine */
wire       [15:0]     bytes_to_transfer_Q;
wire       [11:0]     bytes_to_transfer, bytes_to_transfer_next;
wire       [11:0]     bytes_to_transfer_config;
assign                bytes_to_transfer_config = DMA_config[75:64];
assign                bytes_to_transfer = bytes_to_transfer_Q[11:0];

mux2$   mux2$_bytes_to_transfer[11:0](bytes_to_transfer_next, bytes_to_transfer, bytes_to_transfer_config, IN_001);
dff16$          dff_bytes_to_transfer(clk, {4'b0000, bytes_to_transfer_next}, bytes_to_transfer_Q, , rst, 1'b1);

wire        [7:0]     bursts_left, bursts_left_next;
wire        [7:0]     bursts_left_orig, bursts_left_orig_next;
wire        [7:0]     bursts_left_dec, bursts_left_calc;

PA_8b     PA_8b_bursts_left_decrementer(
  .in0(bursts_left), .in1(8'hFF),
	.s(bursts_left_dec)
);

wire                  unaligned_xfer;
or4$             or4$_unaligned_xfer(unaligned_xfer, bytes_to_transfer[3], bytes_to_transfer[2], bytes_to_transfer[1], bytes_to_transfer[0]);

PA_8b    PA_8b_bursts_left_calculator(
  .in0(bytes_to_transfer[11:4]), .in1({{7{1'b0}}, unaligned_xfer}),
	.s(bursts_left_calc)
);

mux2$   mux2$_bursts_left_orig[7:0](bursts_left_orig_next, bursts_left_orig, bursts_left_calc, IN_010);
dff8$          dff_bursts_left_orig(clk, bursts_left_orig_next, bursts_left_orig, , rst, 1'b1);

mux3$       mux3$_bursts_left[7:0](bursts_left_next, bursts_left, bursts_left_calc, bursts_left_dec, IN_010, inc_trig);
dff8$              dff_bursts_left(clk, bursts_left_next, bursts_left, , rst, 1'b1);

/* BUS DRIVERS */

wire       [31:0]     DATA_FOR_BUS;

mux4$   mux4$_DATA_FOR_BUS[31:0](DATA_FOR_BUS, buf_data[31:0], buf_data[63:32], buf_data[95:64], buf_data[127:96], Q0, Q1);
tristate_bus_driver16$  DATA_BUS_DRIVER_H(.enbar(TRANSFERRING_N), .in(DATA_FOR_BUS[31:16]), .out(DATA_BUS[31:16]));
tristate_bus_driver16$  DATA_BUS_DRIVER_L(.enbar(TRANSFERRING_N), .in(DATA_FOR_BUS[15:0]),  .out(DATA_BUS[15:0]));

wire       [15:0]     ADDR_FOR_BUS_INC, ADDR_FOR_BUS_Q;
wire       [14:4]     ADDR_FOR_BUS, ADDR_FOR_BUS_NEXT, ADDR_FOR_BUS_CALC;
wire       [15:0]     ADDR_FOR_BUS_CALC_FULL;
assign                ADDR_FOR_BUS_CALC = ADDR_FOR_BUS_CALC_FULL[14:4];
assign                ADDR_FOR_BUS = ADDR_FOR_BUS_Q[10:0];

PA_16b    PA_16b_ADDR_adjuster ( 
  .in0({5'b00000, start_mem_addr[14:4]}), .in1({16{1'b1}}),
	.s(ADDR_FOR_BUS_CALC_FULL)
);

PA_16b    PA_16b_ADDR_incrementer ( 
  .in0({5'b00000, ADDR_FOR_BUS}), .in1(16'd1),
	.s(ADDR_FOR_BUS_INC)
);

mux3$       mux3$_ADDR_FOR_BUS[14:4](ADDR_FOR_BUS_NEXT, ADDR_FOR_BUS, ADDR_FOR_BUS_CALC, ADDR_FOR_BUS_INC[10:0], IN_010, inc_trig);
dff16$              dff_ADDR_FOR_BUS(clk, {5'b00000, ADDR_FOR_BUS_NEXT}, ADDR_FOR_BUS_Q, , rst, 1'b1);

wire       [15:0]     ADDR_FOR_BUS_FULL;

assign                ADDR_BUS = ADDR_FOR_BUS_FULL[14:0];

tristate_bus_driver16$  ADDR_BUS_DRIVER(.enbar(TRANSFERRING_N), .in({1'b0, ADDR_FOR_BUS, 4'b0000}),  .out(ADDR_FOR_BUS_FULL));

wire                  FIRST_BURST, LAST_BURST;

wire        [7:0]     bursts_left_orig_m1;

PA_8b    PA_8b_bursts_left_m1_calculator(
  .in0(bursts_left_orig), .in1({8{1'b1}}),
	.s(bursts_left_orig_m1)
);

eq_8b   eq_8b_FIRST_BURST(.in0(bursts_left), .in1(bursts_left_orig_m1), .eq(FIRST_BURST));
eq_8b    eq_8b_LAST_BURST(.in0(bursts_left), .in1(8'd0), .eq(LAST_BURST));

wire       [15:0]   FIRST_WRMASK, LAST_WRMASK_INT, LAST_WRMASK, SHIFTED_FIRST, FIRST_LAST_WRMASK, SHIFTED_FIRST_LAST;

lshf_var_16b  lshf_var_16b_FIRST_WRMASK(
  .in({16{1'b1}}),
  .shf_amt(start_mem_addr[3:0]),
  .out(SHIFTED_FIRST)
);

inv1$   inv1$_FIRST_WRMASK[15:0](FIRST_WRMASK, SHIFTED_FIRST);

lshf_var_16b  lshf_var_16b_LAST_INT_WRMASK(
  .in({16{1'b1}}),
  .shf_amt(bytes_to_transfer[3:0]),
  .out(LAST_WRMASK_INT)
);

lshf_var_16b  lshf_var_16b_LAST_WRMASK(
  .in(LAST_WRMASK_INT),
  .shf_amt(start_mem_addr[3:0]),
  .out(LAST_WRMASK)
);

lshf_var_16b  lshf_var_16b_FIRST_LAST_WRMASK(
  .in(SHIFTED_FIRST),
  .shf_amt(bytes_to_transfer[3:0]),
  .out(SHIFTED_FIRST_LAST)
);

or2$      or2$_FIRST_LAST_WRMASK[15:0](FIRST_LAST_WRMASK, SHIFTED_FIRST_LAST, FIRST_WRMASK);


wire       [15:0]   WRMASK_FOR_BUS;

mux4$     mux4$_WRMASK_FOR_BUS[15:0](WRMASK_FOR_BUS, 16'd0, FIRST_WRMASK, LAST_WRMASK, FIRST_LAST_WRMASK, FIRST_BURST, LAST_BURST);
tristate_bus_driver16$  WRMASK_BUS_DRIVER(.enbar(TRANSFERRING_N), .in(WRMASK_FOR_BUS),  .out(WR_mask));


dmu #(.MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY), .DELAY_ADJ(DELAY_ADJ), .CYCLE_TIME(CYCLE_TIME)) 
      DMU_INST(
                .rst(rst), .clk(clk), .RD(DMA_RD), .WR(DMA_WR),
                .WR_mask(WR_mask),
                .DATA_BUS(DATA_BUS),
                .DMA_config(DMA_config)    
              );

dma_disk_buffer DISK_INST (
                            .clk(clk), .rst(rst), .start_xfer(start_xfer),
                            .disk_addr(disk_addr), .start_mem_addr(start_mem_addr),
                            .buf_addr(buf_addr),

                            .buf_valid(buf_valid),
                            .busy(),

                            .buf_data(buf_data)
                          );

wire          done_xfer;
eq_8b   eq_8b_done_xfer(.in0(bursts_left), .in1(8'd0), .eq(done_xfer));
and2$   and2$_DMA_INT(DMA_INT, done_xfer, IN_111);

wire          TR_INIT_config, TR_INIT_delay, TR_rising, TR_INIT_delay_BAR, TR_INIT_confirm;
assign  TR_INIT_config = DMA_config[96];
dff$    dff$_TR_INIT_delay(clk, TR_INIT_config, TR_INIT_delay, , rst, 1'b1);
inv1$   inv1$_TR_INIT_delay_BAR(TR_INIT_delay_BAR, TR_INIT_delay);
and2$   and2$_TR_INIT_confirm(TR_INIT_confirm, TR_INIT_delay_BAR, TR_INIT_config);


/* Inverters */
wire Q0_bar;
wire DMA_WR_ACK_bar;
inv1$ inv_1(DMA_WR_ACK_bar, DMA_WR_ACK);
wire done_xfer_bar;
inv1$ inv_2(done_xfer_bar, done_xfer);
wire CT_WR_EN_bar;
inv1$ inv_3(CT_WR_EN_bar, CT_WR_EN);
wire Q2_bar;
wire Q1_bar;

/* Product Expressions */
wire and_0_0_out;
and4$ and_0_0(and_0_0_out,Q2_bar,Q1_bar,Q0_bar,TR_INIT_confirm);
wire and_1_0_out;
and4$ and_1_0(and_1_0_out,Q2,Q1_bar,Q0_bar,CT_WR_ACK);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2_bar,Q1,Q0_bar,buf_valid);
wire and_3_0_out;
and4$ and_3_0(and_3_0_out,Q2_bar,Q1,Q0,DMA_WR_ACK);
wire and_4_0_out;
and4$ and_4_0(and_4_0_out,Q2,Q1,Q0_bar,CT_WR_EN);
wire and_5_0_out;
and3$ and_5_0(and_5_0_out,Q2_bar,Q1_bar,Q0_bar);
wire and_6_0_out;
and4$ and_6_0(and_6_0_out,Q2,Q1_bar,Q0,CT_WR_EN);
wire and_7_0_out;
and4$ and_7_0(and_7_0_out,Q2,Q1,Q0,done_xfer_bar);
wire and_8_0_out;
and4$ and_8_0(and_8_0_out,Q2,Q1_bar,Q0,CT_WR_EN_bar);
wire and_9_0_out;
and3$ and_9_0(and_9_0_out,Q2,Q1,Q0);
wire and_10_0_out;
and4$ and_10_0(and_10_0_out,Q2_bar,Q1,Q0,DMA_WR_ACK_bar);
wire and_11_0_out;
and3$ and_11_0(and_11_0_out,Q2_bar,Q1_bar,Q0);
wire and_12_0_out;
and3$ and_12_0(and_12_0_out,Q2,Q1_bar,Q0_bar);
wire and_13_0_out;
and4$ and_13_0(and_13_0_out,Q2,Q1,Q0,CT_WR_EN_bar);
wire and_14_0_out;
and3$ and_14_0(and_14_0_out,Q2_bar,Q1,Q0_bar);
wire and_15_0_out;
and3$ and_15_0(and_15_0_out,Q2,Q1,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
or4$ or_0_0(D2,or_0_1_out,and_3_0_out,and_6_0_out,and_8_0_out);
or3$ or_0_1(or_0_1_out,and_12_0_out,and_13_0_out,and_15_0_out);
wire or_1_1_out;
or4$ or_1_0(D1,or_1_1_out,and_6_0_out,and_7_0_out,and_10_0_out);
or4$ or_1_1(or_1_1_out,and_11_0_out,and_13_0_out,and_14_0_out,and_15_0_out);
wire or_2_1_out;
wire or_2_2_out;
or4$ or_2_0(D0,or_2_1_out,or_2_2_out,and_0_0_out,and_1_0_out);
or4$ or_2_1(or_2_1_out,and_2_0_out,and_4_0_out,and_7_0_out,and_8_0_out);
or2$ or_2_2(or_2_2_out,and_10_0_out,and_13_0_out);
buffer$ buffer_or_3_0(IN_000,and_5_0_out);
buffer$ buffer_or_4_0(IN_001,and_11_0_out);
buffer$ buffer_or_5_0(IN_010,and_14_0_out);
or2$ or_6_0(IN_011,and_3_0_out,and_10_0_out);
buffer$ buffer_or_7_0(IN_100,and_12_0_out);
or2$ or_8_0(IN_101,and_6_0_out,and_8_0_out);
buffer$ buffer_or_9_0(IN_110,and_15_0_out);
buffer$ buffer_or_10_0(IN_111,and_9_0_out);
buffer$ buffer_or_11_0(start_xfer,and_14_0_out);
or2$ or_12_0(DMA_MEM_WR_RQ,and_3_0_out,and_10_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule