module dmac #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter CHIP_BYTE_WIDTH=CHIP_BIT_WIDTH/8,
  parameter CHIP_ROW_COUNT=128,
  parameter CHIP_BYTE_CAPACITY=CHIP_ROW_COUNT*CHIP_BYTE_WIDTH,
  parameter CHIP_COUNT=MEM_BYTE_CAPACITY/CHIP_BYTE_CAPACITY,

  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,
  parameter RANK_BYTE_CAPACITY=CHIP_BYTE_CAPACITY*CHIPS_PER_RANK,
  parameter RANK_COUNT=MEM_BYTE_CAPACITY/RANK_BYTE_CAPACITY,
  parameter RANK_IDX_WIDTH=$clog2(RANK_COUNT),
  parameter RANK_ADDR_WIDTH=MEM_ADDR_WIDTH-$clog2(RANK_COUNT)-$clog2(CHIPS_PER_RANK),

  /*  
      Next few parameters are in units of 1e-10 seconds (X10 turns ns (1e-9) into 1e-10).
      The point of multiplying by 10 is to allow cycle time to have increments of 0.1 ns 
      while still using integer math.
  */
  parameter ADDR_SETUP_X10            = 280,  /* Add 3 ns for state transition comb logic delay + buf256 */
  parameter CE_SETUP_X10              = 370,  /* Add 2 ns for state transition comb logic delay */
  parameter DOE_TIME_X10              = 620,  /* Add 2 ns for state transition comb logic delay */
  parameter HZ_TIME_X10               = 175,
  parameter CYCLE_TIME_X10            = 100,

  /* Next few parameters are in units of cycles */
  parameter RD_EN_CYCLES              = ((DOE_TIME_X10 / CYCLE_TIME_X10)   + 1),
  parameter ADDR_EN_TO_WR_EN_CYCLES   = ((ADDR_SETUP_X10  / CYCLE_TIME_X10)   + 1),
  parameter WR_AND_DATA_EN_CYCLES     = ((CE_SETUP_X10  / CYCLE_TIME_X10)   + 1),

  parameter V_CT_WRITE_DONE       = WR_AND_DATA_EN_CYCLES - 1,
  parameter V_CT_RD_EN_DONE       = RD_EN_CYCLES - 1,
  parameter V_CT_SHORT_BRST_DONE  = (RANK_BURST_SIZE - 1) - 1
) (
  input                             rst, clk, 
  input                             DC_DMA_WR_ACK,
  input                             DC_DMA_RD_ACK,
  input     [CHIPS_PER_RANK-1:0]    WR_mask,
  inout     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS,
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS,
  input                             DMA_MEM_WR_ACK,
  output                            DMA_MEM_WR_RQ,
  output                            DMAC_BUSY,
  output                            DATA_VALID_BAR,
  output                            DMA_INT
);

/*** STATE BITS + COUNTER ***/
wire  [2:0] STATE, NEXT_STATE;
wire        Q2,Q1,Q0;
wire        D2,D1,D0;

wire        Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;

bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

assign STATE        = {Q2, Q1, Q0};
assign NEXT_STATE   = {D2, D1, D0};

wire                  IN_000, IN_001, IN_010, IN_011,
                      IN_100, IN_101, IN_110, IN_111;

wire                  IN_000_buf256, IN_001_buf256, IN_010_buf256, IN_011_buf256,
                      IN_100_buf256, IN_101_buf256, IN_110_buf256, IN_111_buf256;

bufferH256$     bufferH256$_IN_000_buf256[2:0](IN_000_buf256, IN_000);
bufferH256$     bufferH256$_IN_001_buf256[2:0](IN_001_buf256, IN_001);
bufferH256$     bufferH256$_IN_010_buf256[2:0](IN_010_buf256, IN_010);
bufferH256$     bufferH256$_IN_011_buf256[2:0](IN_011_buf256, IN_011);
bufferH256$     bufferH256$_IN_100_buf256[2:0](IN_100_buf256, IN_100);
bufferH256$     bufferH256$_IN_101_buf256[2:0](IN_101_buf256, IN_101);
bufferH256$     bufferH256$_IN_110_buf256[2:0](IN_110_buf256, IN_110);
bufferH256$     bufferH256$_IN_111_buf256[2:0](IN_111_buf256, IN_111);

wire                  TRANSFERRING_N, Q2_bar;
assign TRANSFERRING_N = Q2_bar;

/* DMA_config provided by the 4 DMA registers in dmu.v */
wire      [RANK_BIT_WIDTH-1:0]     DMA_config, buf_data;

/* I/O signals for dma_disk_buffer.v */
wire                  start_xfer;

wire       [31:0]     disk_addr, disk_addr_config;
assign                disk_addr_config = DMA_config[31:0];

reg_n #(
  .WIDTH(32),
  .USE_EN_BAR(0)
) reg_n_disk_addr (
  .clk(clk), .rst(rst),
  .en({32{IN_001_buf256}}), .d(disk_addr_config),
  .q(disk_addr)
);


wire       [31:0]     start_mem_addr, start_mem_addr_config;
assign                start_mem_addr_config = DMA_config[63:32];

reg_n #(
  .WIDTH(32),
  .USE_EN_BAR(0)
) reg_n_start_mem_addr (
  .clk(clk), .rst(rst),
  .en({32{IN_001_buf256}}), .d(start_mem_addr_config),
  .q(start_mem_addr)
);


wire        [7:0]     buf_addr, buf_addr_next;
wire        [7:0]     buf_addr_inc;

big_increment #(
  .WIDTH(8)
) big_increment_inc_counter (
  .a(buf_addr),
  .s(buf_addr_inc)
);

wire                  inc_trig;
and2$   and2$_inc_trig(inc_trig, IN_011_buf256, D2);
mux3$   mux3$_buf_addr[7:0](buf_addr_next, buf_addr, {8{1'b1}}, buf_addr_inc, IN_010_buf256, inc_trig);

reg_n #(
  .WIDTH(8),
  .USE_EN_BAR(0)
) reg_n_buf_addr (
  .clk(clk), .rst(rst),
  .en({8{1'b1}}), .d(buf_addr_next),
  .q(buf_addr)
);

/* Control counters for the looping DMAC state machine */
wire       [11:0]     bytes_to_transfer;
wire       [11:0]     bytes_to_transfer_config;
assign                bytes_to_transfer_config = DMA_config[75:64];

reg_n #(
  .WIDTH(12),
  .USE_EN_BAR(0)
) reg_n_bytes_to_transfer (
  .clk(clk), .rst(rst),
  .en({12{IN_001_buf256}}), .d(bytes_to_transfer_config),
  .q(bytes_to_transfer)
);

wire        [7:0]     bursts_left, bursts_left_next;
wire        [7:0]     bursts_left_orig, bursts_left_orig_next;
wire        [7:0]     bursts_left_dec, bursts_left_calc;

big_decrement #(
  .WIDTH(8)
) big_decrement_bursts_left_dec (
  .a(bursts_left),
  .s(bursts_left_dec)
);

wire                  unaligned_xfer;
or4$             or4$_unaligned_xfer(unaligned_xfer, bytes_to_transfer[3], bytes_to_transfer[2], bytes_to_transfer[1], bytes_to_transfer[0]);

PA_8b    PA_8b_bursts_left_calculator(
  .in0(bytes_to_transfer[11:4]), .in1({{7{1'b0}}, unaligned_xfer}),
	.s(bursts_left_calc)
);

mux2$   mux2$_bursts_left_orig[7:0](bursts_left_orig_next, bursts_left_orig, bursts_left_calc, IN_010_buf256);

reg_n #(
  .WIDTH(8),
  .USE_EN_BAR(0)
) reg_n_bursts_left_orig (
  .clk(clk), .rst(rst),
  .en({8{1'b1}}), .d(bursts_left_orig_next),
  .q(bursts_left_orig)
);

mux3$       mux3$_bursts_left[7:0](bursts_left_next, bursts_left, bursts_left_calc, bursts_left_dec, IN_010_buf256, inc_trig);

reg_n #(
  .WIDTH(8),
  .USE_EN_BAR(0)
) reg_n_bursts_left (
  .clk(clk), .rst(rst),
  .en({8{1'b1}}), .d(bursts_left_next),
  .q(bursts_left)
);

/* BUS DRIVERS */

wire       [31:0]     DATA_FOR_BUS;

mux4$   mux4$_DATA_FOR_BUS[31:0](DATA_FOR_BUS, buf_data[31:0], buf_data[63:32], buf_data[95:64], buf_data[127:96], Q0, Q1);
tristate_bus_driver16$  DATA_BUS_DRIVER_H(.enbar(TRANSFERRING_N), .in(DATA_FOR_BUS[31:16]), .out(DATA_BUS[31:16]));
tristate_bus_driver16$  DATA_BUS_DRIVER_L(.enbar(TRANSFERRING_N), .in(DATA_FOR_BUS[15:0]),  .out(DATA_BUS[15:0]));

wire       [14:4]     ADDR_FOR_BUS_INC;
wire       [14:4]     ADDR_FOR_BUS, ADDR_FOR_BUS_NEXT, ADDR_FOR_BUS_CALC;

big_decrement #(
  .WIDTH(11)
) big_decrement_ADDR_FOR_BUS_CALC (
  .a(start_mem_addr[14:4]),
  .s(ADDR_FOR_BUS_CALC)
);

big_increment #(
  .WIDTH(11)
) big_increment_ADDR_FOR_BUS_CALC (
  .a(ADDR_FOR_BUS),
  .s(ADDR_FOR_BUS_INC)
);

mux3$       mux3$_ADDR_FOR_BUS[14:4](ADDR_FOR_BUS_NEXT, ADDR_FOR_BUS, ADDR_FOR_BUS_CALC, ADDR_FOR_BUS_INC, IN_010_buf256, inc_trig);

reg_n #(
  .WIDTH(11),
  .USE_EN_BAR(0)
) reg_n_ADDR_FOR_BUS (
  .clk(clk), .rst(rst),
  .en({11{1'b1}}), .d(ADDR_FOR_BUS_NEXT),
  .q(ADDR_FOR_BUS)
);

tristate_bus_driver1$  ADDR_BUS_DRIVER[MEM_ADDR_WIDTH-1:0](.enbar(TRANSFERRING_N), .in({ADDR_FOR_BUS, 4'b0000}),  .out(ADDR_BUS));

wire                  FIRST_BURST, LAST_BURST;

wire        [7:0]     bursts_left_orig_m1;

big_decrement #(
  .WIDTH(8)
) big_decrement_bursts_left_orig_m1 (
  .a(bursts_left_orig),
  .s(bursts_left_orig_m1)
);

big_eq #(
  .WIDTH(8)
) big_eq_FIRST_BURST (
  .in0(bursts_left), .in1(bursts_left_orig_m1),
  .eq(FIRST_BURST)
);

big_eq #(
  .WIDTH(8)
) big_eq_LAST_BURST (
  .in0(bursts_left), .in1(8'd0),
  .eq(LAST_BURST)
);

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


dmu #(.CYCLE_TIME_X10(CYCLE_TIME_X10)) DMU_inst (
  .rst          (rst          )    , .clk(clk), 
  .DC_DMA_WR_ACK(DC_DMA_WR_ACK)      ,
  .DC_DMA_RD_ACK(DC_DMA_RD_ACK)      , 
  .WR_mask      (WR_mask      )    ,
  .ADDR_BUS     (ADDR_BUS     )    ,
  .DATA_BUS     (DATA_BUS     )    ,
  .DMAC_BUSY      (DMAC_BUSY     )     , .DATA_VALID_BAR(DATA_VALID_BAR), .DMA_config(DMA_config)
);

dma_disk_buffer DISK_INST (
                            .clk(clk), .rst(rst), .start_xfer(start_xfer),
                            .disk_addr(disk_addr), .start_mem_addr(start_mem_addr),
                            .buf_addr(buf_addr),

                            .buf_valid(buf_valid),
                            .busy(),

                            .buf_data(buf_data)
                          );

wire      DMA_INT_FOR_BUS;

and2$   and2$_DMA_INT_FOR_BUS(DMA_INT_FOR_BUS, LAST_BURST, IN_111_buf256);

tristate_bus_driver1$ tristate_bus_driver1$_DMA_INT(.enbar(1'b0), .in(DMA_INT_FOR_BUS), .out(DMA_INT));

wire      DMA_MEM_WR_RQ_FOR_BUS;

tristate_bus_driver1$ tristate_bus_driver1$_DMA_MEM_WR_RQ(.enbar(1'b0), .in(DMA_MEM_WR_RQ_FOR_BUS), .out(DMA_MEM_WR_RQ));

wire          TR_INIT_config, TR_INIT_delay, TR_rising, TR_INIT_delay_BAR, TR_INIT_confirm;
wire          nonzero_bytes_to_transfer;

big_or #(
  .WIDTH(12)
) big_or_nonzero_bytes_to_transfer (
  .out(nonzero_bytes_to_transfer),
  .in(bytes_to_transfer_config)
);

assign  TR_INIT_config = DMA_config[96];
dff$    dff$_TR_INIT_delay(clk, TR_INIT_config, TR_INIT_delay, , rst, 1'b1);
inv1$   inv1$_TR_INIT_delay_BAR(TR_INIT_delay_BAR, TR_INIT_delay);
and3$   and3$_TR_INIT_confirm(TR_INIT_confirm, TR_INIT_delay_BAR, TR_INIT_config, nonzero_bytes_to_transfer);

/* Inverters */
wire Q0_bar;
wire Q1_bar;
wire DMA_MEM_WR_ACK_bar;
inv1$ inv_2(DMA_MEM_WR_ACK_bar, DMA_MEM_WR_ACK);
wire LAST_BURST_bar;
inv1$ inv_3(LAST_BURST_bar, LAST_BURST);

/* Product Expressions */
wire nand_0_0_0_out;
nand3$ nand_0_0_0(nand_0_0_0_out,Q1_bar,Q0_bar,TR_INIT_confirm);
wire nand_1_0_0_out;
nand3$ nand_1_0_0(nand_1_0_0_out,Q1,Q0_bar,buf_valid);
wire nand_2_0_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,Q2_bar,Q1,Q0,DMA_MEM_WR_ACK);
wire nand_3_0_0_out;
nand3$ nand_3_0_0(nand_3_0_0_out,Q2,Q1,LAST_BURST_bar);
wire nand_4_0_0_out;
nand3$ nand_4_0_0(nand_4_0_0_out,Q2_bar,Q1_bar,Q0_bar);
wire nand_5_0_0_out;
nand3$ nand_5_0_0(nand_5_0_0_out,Q2,Q1,Q0);
wire nand_6_0_0_out;
nand3$ nand_6_0_0(nand_6_0_0_out,Q2_bar,Q1_bar,Q0);
wire nand_7_0_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1,Q0,DMA_MEM_WR_ACK_bar);
wire nand_8_0_0_out;
nand3$ nand_8_0_0(nand_8_0_0_out,Q2,Q1_bar,Q0_bar);
wire nand_9_0_0_out;
nand3$ nand_9_0_0(nand_9_0_0_out,Q2,Q1_bar,Q0);
wire nand_10_0_0_out;
nand3$ nand_10_0_0(nand_10_0_0_out,Q2_bar,Q1,Q0_bar);
wire nand_11_0_0_out;
nand3$ nand_11_0_0(nand_11_0_0_out,Q2,Q1,Q0_bar);

/* Sum Expressions */
nand4$ nand_0_0_1(D2,nand_2_0_0_out,nand_8_0_0_out,nand_9_0_0_out,nand_11_0_0_out);
wire nand_1_1_1_out;
nand4$ nand_1_0_1(D1,nand_1_1_1_out,nand_3_0_0_out,nand_6_0_0_out,nand_7_0_0_out);
and3$ nand_1_1_1(nand_1_1_1_out,nand_9_0_0_out,nand_10_0_0_out,nand_11_0_0_out);
wire nand_2_1_1_out;
nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_0_0_0_out,nand_1_0_0_out,nand_3_0_0_out);
and3$ nand_2_1_1(nand_2_1_1_out,nand_7_0_0_out,nand_8_0_0_out,nand_11_0_0_out);
inv1$ nand_3_0_1(IN_000, nand_4_0_0_out);
inv1$ nand_4_0_1(IN_001, nand_6_0_0_out);
inv1$ nand_5_0_1(IN_010, nand_10_0_0_out);
nand2$ nand_6_0_1(IN_011,nand_2_0_0_out,nand_7_0_0_out);
inv1$ nand_7_0_1(IN_100, nand_8_0_0_out);
inv1$ nand_8_0_1(IN_101, nand_9_0_0_out);
inv1$ nand_9_0_1(IN_110, nand_11_0_0_out);
inv1$ nand_10_0_1(IN_111, nand_5_0_0_out);
inv1$ nand_11_0_1(start_xfer, nand_10_0_0_out);
nand2$ nand_12_0_1(DMA_MEM_WR_RQ_FOR_BUS,nand_2_0_0_out,nand_7_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule