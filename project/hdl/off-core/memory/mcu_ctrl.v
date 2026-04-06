module mcu_ctrl #(
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
  parameter V_CT_0100   = WR_AND_DATA_EN_CYCLES - 1
) (
  input           rst, clk, 
  input           DC_MEM_WR_ACK, DMA_MEM_WR_ACK,
  output  [2:0]   MEM_CTRL_Q_MUX
);

/*** REWRITE COUNTER VALUES AS WIRES ***/

wire    [0:0]   CT_1000,
                CT_0100;

wire    [2:0]   W_CT_1000,
                W_CT_0100;

assign          W_CT_1000 = V_CT_1000 ;  
assign          W_CT_0100 = V_CT_0100 ; 

/*** STATE BITS + COUNTER ***/
wire  [3:0] STATE, NEXT_STATE;
wire        Q3,Q2,Q1,Q0;
wire        Q3_prebuf,Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q3_bar_prebuf,Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;
wire        D3,D2,D1,D0;

assign STATE        = {Q3, Q2, Q1, Q0};
assign NEXT_STATE   = {D3, D2, D1, D0};

bufferH64$  bufferH64$_Q3(Q3, Q3_prebuf);
bufferH64$  bufferH64$_Q2(Q2, Q2_prebuf);
bufferH64$  bufferH64$_Q1(Q1, Q1_prebuf);
bufferH64$  bufferH64$_Q0(Q0, Q0_prebuf);

buffer$ buffer$_MEM_CTRL_Q_MUX[2:0](MEM_CTRL_Q_MUX, {Q2_prebuf, Q1_prebuf, Q0_prebuf});

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

/* Inverters */
wire Q0_bar;
wire CT_0100_bar;
inv1$ inv_1(CT_0100_bar, CT_0100);
wire Q2_bar;
wire Q1_bar;
wire Q3_bar;
wire CT_1000_bar;
inv1$ inv_5(CT_1000_bar, CT_1000);

/* Product Expressions */
wire nand_0_0_0_out;
wire nand_0_1_0_out;
nand4$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,Q3_bar,Q2,Q1_bar);
and2$ nand_0_1_0(nand_0_1_0_out,Q0_bar,CT_0100_bar);
wire nand_1_0_0_out;
wire nand_1_1_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,nand_1_1_0_out,Q3,Q2_bar,Q1_bar);
and2$ nand_1_1_0(nand_1_1_0_out,Q0_bar,CT_1000);
wire nand_2_0_0_out;
wire nand_2_1_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,nand_2_1_0_out,Q3,Q2_bar,Q1_bar);
and2$ nand_2_1_0(nand_2_1_0_out,Q0_bar,CT_1000_bar);
wire nand_3_0_0_out;
wire nand_3_1_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,nand_3_1_0_out,Q3_bar,Q2_bar,Q1_bar);
and2$ nand_3_1_0(nand_3_1_0_out,Q0_bar,DMA_MEM_WR_ACK);
wire nand_4_0_0_out;
wire nand_4_1_0_out;
nand4$ nand_4_0_0(nand_4_0_0_out,nand_4_1_0_out,Q3_bar,Q2_bar,Q1_bar);
and2$ nand_4_1_0(nand_4_1_0_out,Q0_bar,DC_MEM_WR_ACK);

/* Sum Expressions */
nand3$ nand_0_0_1(D3,nand_2_0_0_out,nand_3_0_0_out,nand_4_0_0_out);
nand2$ nand_1_0_1(D2,nand_0_0_0_out,nand_1_0_0_out);
assign D1 = 1'b0;
assign D0 = 1'b0;

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