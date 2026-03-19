module dmu #(
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
  input     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS,
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS,
  output                            DMAC_BUSY, DATA_VALID_BAR,
  output    [RANK_BIT_WIDTH-1:0]    DMA_config
);

/*** REWRITE COUNTER VALUES AS WIRES ***/

wire    [0:0]   WRITE_DONE     ,
                RD_EN_DONE     ,
                SHORT_BRST_DONE;

wire    [2:0]   W_CT_WRITE_DONE     ,
                W_CT_RD_EN_DONE     ,
                W_CT_SHORT_BRST_DONE;

assign          W_CT_WRITE_DONE       = V_CT_WRITE_DONE     ;
assign          W_CT_RD_EN_DONE       = V_CT_RD_EN_DONE     ;
assign          W_CT_SHORT_BRST_DONE  = V_CT_SHORT_BRST_DONE;

/*** STATE BITS + COUNTER ***/
wire  [2:0] STATE, NEXT_STATE;
wire        Q2,Q1,Q0;
wire        D2,D1,D0;

wire        Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;

bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

wire  [2:0] counter, counter_buf1024;
wire        L2B_CTR;

assign STATE        = {Q2, Q1, Q0};
assign NEXT_STATE   = {D2, D1, D0};

bufferH1024$  bufferH1024$_counter_buf1024[2:0](counter_buf1024, counter);

and2$   and2$_L2B_CTR(L2B_CTR, counter_buf1024[1], counter_buf1024[0]);

/*** STATE MACHINE OUTPUTS ***/
wire    STORE_BUF_LD_EN, STORE_BUF_LD_EN_buf1024;

bufferH1024$  bufferH1024$_STORE_BUF_LD_EN_buf1024(STORE_BUF_LD_EN_buf1024, STORE_BUF_LD_EN);

wire    MEM_ADDR_GATE_ST, MEM_ADDR_GATE_ST_buf16,
        MEM_ADDR_GATE_LD, MEM_ADDR_GATE_LD_buf16,
        MEM_DIO_GATE, MEM_DIO_GATE_buf256,
        DATA_BUS_GATE, DATA_BUS_GATE_buf256;


bufferH16$  bufferH16$_MEM_ADDR_GATE_ST_buf16(MEM_ADDR_GATE_ST_buf16, MEM_ADDR_GATE_ST);
bufferH16$  bufferH16$_MEM_ADDR_GATE_LD_buf16(MEM_ADDR_GATE_LD_buf16, MEM_ADDR_GATE_LD);
bufferH256$ bufferH256$_MEM_DIO_GATE_buf256(MEM_DIO_GATE_buf256, MEM_DIO_GATE);
bufferH256$ bufferH256$_DATA_BUS_GATE_buf256(DATA_BUS_GATE_buf256, DATA_BUS_GATE);

wire    DMAC_BUSY_DRIVER_VALUE;
or3$    or3$_DMAC_BUSY_DRIVER_VALUE(DMAC_BUSY_DRIVER_VALUE, Q2, Q1, Q0);
tristate_bus_driver1$  tristate_bus_driver1$_DMAC_BUSY(.enbar(1'b0), 
                                                      .in(DMAC_BUSY_DRIVER_VALUE), 
                                                      .out(DMAC_BUSY));

wire    DATA_VALID_BAR_DRIVER_VALUE, NOT_DMAC_BUSY_DRIVER_VALUE;
assign  DATA_VALID_BAR_DRIVER_VALUE = DATA_BUS_GATE_buf256;
inv1$   inv1$_NOT_DMAC_BUSY_DRIVER_VALUE(NOT_DMAC_BUSY_DRIVER_VALUE, DMAC_BUSY_DRIVER_VALUE);
tristate_bus_driver1$  tristate_bus_driver1$_DATA_VALID_BAR(.enbar(NOT_DMAC_BUSY_DRIVER_VALUE), 
                                                            .in(DATA_VALID_BAR_DRIVER_VALUE), 
                                                            .out(DATA_VALID_BAR));

/*** STORE BUFFER ***/

/* "STORE BUFFER DATA" (DMA_config) */

wire    [RANK_BIT_WIDTH-1:0]  STORE_BUFFER_DATA, STORE_BUFFER_DATA_WR_EN, STORE_BUFFER_DATA_WR_EN_GATED,
                              SHIFTED_DATA_BUS;

wire    [RANK_BIT_WIDTH-1:0]  DMA_config_WR_mask, DMA_config_WR_mask_bar;

genvar i;
generate
    for (i = 0; i < CHIPS_PER_RANK; i = i + 1) begin : DMA_config_WR_mask_generation
        assign DMA_config_WR_mask[i*8 +: 8] = {8{WR_mask[i]}};
    end
endgenerate

inv1$   inv1$_DMA_config_WR_mask_bar[RANK_BIT_WIDTH-1:0](DMA_config_WR_mask_bar, DMA_config_WR_mask);

mux4$   mux4$_STORE_BUFFER_DATA_WR_EN[RANK_BIT_WIDTH-1:0](STORE_BUFFER_DATA_WR_EN,
                                                          {{96{1'b0}}, {32{1'b1}}},
                                                          {{64{1'b0}}, {32{1'b1}}, {32{1'b0}}},
                                                          {{32{1'b0}}, {32{1'b1}}, {64{1'b0}}},
                                                          {{32{1'b1}}, {96{1'b0}}},
                                                          counter_buf1024[0],
                                                          counter_buf1024[1]);

mux4$   mux4$_SHIFTED_DATA_BUS[RANK_BIT_WIDTH-1:0]        (SHIFTED_DATA_BUS,
                                                          {{96{1'b0}}, DATA_BUS},
                                                          {{64{1'b0}}, DATA_BUS, {32{1'b0}}},
                                                          {{32{1'b0}}, DATA_BUS, {64{1'b0}}},
                                                          {DATA_BUS,   {96{1'b0}}},
                                                          counter_buf1024[0],
                                                          counter_buf1024[1]);

and3$   and3$_STORE_BUFFER_DATA_WR_EN_GATED[RANK_BIT_WIDTH-1:0](STORE_BUFFER_DATA_WR_EN_GATED,
                                                                STORE_BUFFER_DATA_WR_EN,
                                                                {RANK_BIT_WIDTH{STORE_BUF_LD_EN_buf1024}},
                                                                DMA_config_WR_mask_bar);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_DMA_config (
  .clk(clk), .rst(rst),
  .en(STORE_BUFFER_DATA_WR_EN_GATED), .d(SHIFTED_DATA_BUS),
  .q(DMA_config)
);

/*** LOAD BUFFER ***/

/* LOAD BUFFER DATA (just the same DMA config) */

wire    [BUS_BIT_WIDTH-1:0]   DATA_BUS_DRIVER_VALUE;

mux4$   mux4$_DATA_BUS_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (DATA_BUS_DRIVER_VALUE,
                                                        DMA_config[BUS_BIT_WIDTH-1:0],
                                                        DMA_config[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                        DMA_config[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                        DMA_config[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                        counter_buf1024[0],
                                                        counter_buf1024[1]);

tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_H(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[BUS_BIT_WIDTH-1:16]), 
                                                          .out(DATA_BUS[BUS_BIT_WIDTH-1:16]));
                                                                              
tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_L(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[15:0]), 
                                                          .out(DATA_BUS[15:0]));

/* Counter Logic */

wire  [2:0] inc_counter, next_counter;

big_increment #(
  .WIDTH(3)
) big_increment_inc_counter (
  .a(counter_buf1024),
  .s(inc_counter)
);

wire    no_state_change;

big_eq #(
  .WIDTH(3)
) big_eq_no_state_change (
  .in0({Q2,Q1,Q0}), .in1({D2,D1,D0}),
  .eq(no_state_change)
);

wire    state_override, should_inc_counter;

big_eq #(
  .WIDTH(3)
) big_eq_no_state_override (
  .in0({Q2,Q1,Q0}), .in1(3'b101),
  .eq(state_override)
);    

or2$  or2$_should_inc_counter(should_inc_counter, no_state_change, state_override);

mux2$ mux2$_next_counter[2:0](next_counter, 3'b000, inc_counter, should_inc_counter);

reg_n #(
  .WIDTH(3),
  .USE_EN_BAR(0)
) reg_n_counter (
  .clk(clk), .rst(rst),
  .en({3{1'b1}}), .d(next_counter),
  .q(counter)
);

/* "State Done" Counter Comparators */

big_eq  #(.WIDTH(3)) done_WRITE_DONE         (.in0(counter_buf1024), .in1(W_CT_WRITE_DONE     ), .eq(WRITE_DONE     ));
big_eq  #(.WIDTH(3)) done_RD_EN_DONE         (.in0(counter_buf1024), .in1(W_CT_RD_EN_DONE     ), .eq(RD_EN_DONE     ));
big_eq  #(.WIDTH(3)) done_SHORT_BRST_DONE    (.in0(counter_buf1024), .in1(W_CT_SHORT_BRST_DONE), .eq(SHORT_BRST_DONE));

/*** BEGIN AUTO-GENERATED CODE ***/

/* Inverters */
wire Q0_bar;
wire SHORT_BRST_DONE_bar;
inv1$ inv_1(SHORT_BRST_DONE_bar, SHORT_BRST_DONE);
wire Q2_bar;
wire Q1_bar;
wire L2B_CTR_bar;
inv1$ inv_4(L2B_CTR_bar, L2B_CTR);
wire WRITE_DONE_bar;
inv1$ inv_5(WRITE_DONE_bar, WRITE_DONE);

/* Product Expressions */
wire nand_0_0_0_out;
nand3$ nand_0_0_0(nand_0_0_0_out,Q1,Q0_bar,WRITE_DONE_bar);
wire nand_1_0_0_out;
nand3$ nand_1_0_0(nand_1_0_0_out,Q2,Q0_bar,RD_EN_DONE);
wire nand_2_0_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_DMA_WR_ACK);
wire nand_3_0_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR);
wire nand_4_0_0_out;
nand4$ nand_4_0_0(nand_4_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR_bar);
wire nand_5_0_0_out;
nand4$ nand_5_0_0(nand_5_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE);
wire nand_6_0_0_out;
nand4$ nand_6_0_0(nand_6_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE_bar);
wire nand_7_0_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_DMA_RD_ACK);
wire nand_8_0_0_out;
nand3$ nand_8_0_0(nand_8_0_0_out,Q2_bar,Q1,Q0);
wire nand_9_0_0_out;
nand3$ nand_9_0_0(nand_9_0_0_out,Q2,Q1,L2B_CTR_bar);
wire nand_10_0_0_out;
nand2$ nand_10_0_0(nand_10_0_0_out,Q1,Q0);
wire nand_11_0_0_out;
nand3$ nand_11_0_0(nand_11_0_0_out,Q2,Q1_bar,Q0_bar);
wire nand_12_0_0_out;
nand3$ nand_12_0_0(nand_12_0_0_out,Q2,Q1,Q0_bar);
wire nand_13_0_0_out;
inv1$ nand_13_0_0(nand_13_0_0_out, Q2_bar);

/* Sum Expressions */
wire nand_0_1_1_out;
nand4$ nand_0_0_1(D2,nand_0_1_1_out,nand_5_0_0_out,nand_6_0_0_out,nand_8_0_0_out);
and3$ nand_0_1_1(nand_0_1_1_out,nand_9_0_0_out,nand_11_0_0_out,nand_12_0_0_out);
wire nand_1_1_1_out;
nand4$ nand_1_0_1(D1,nand_1_1_1_out,nand_0_0_0_out,nand_3_0_0_out,nand_5_0_0_out);
and3$ nand_1_1_1(nand_1_1_1_out,nand_7_0_0_out,nand_9_0_0_out,nand_12_0_0_out);
wire nand_2_1_1_out;
nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_1_0_0_out,nand_2_0_0_out,nand_4_0_0_out);
and4$ nand_2_1_1(nand_2_1_1_out,nand_6_0_0_out,nand_7_0_0_out,nand_9_0_0_out,nand_12_0_0_out);
nand3$ nand_3_0_1(DATA_BUS_GATE,nand_10_0_0_out,nand_11_0_0_out,nand_13_0_0_out);
nand2$ nand_4_0_1(STORE_BUF_LD_EN,nand_3_0_0_out,nand_4_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule