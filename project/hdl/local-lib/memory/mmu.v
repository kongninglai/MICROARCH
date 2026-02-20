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

  parameter V_CT_WRITE_DONE       = (ADDR_EN_TO_WR_EN_CYCLES + WR_AND_DATA_EN_CYCLES) - 1,
  parameter V_CT_RD_EN_DONE       = RD_EN_CYCLES - 1,
  parameter V_CT_SHORT_BRST_DONE  = RANK_BURST_SIZE - 1
) (
  input                             rst, clk, 
  input                             DC_MEM_WR_ACK, DMA_MEM_WR_ACK,
  input                             DC_MEM_RD_ACK, IC_MEM_RD_ACK,
  input     [CHIPS_PER_RANK-1:0]    WR_mask,
  input     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS,
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS,
  output                            MEM_BUSY
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

/*** DATA TO MAIN MEMORY ***/
wire    [RANK_BIT_WIDTH-1:0]  DIO;

/*** STATE BITS + COUNTER ***/
wire  [3:0] STATE, NEXT_STATE;
wire        Q3,Q2,Q1,Q0;
wire        D3,D2,D1,D0;
wire  [2:0] counter, counter_buf1024;
wire        L2B_CTR;

assign STATE        = {Q3, Q2, Q1, Q0};
assign NEXT_STATE   = {D3, D2, D1, D0};

bufferH1024$  bufferH1024$_counter_buf1024[2:0](counter_buf1024, counter);

and2$   and2$_L2B_CTR(L2B_CTR, counter_buf1024[1], counter_buf1024[0]);

/*** STATE MACHINE OUTPUTS ***/
wire    STORE_BUF_LD_EN, STORE_BUF_LD_EN_buf1024;
wire    LOAD_BUF_LD_EN , LOAD_BUF_LD_EN_buf1024;
wire    LOAD_ADDR_LD_EN, LOAD_ADDR_LD_EN_buf1024;

bufferH1024$  bufferH1024$_STORE_BUF_LD_EN_buf1024(STORE_BUF_LD_EN_buf1024, STORE_BUF_LD_EN);
bufferH1024$  bufferH1024$_LOAD_BUF_LD_EN_buf1024 (LOAD_BUF_LD_EN_buf1024,  LOAD_BUF_LD_EN);
bufferH1024$  bufferH1024$_LOAD_ADDR_LD_EN_buf1024(LOAD_ADDR_LD_EN_buf1024, LOAD_ADDR_LD_EN);

wire    MEM_ADDR_GATE_ST,
        MEM_ADDR_GATE_LD,
        MEM_DIO_GATE,
        DATA_BUS_GATE;

or4$    or4$_MEM_BUSY(MEM_BUSY, Q3, Q2, Q1, Q0);

/*** STORE BUFFER ***/

/* STORE BUFFER ADDRESS FOR ALL RANKS */

wire    [RANK_ADDR_WIDTH-1:0]  STORE_BUFFER_A_RANK0, STORE_BUFFER_A_RANK0_CALC, STORE_BUFFER_A_OTHERS;

assign STORE_BUFFER_A_RANK0_CALC  = ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH];

reg_n #(
  .WIDTH(RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_STORE_BUFFER_A_RANK0 (
  .clk(clk), .rst(rst),
  .en({RANK_ADDR_WIDTH{STORE_BUF_LD_EN_buf1024}}), .d(STORE_BUFFER_A_RANK0_CALC),
  .q(STORE_BUFFER_A_RANK0)
);

assign STORE_BUFFER_A_OTHERS = STORE_BUFFER_A_RANK0;

/* STORE BUFFER MEM CTRL (WR, OE, CE) */

wire    [RANK_COUNT*CHIPS_PER_RANK-1:0]  STORE_BUFFER_WR_CALC, STORE_BUFFER_WR, STORE_BUFFER_CE, STORE_BUFFER_OE;

lshf_chunks_var_256b lshf_chunks_var_256b_STORE_BUFFER_WR (
  .in({{(RANK_COUNT-1)*CHIPS_PER_RANK{1'b1}}, WR_mask}),
  .shf_amt(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]),
  .out(STORE_BUFFER_WR_CALC)
);

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_STORE_BUFFER_WR (
  .clk(clk), .rst(rst),
  .en({RANK_COUNT*CHIPS_PER_RANK{STORE_BUF_LD_EN_buf1024}}), .d(STORE_BUFFER_WR_CALC),
  .q(STORE_BUFFER_WR)
);

assign STORE_BUFFER_CE = STORE_BUFFER_WR;
assign STORE_BUFFER_OE = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};

/* STORE BUFFER DATA (DESERIALIZER) */

wire    [RANK_BIT_WIDTH-1:0]  STORE_BUFFER_DATA, STORE_BUFFER_DATA_WR_EN, STORE_BUFFER_DATA_WR_EN_GATED,
                              SHIFTED_DATA_BUS;

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

and2$   and2$_STORE_BUFFER_DATA_WR_EN_GATED[RANK_BIT_WIDTH-1:0](STORE_BUFFER_DATA_WR_EN_GATED,
                                                                STORE_BUFFER_DATA_WR_EN,
                                                                {RANK_BIT_WIDTH{STORE_BUF_LD_EN_buf1024}});

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_STORE_BUFFER_DATA (
  .clk(clk), .rst(rst),
  .en(STORE_BUFFER_DATA_WR_EN_GATED), .d(SHIFTED_DATA_BUS),
  .q(STORE_BUFFER_DATA)
);

/*** LOAD BUFFER ***/

/* LOAD BUFFER ADDRESS FOR RANK 0 */

wire    [RANK_ADDR_WIDTH-1:0]  LOAD_BUFFER_A_RANK0, LOAD_BUFFER_A_RANK0_CALC;

reg_n #(
  .WIDTH(RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_A_RANK0 (
  .clk(clk), .rst(rst),
  .en({RANK_ADDR_WIDTH{LOAD_BUF_LD_EN_buf1024}}), .d(LOAD_BUFFER_A_RANK0_CALC),
  .q(LOAD_BUFFER_A_RANK0)
);

wire    [RANK_ADDR_WIDTH-1:0]   INCREMENTED_A_RANK0;

big_increment #(
  .WIDTH(RANK_ADDR_WIDTH)
) big_increment_INCREMENTED_RANK_ADDR (
  .a(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .s(INCREMENTED_A_RANK0)
);

wire    LAST_RANK_ACTIVE;

and4$   and4$_LAST_RANK_ACTIVE(LAST_RANK_ACTIVE,  ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1],
                                                  ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-2],
                                                  ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-3],
                                                  ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]);

wire    LAST_RANK_ACTIVE_buf16;

bufferH16$  bufferH16$_LAST_RANK_ACTIVE_buf16(LAST_RANK_ACTIVE_buf16, LAST_RANK_ACTIVE);

mux2$   mux2$_LOAD_BUFFER_A_RANK0_CALC[RANK_ADDR_WIDTH-1:0](  LOAD_BUFFER_A_RANK0_CALC,
                                                              ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH],
                                                              INCREMENTED_A_RANK0,
                                                              LAST_RANK_ACTIVE_buf16);

/* LOAD BUFFER ADDRESS FOR OTHER RANKS */

wire    [RANK_ADDR_WIDTH-1:0]  LOAD_BUFFER_A_OTHERS;

reg_n #(
  .WIDTH(RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_A_OTHERS (
  .clk(clk), .rst(rst),
  .en({RANK_ADDR_WIDTH{LOAD_BUF_LD_EN_buf1024}}), .d(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .q(LOAD_BUFFER_A_OTHERS)
);

/* "State Done" Counter Comparators */

big_eq  #(.WIDTH(3)) done_WRITE_DONE         (.in0(counter_buf1024), .in1(W_CT_WRITE_DONE     ), .eq(WRITE_DONE     ));
big_eq  #(.WIDTH(3)) done_RD_EN_DONE         (.in0(counter_buf1024), .in1(W_CT_RD_EN_DONE     ), .eq(RD_EN_DONE     ));
big_eq  #(.WIDTH(3)) done_SHORT_BRST_DONE    (.in0(counter_buf1024), .in1(W_CT_SHORT_BRST_DONE), .eq(SHORT_BRST_DONE));

/*** BEGIN AUTO-GENERATED CODE ***/

 /* Inverters */
wire L2B_CTR_bar;
inv1$ inv_0(L2B_CTR_bar, L2B_CTR);
wire Q1_bar;
wire WRITE_DONE_bar;
inv1$ inv_2(WRITE_DONE_bar, WRITE_DONE);
wire RD_EN_DONE_bar;
inv1$ inv_3(RD_EN_DONE_bar, RD_EN_DONE);
wire Q3_bar;
wire Q0_bar;
wire Q2_bar;

/* Product Expressions */
wire and_0_0_out;
and4$ and_0_0(and_0_0_out,Q2_bar,Q1,Q0_bar,WRITE_DONE_bar);
wire and_1_0_out;
wire and_1_1_out;
and4$ and_1_0(and_1_0_out,and_1_1_out,Q3_bar,Q2,Q1);
and2$ and_1_1(and_1_1_out,Q0_bar,L2B_CTR_bar);
wire and_2_0_out;
wire and_2_1_out;
and4$ and_2_0(and_2_0_out,and_2_1_out,Q3,Q2,Q1_bar);
and2$ and_2_1(and_2_1_out,Q0_bar,L2B_CTR_bar);
wire and_3_0_out;
and4$ and_3_0(and_3_0_out,Q3,Q2_bar,Q0_bar,SHORT_BRST_DONE);
wire and_4_0_out;
and4$ and_4_0(and_4_0_out,Q3_bar,Q2_bar,Q1,Q0_bar);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q3_bar,Q2,Q1_bar,Q0_bar);
wire and_6_0_out;
wire and_6_1_out;
and4$ and_6_0(and_6_0_out,and_6_1_out,Q3_bar,Q2,Q1_bar);
and2$ and_6_1(and_6_1_out,Q0,RD_EN_DONE);
wire and_7_0_out;
and4$ and_7_0(and_7_0_out,Q3,Q2_bar,Q1,Q0);
wire and_8_0_out;
and4$ and_8_0(and_8_0_out,Q3,Q2_bar,Q1,Q0_bar);
wire and_9_0_out;
wire and_9_1_out;
and4$ and_9_0(and_9_0_out,and_9_1_out,Q3,Q2_bar,Q1_bar);
and2$ and_9_1(and_9_1_out,Q0,RD_EN_DONE);
wire and_10_0_out;
wire and_10_1_out;
and4$ and_10_0(and_10_0_out,and_10_1_out,Q3_bar,Q2,Q1_bar);
and2$ and_10_1(and_10_1_out,Q0,RD_EN_DONE_bar);
wire and_11_0_out;
wire and_11_1_out;
and4$ and_11_0(and_11_0_out,and_11_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_11_1(and_11_1_out,Q0,L2B_CTR);
wire and_12_0_out;
wire and_12_1_out;
and4$ and_12_0(and_12_0_out,and_12_1_out,Q3,Q2_bar,Q1_bar);
and2$ and_12_1(and_12_1_out,Q0,RD_EN_DONE_bar);
wire and_13_0_out;
wire and_13_1_out;
and4$ and_13_0(and_13_0_out,and_13_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_13_1(and_13_1_out,Q0,L2B_CTR_bar);
wire and_14_0_out;
and3$ and_14_0(and_14_0_out,Q3_bar,Q2,Q0_bar);
wire and_15_0_out;
and3$ and_15_0(and_15_0_out,Q2,Q1_bar,Q0_bar);
wire and_16_0_out;
and4$ and_16_0(and_16_0_out,Q2_bar,Q1_bar,Q0_bar,IC_MEM_RD_ACK);
wire and_17_0_out;
and4$ and_17_0(and_17_0_out,Q2_bar,Q1_bar,Q0_bar,DMA_MEM_WR_ACK);
wire and_18_0_out;
and4$ and_18_0(and_18_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_WR_ACK);
wire and_19_0_out;
and4$ and_19_0(and_19_0_out,Q3_bar,Q1_bar,Q0_bar,DC_MEM_RD_ACK);
wire and_20_0_out;
and4$ and_20_0(and_20_0_out,Q3,Q2_bar,Q1_bar,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
or4$ or_0_0(D3,or_0_1_out,and_2_0_out,and_7_0_out,and_8_0_out);
or4$ or_0_1(or_0_1_out,and_9_0_out,and_12_0_out,and_16_0_out,and_20_0_out);
wire or_1_1_out;
or4$ or_1_0(D2,or_1_1_out,and_1_0_out,and_2_0_out,and_5_0_out);
or4$ or_1_1(or_1_1_out,and_6_0_out,and_7_0_out,and_10_0_out,and_19_0_out);
wire or_2_1_out;
or4$ or_2_0(D1,or_2_1_out,and_0_0_out,and_1_0_out,and_6_0_out);
or3$ or_2_1(or_2_1_out,and_8_0_out,and_9_0_out,and_11_0_out);
wire or_3_1_out;
wire or_3_2_out;
or4$ or_3_0(D0,or_3_1_out,or_3_2_out,and_3_0_out,and_5_0_out);
or4$ or_3_1(or_3_1_out,and_10_0_out,and_12_0_out,and_13_0_out,and_17_0_out);
or3$ or_3_2(or_3_2_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_4_1_out;
wire or_4_2_out;
wire or_4_3_out;
wire or_4_4_out;
or4$ or_4_0(MEM_ADDR_GATE_ST,or_4_1_out,or_4_2_out,or_4_3_out,or_4_4_out);
or4$ or_4_1(or_4_1_out,and_6_0_out,and_7_0_out,and_8_0_out,and_9_0_out);
or4$ or_4_2(or_4_2_out,and_10_0_out,and_11_0_out,and_12_0_out,and_13_0_out);
or4$ or_4_3(or_4_3_out,and_14_0_out,and_15_0_out,and_16_0_out,and_17_0_out);
or3$ or_4_4(or_4_4_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_5_1_out;
wire or_5_2_out;
or4$ or_5_0(MEM_ADDR_GATE_LD,or_5_1_out,or_5_2_out,and_4_0_out,and_11_0_out);
or4$ or_5_1(or_5_1_out,and_13_0_out,and_14_0_out,and_15_0_out,and_16_0_out);
or4$ or_5_2(or_5_2_out,and_17_0_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_6_1_out;
wire or_6_2_out;
wire or_6_3_out;
wire or_6_4_out;
or4$ or_6_0(MEM_DIO_GATE,or_6_1_out,or_6_2_out,or_6_3_out,or_6_4_out);
or4$ or_6_1(or_6_1_out,and_6_0_out,and_7_0_out,and_8_0_out,and_9_0_out);
or4$ or_6_2(or_6_2_out,and_10_0_out,and_11_0_out,and_12_0_out,and_13_0_out);
or4$ or_6_3(or_6_3_out,and_14_0_out,and_15_0_out,and_16_0_out,and_17_0_out);
or3$ or_6_4(or_6_4_out,and_18_0_out,and_19_0_out,and_20_0_out);
wire or_7_1_out;
wire or_7_2_out;
wire or_7_3_out;
or4$ or_7_0(DATA_BUS_GATE,or_7_1_out,or_7_2_out,or_7_3_out,and_4_0_out);
or4$ or_7_1(or_7_1_out,and_5_0_out,and_6_0_out,and_9_0_out,and_10_0_out);
or4$ or_7_2(or_7_2_out,and_11_0_out,and_12_0_out,and_13_0_out,and_16_0_out);
or4$ or_7_3(or_7_3_out,and_17_0_out,and_18_0_out,and_19_0_out,and_20_0_out);
or2$ or_8_0(STORE_BUF_LD_EN,and_11_0_out,and_13_0_out);
wire or_9_1_out;
or4$ or_9_0(LOAD_BUF_LD_EN,or_9_1_out,and_6_0_out,and_7_0_out,and_9_0_out);
or2$ or_9_1(or_9_1_out,and_10_0_out,and_12_0_out);
or2$ or_10_0(LOAD_ADDR_LD_EN,and_5_0_out,and_20_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);
dff$ dff_3(clk, D3, Q3, Q3_bar, rst, 1'b1);

endmodule