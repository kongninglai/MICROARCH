module mmu_ctrl #(
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

  parameter V_CT_1000   = RANK_BURST_SIZE - 1,
  parameter V_CT_0100   = WR_AND_DATA_EN_CYCLES - 1,
  parameter V_CT_0101   = RD_EN_CYCLES  - 1,
  parameter V_CT_1101   = RANK_BURST_SIZE  - 1,
  parameter V_CT_1110   = (RD_EN_CYCLES - RANK_BURST_SIZE) - 1,
  parameter V_CT_1111   = (RANK_BURST_SIZE) - 1
) (
  input           rst, clk, 
  input           DC_MEM_WR_ACK, DMA_MEM_WR_ACK,
  input           DC_MEM_RD_ACK, IC_MEM_RD_ACK,
  output  [2:0]   MEM_CTRL_Q_MUX
);

/*** REWRITE COUNTER VALUES AS WIRES ***/

wire    [0:0]   CT_1000,
                CT_0100,
                CT_0101,
                CT_1101,
                CT_1110,
                CT_1111;

wire    [2:0]   W_CT_1000,
                W_CT_0100,
                W_CT_0101,
                W_CT_1101,
                W_CT_1110,
                W_CT_1111;

assign          W_CT_1000 = V_CT_1000 ;  
assign          W_CT_0100 = V_CT_0100 ;  
assign          W_CT_0101 = V_CT_0101 ;  
assign          W_CT_1101 = V_CT_1101 ;  
assign          W_CT_1110 = V_CT_1110 ;
assign          W_CT_1111 = V_CT_1111 ;

/*** STATE BITS + COUNTER ***/
wire  [3:0] STATE, NEXT_STATE;
wire        Q3,Q2,Q1,Q0;
wire        Q3_prebuf,Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q3_bar_prebuf,Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;
wire        D3,D2,D1,D0;

assign STATE        = {Q3, Q2, Q1, Q0};
assign NEXT_STATE   = {D3, D2, D1, D0};

bufferH1024$  bufferH1024$_Q3(Q3, Q3_prebuf);
bufferH1024$  bufferH1024$_Q2(Q2, Q2_prebuf);
bufferH1024$  bufferH1024$_Q1(Q1, Q1_prebuf);
bufferH1024$  bufferH1024$_Q0(Q0, Q0_prebuf);

assign MEM_CTRL_Q_MUX = {Q2, Q1, Q0};

wire  [2:0] counter, counter_buf16, inc_counter, next_counter;
bufferH16$  bufferH16$_counter_buf16[2:0](counter_buf16, counter);


big_increment #(
  .WIDTH(3)
) big_increment_inc_counter (
  .a(counter_buf16),
  .s(inc_counter)
);

wire    no_state_change;

big_eq #(
  .WIDTH(4)
) big_eq_no_state_change (
  .in0({Q3,Q2,Q1,Q0}), .in1({D3,D2,D1,D0}),
  .eq(no_state_change)
);

mux2$ mux2$_next_counter[2:0](next_counter, 3'b000, inc_counter, no_state_change);

reg_n #(
  .WIDTH(3),
  .USE_EN_BAR(0)
) reg_n_counter (
  .clk(clk), .rst(rst),
  .en({3{1'b1}}), .d(next_counter),
  .q(counter)
);

/* "State Done" Counter Comparators */

big_eq  #(.WIDTH(3)) done_1000  (.in0(counter_buf16), .in1(W_CT_1000), .eq(CT_1000));
big_eq  #(.WIDTH(3)) done_0100  (.in0(counter_buf16), .in1(W_CT_0100), .eq(CT_0100));
big_eq  #(.WIDTH(3)) done_0101  (.in0(counter_buf16), .in1(W_CT_0101), .eq(CT_0101));
big_eq  #(.WIDTH(3)) done_1101  (.in0(counter_buf16), .in1(W_CT_1101), .eq(CT_1101));
big_eq  #(.WIDTH(3)) done_1110  (.in0(counter_buf16), .in1(W_CT_1110), .eq(CT_1110));
big_eq  #(.WIDTH(3)) done_1111  (.in0(counter_buf16), .in1(W_CT_1111), .eq(CT_1111));

/* Inverters */
wire CT_0101_bar;
inv1$ inv_0(CT_0101_bar, CT_0101);
wire Q1_bar;
wire CT_0100_bar;
inv1$ inv_2(CT_0100_bar, CT_0100);
wire CT_1101_bar;
inv1$ inv_3(CT_1101_bar, CT_1101);
wire CT_1000_bar;
inv1$ inv_4(CT_1000_bar, CT_1000);
wire Q3_bar;
wire CT_1111_bar;
inv1$ inv_6(CT_1111_bar, CT_1111);
wire Q2_bar;
wire Q0_bar;

/* Product Expressions */
wire and_0_0_out;
wire and_0_1_out;
and4$ and_0_0(and_0_0_out,and_0_1_out,Q3_bar,Q2,Q1_bar);
and2$ and_0_1(and_0_1_out,Q0_bar,CT_0100_bar);
wire and_1_0_out;
wire and_1_1_out;
and4$ and_1_0(and_1_0_out,and_1_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_1_1(and_1_1_out,Q0_bar,DMA_MEM_WR_ACK);
wire and_2_0_out;
wire and_2_1_out;
and4$ and_2_0(and_2_0_out,and_2_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_2_1(and_2_1_out,Q0_bar,DC_MEM_WR_ACK);
wire and_3_0_out;
and4$ and_3_0(and_3_0_out,Q3,Q1,Q0_bar,CT_1110);
wire and_4_0_out;
wire and_4_1_out;
and4$ and_4_0(and_4_0_out,and_4_1_out,Q3_bar,Q2_bar,Q1_bar);
and2$ and_4_1(and_4_1_out,Q0_bar,IC_MEM_RD_ACK);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q3_bar,Q2_bar,Q1_bar,DC_MEM_RD_ACK);
wire and_6_0_out;
and4$ and_6_0(and_6_0_out,Q3,Q2_bar,Q0_bar,CT_1000_bar);
wire and_7_0_out;
and4$ and_7_0(and_7_0_out,Q3,Q2_bar,Q0_bar,CT_1000);
wire and_8_0_out;
wire and_8_1_out;
and4$ and_8_0(and_8_0_out,and_8_1_out,Q3,Q2,Q1_bar);
and2$ and_8_1(and_8_1_out,Q0,CT_1101);
wire and_9_0_out;
wire and_9_1_out;
and4$ and_9_0(and_9_0_out,and_9_1_out,Q3,Q2,Q1);
and2$ and_9_1(and_9_1_out,Q0,CT_1111_bar);
wire and_10_0_out;
and4$ and_10_0(and_10_0_out,Q3_bar,Q1_bar,Q0,CT_0101_bar);
wire and_11_0_out;
wire and_11_1_out;
and4$ and_11_0(and_11_0_out,and_11_1_out,Q3,Q2,Q1_bar);
and2$ and_11_1(and_11_1_out,Q0,CT_1101_bar);
wire and_12_0_out;
and4$ and_12_0(and_12_0_out,Q3_bar,Q2_bar,Q1_bar,Q0);
wire and_13_0_out;
and4$ and_13_0(and_13_0_out,Q3,Q2,Q1,Q0_bar);
wire and_14_0_out;
and4$ and_14_0(and_14_0_out,Q3,Q2_bar,Q1,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
wire or_0_2_out;
or4$ or_0_0(D3,or_0_1_out,or_0_2_out,and_1_0_out,and_2_0_out);
or4$ or_0_1(or_0_1_out,and_4_0_out,and_6_0_out,and_8_0_out,and_9_0_out);
or3$ or_0_2(or_0_2_out,and_11_0_out,and_13_0_out,and_14_0_out);
wire or_1_1_out;
wire or_1_2_out;
or4$ or_1_0(D2,or_1_1_out,or_1_2_out,and_0_0_out,and_7_0_out);
or4$ or_1_1(or_1_1_out,and_8_0_out,and_9_0_out,and_10_0_out,and_11_0_out);
or3$ or_1_2(or_1_2_out,and_12_0_out,and_13_0_out,and_14_0_out);
or4$ or_2_0(D1,and_4_0_out,and_8_0_out,and_9_0_out,and_13_0_out);
wire or_3_1_out;
or4$ or_3_0(D0,or_3_1_out,and_3_0_out,and_5_0_out,and_9_0_out);
or4$ or_3_1(or_3_1_out,and_10_0_out,and_11_0_out,and_12_0_out,and_14_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);
dff$ dff_3(clk, D3, Q3_prebuf, Q3_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH1024$  bufferH1024$_Q3_bar(Q3_bar, Q3_bar_prebuf);
bufferH1024$  bufferH1024$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH1024$  bufferH1024$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH1024$  bufferH1024$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule