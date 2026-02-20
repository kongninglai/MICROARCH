module mmu #(
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

  parameter V_CT_ADDR_DATA    = ADDR_EN_TO_WR_EN_CYCLES - 1,
  parameter V_CT_WR_EN        = WR_AND_DATA_EN_CYCLES - 1,
  parameter V_CT_RD_EN        = RD_EN_CYCLES - 1,
  parameter V_CT_SHORT_RD_EN  = (RD_EN_CYCLES - RANK_BURST_SIZE) - 1,
  parameter V_CT_SHORT_BRST   = (RANK_BURST_SIZE - 1) - 1
) (
  input                             rst, clk, 
  input                             DC_MEM_WR_ACK, DMA_MEM_WR_ACK,
  input                             DC_MEM_RD_ACK, IC_MEM_RD_ACK,
  input     [CHIPS_PER_RANK-1:0]    WR_mask,
  input     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS,
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS,
  output                            MEM_BUSY
);

wire    [0:0]   ADDR_DATA_DONE,
                WR_EN_DONE,
                RD_EN_DONE,
                SHORT_RD_EN_DONE,
                SHORT_BRST_DONE;

wire    [2:0]   W_CT_ADDR_DATA  ,
                W_CT_WR_EN      ,
                W_CT_RD_EN      ,
                W_CT_SHORT_RD_EN,
                W_CT_SHORT_BRST ;

assign          W_CT_ADDR_DATA   = V_CT_ADDR_DATA   ;  
assign          W_CT_WR_EN       = V_CT_WR_EN       ;  
assign          W_CT_RD_EN       = V_CT_RD_EN       ;  
assign          W_CT_SHORT_RD_EN = V_CT_SHORT_RD_EN ;  
assign          W_CT_SHORT_BRST  = V_CT_SHORT_BRST  ;

wire    [RANK_BIT_WIDTH-1:0]  DIO;

wire        Q3,Q2,Q1,Q0;
wire        D3,D2,D1,D0;
wire  [2:0] counter;

nor4$   nor4$_MEM_BUSY(MEM_BUSY, Q3, Q2, Q1, Q0);


/* STORE BUFFER */

wire    [RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH-1:0]  STORE_BUFFER_ADDR_CALC, STORE_BUFFER_ADDR;

wire    STORE_BUF_LD_EN_buf16;
bufferH16$    bufferH16$_STORE_BUF_LD_EN_buf16(STORE_BUF_LD_EN_buf16, STORE_BUF_LD_EN);

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_STORE_BUFFER_ADDR (
  .clk(clk), .rst(rst),
  .en({RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH{STORE_BUF_LD_EN_buf16}}), .d(STORE_BUFFER_ADDR_CALC),
  .q(STORE_BUFFER_ADDR)
);

wire    [RANK_COUNT*CHIPS_PER_RANK*RANK_ADDR_WIDTH-1:0]  STORE_BUFFER_ADDR_CALC_IDENTICAL, STORE_BUFFER_ADDR_CALC_DIFFERENT;

assign STORE_BUFFER_ADDR_CALC_IDENTICAL = {RANK_COUNT*CHIPS_PER_RANK{ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]}};

wire    [RANK_ADDR_WIDTH-1:0]   INCREMENTED_RANK_ADDR;

big_increment #(
  .WIDTH(RANK_ADDR_WIDTH)
) big_increment_INCREMENTED_RANK_ADDR (
  .a(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .s(INCREMENTED_RANK_ADDR)
);

assign  STORE_BUFFER_ADDR_CALC_DIFFERENT = {{((RANK_COUNT-1)*CHIPS_PER_RANK){ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]}},
                                            {CHIPS_PER_RANK{INCREMENTED_RANK_ADDR}}};

wire    [RANK_COUNT*CHIPS_PER_RANK-1:0]  STORE_BUFFER_WR_CALC, STORE_BUFFER_WR;

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_STORE_BUFFER_WR (
  .clk(clk), .rst(rst),
  .en(STORE_BUF_LD_EN), .d(STORE_BUFFER_WR_CALC),
  .q(STORE_BUFFER_WR)
);

big_eq  #(.WIDTH(3)) done_ADDR_DATA    (.in0(counter), .in1(W_CT_ADDR_DATA  ), .eq(CT_HIZ_PROT));
big_eq  #(.WIDTH(3)) done_WR_EN        (.in0(counter), .in1(W_CT_WR_EN      ), .eq(CT_RD_EN   ));
big_eq  #(.WIDTH(3)) done_RD_EN        (.in0(counter), .in1(W_CT_RD_EN      ), .eq(CT_RD_BRST ));
big_eq  #(.WIDTH(3)) done_SHORT_RD_EN  (.in0(counter), .in1(W_CT_SHORT_RD_EN), .eq(CT_BUS_FREE));
big_eq  #(.WIDTH(3)) done_SHORT_BRST   (.in0(counter), .in1(W_CT_SHORT_BRST ), .eq(CT_WR_ADDR ));

/* Inverters */
wire Q2_bar;
wire Q3_bar;
wire WR_EN_DONE_bar;
inv1$ inv_2(WR_EN_DONE_bar, WR_EN_DONE);
wire Q1_bar;
wire Q0_bar;
wire L2B_CTR_bar;
inv1$ inv_5(L2B_CTR_bar, L2B_CTR);
wire SHORT_BRST_DONE_bar;
inv1$ inv_6(SHORT_BRST_DONE_bar, SHORT_BRST_DONE);

/* Product Expressions */
wire and_0_0_out;
and3$ and_0_0(and_0_0_out,Q3,Q2,L2B_CTR_bar);
wire and_1_0_out;
and4$ and_1_0(and_1_0_out,Q3,Q2,Q0_bar,SHORT_RD_EN_DONE);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2,Q1,Q0_bar,RD_EN_DONE);
wire and_3_0_out;
wire and_3_1_out;
and4$ and_3_0(and_3_0_out,and_3_1_out,Q3_bar,Q2_bar,Q1);
and2$ and_3_1(and_3_1_out,Q0_bar,ADDR_DATA_DONE);
wire and_4_0_out;
wire and_4_1_out;
and4$ and_4_0(and_4_0_out,and_4_1_out,Q3_bar,Q2_bar,Q1);
and2$ and_4_1(and_4_1_out,Q0,WR_EN_DONE_bar);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q2,Q1,Q0,L2B_CTR_bar);
wire and_6_0_out;
and3$ and_6_0(and_6_0_out,Q3_bar,Q2_bar,Q0);
wire and_7_0_out;
wire and_7_1_out;
and4$ and_7_0(and_7_0_out,and_7_1_out,Q3,Q2_bar,Q1);
and2$ and_7_1(and_7_1_out,Q0_bar,L2B_CTR);
wire and_8_0_out;
wire and_8_1_out;
and4$ and_8_0(and_8_0_out,and_8_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_8_1(and_8_1_out,Q0,L2B_CTR);
wire and_9_0_out;
wire and_9_1_out;
and4$ and_9_0(and_9_0_out,and_9_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_9_1(and_9_1_out,Q0,L2B_CTR_bar);
wire and_10_0_out;
wire and_10_1_out;
and4$ and_10_0(and_10_0_out,and_10_1_out,Q3,Q2,Q1_bar);
and2$ and_10_1(and_10_1_out,Q0,SHORT_BRST_DONE);
wire and_11_0_out;
wire and_11_1_out;
and4$ and_11_0(and_11_0_out,and_11_1_out,Q3,Q2,Q1_bar);
and2$ and_11_1(and_11_1_out,Q0,SHORT_BRST_DONE_bar);
wire and_12_0_out;
and4$ and_12_0(and_12_0_out,Q3,Q2_bar,Q0_bar,L2B_CTR_bar);
wire and_13_0_out;
and4$ and_13_0(and_13_0_out,Q3_bar,Q2_bar,Q1,Q0_bar);
wire and_14_0_out;
and4$ and_14_0(and_14_0_out,Q3,Q2,Q1_bar,Q0_bar);
wire and_15_0_out;
and4$ and_15_0(and_15_0_out,Q3_bar,Q2,Q1,Q0_bar);
wire and_16_0_out;
wire and_16_1_out;
and4$ and_16_0(and_16_0_out,and_16_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_16_1(and_16_1_out,Q0_bar,DMA_MEM_WR_ACK);
wire and_17_0_out;
wire and_17_1_out;
and4$ and_17_0(and_17_0_out,and_17_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_17_1(and_17_1_out,Q0_bar,DC_MEM_WR_ACK);
wire and_18_0_out;
and4$ and_18_0(and_18_0_out,Q3,Q2,Q1,Q0_bar);
wire and_19_0_out;
and3$ and_19_0(and_19_0_out,Q2,Q1,Q0);
wire and_20_0_out;
wire and_20_1_out;
and4$ and_20_0(and_20_0_out,and_20_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_20_1(and_20_1_out,Q0_bar,DC_MEM_RD_ACK);
wire and_21_0_out;
and4$ and_21_0(and_21_0_out,Q2_bar,Q1_bar,Q0_bar,IC_MEM_RD_ACK);
wire and_22_0_out;
and4$ and_22_0(and_22_0_out,Q3_bar,Q2,Q1_bar,Q0);
wire and_23_0_out;
and4$ and_23_0(and_23_0_out,Q3,Q2_bar,Q1_bar,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
wire or_0_2_out;
or4$ or_0_0(D3,or_0_1_out,or_0_2_out,and_0_0_out,and_7_0_out);
or4$ or_0_1(or_0_1_out,and_10_0_out,and_11_0_out,and_12_0_out,and_14_0_out);
or3$ or_0_2(or_0_2_out,and_18_0_out,and_21_0_out,and_23_0_out);
wire or_1_1_out;
wire or_1_2_out;
or4$ or_1_0(D2,or_1_1_out,or_1_2_out,and_5_0_out,and_7_0_out);
or4$ or_1_1(or_1_1_out,and_10_0_out,and_11_0_out,and_14_0_out,and_15_0_out);
or3$ or_1_2(or_1_2_out,and_18_0_out,and_20_0_out,and_22_0_out);
wire or_2_1_out;
wire or_2_2_out;
or4$ or_2_0(D1,or_2_1_out,or_2_2_out,and_4_0_out,and_5_0_out);
or4$ or_2_1(or_2_1_out,and_8_0_out,and_10_0_out,and_12_0_out,and_13_0_out);
or4$ or_2_2(or_2_2_out,and_15_0_out,and_18_0_out,and_22_0_out,and_23_0_out);
wire or_3_1_out;
wire or_3_2_out;
wire or_3_3_out;
or4$ or_3_0(D0,or_3_1_out,or_3_2_out,or_3_3_out,and_1_0_out);
or4$ or_3_1(or_3_1_out,and_2_0_out,and_3_0_out,and_4_0_out,and_5_0_out);
or4$ or_3_2(or_3_2_out,and_9_0_out,and_11_0_out,and_16_0_out,and_17_0_out);
or2$ or_3_3(or_3_3_out,and_18_0_out,and_20_0_out);
wire or_4_1_out;
wire or_4_2_out;
wire or_4_3_out;
or4$ or_4_0(CE_GATE,or_4_1_out,or_4_2_out,or_4_3_out,and_8_0_out);
or4$ or_4_1(or_4_1_out,and_9_0_out,and_10_0_out,and_11_0_out,and_13_0_out);
or4$ or_4_2(or_4_2_out,and_16_0_out,and_17_0_out,and_19_0_out,and_20_0_out);
or3$ or_4_3(or_4_3_out,and_21_0_out,and_22_0_out,and_23_0_out);
wire or_5_1_out;
wire or_5_2_out;
wire or_5_3_out;
or4$ or_5_0(OE_GATE,or_5_1_out,or_5_2_out,or_5_3_out,and_6_0_out);
or4$ or_5_1(or_5_1_out,and_10_0_out,and_11_0_out,and_13_0_out,and_16_0_out);
or4$ or_5_2(or_5_2_out,and_17_0_out,and_19_0_out,and_20_0_out,and_21_0_out);
or2$ or_5_3(or_5_3_out,and_22_0_out,and_23_0_out);
wire or_6_1_out;
wire or_6_2_out;
wire or_6_3_out;
wire or_6_4_out;
wire or_6_5_out;
or4$ or_6_0(WR_GATE,or_6_1_out,or_6_2_out,or_6_3_out,or_6_4_out);
or4$ or_6_1(or_6_1_out,and_7_0_out,and_8_0_out,and_9_0_out,and_10_0_out);
or4$ or_6_2(or_6_2_out,and_11_0_out,and_12_0_out,and_13_0_out,and_14_0_out);
or4$ or_6_3(or_6_3_out,and_15_0_out,and_16_0_out,and_17_0_out,and_18_0_out);
or4$ or_6_4(or_6_4_out,and_19_0_out,and_20_0_out,and_21_0_out,or_6_5_out);
or2$ or_6_5(or_6_5_out,and_22_0_out,and_23_0_out);
wire or_7_1_out;
wire or_7_2_out;
or4$ or_7_0(MEM_ADDR_GATE,or_7_1_out,or_7_2_out,and_8_0_out,and_9_0_out);
or4$ or_7_1(or_7_1_out,and_16_0_out,and_17_0_out,and_19_0_out,and_20_0_out);
or3$ or_7_2(or_7_2_out,and_21_0_out,and_22_0_out,and_23_0_out);
wire or_8_1_out;
wire or_8_2_out;
wire or_8_3_out;
wire or_8_4_out;
or4$ or_8_0(MEM_DIO_GATE,or_8_1_out,or_8_2_out,or_8_3_out,or_8_4_out);
or4$ or_8_1(or_8_1_out,and_7_0_out,and_8_0_out,and_9_0_out,and_10_0_out);
or4$ or_8_2(or_8_2_out,and_11_0_out,and_12_0_out,and_14_0_out,and_15_0_out);
or4$ or_8_3(or_8_3_out,and_16_0_out,and_17_0_out,and_18_0_out,and_19_0_out);
or4$ or_8_4(or_8_4_out,and_20_0_out,and_21_0_out,and_22_0_out,and_23_0_out);
wire or_9_1_out;
wire or_9_2_out;
wire or_9_3_out;
or4$ or_9_0(DATA_BUS_GATE,or_9_1_out,or_9_2_out,or_9_3_out,and_6_0_out);
or4$ or_9_1(or_9_1_out,and_7_0_out,and_12_0_out,and_13_0_out,and_14_0_out);
or4$ or_9_2(or_9_2_out,and_15_0_out,and_16_0_out,and_17_0_out,and_20_0_out);
or3$ or_9_3(or_9_3_out,and_21_0_out,and_22_0_out,and_23_0_out);
or2$ or_10_0(STORE_BUF_LD_EN,and_8_0_out,and_9_0_out);
or3$ or_11_0(LOAD_BUF_LD_EN,and_14_0_out,and_15_0_out,and_18_0_out);
or2$ or_12_0(LOAD_ADDR_LD_EN,and_22_0_out,and_23_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);
dff$ dff_3(clk, D3, Q3, Q3_bar, rst, 1'b1);

endmodule