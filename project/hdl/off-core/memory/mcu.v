module mcu #(
  parameter ROW_BUFFER_EN=1'b0,
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
  input                             DC_MEM_WR_ACK, DMA_MEM_WR_ACK,
  input                             DC_MEM_RD_ACK, IC_MEM_RD_ACK,
  input     [CHIPS_PER_RANK-1:0]    WR_mask,
  input     [MEM_ADDR_WIDTH-1:0]    ADDR_BUS,
  inout     [BUS_BIT_WIDTH-1:0]     DATA_BUS,
  output                            MEM_BUSY, DATA_VALID_BAR
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
bufferH64$  bufferH64$_Q0(Q0, Q0_prebuf);

wire  [2:0] counter, counter_buf1024;
wire        L2B_CTR;

assign STATE        = {Q2, Q1, Q0};
assign NEXT_STATE   = {D2, D1, D0};

bufferH1024$  bufferH1024$_counter_buf1024[2:0](counter_buf1024, counter);

and2$   and2$_L2B_CTR(L2B_CTR, counter_buf1024[1], counter_buf1024[0]);

/*** STATE MACHINE OUTPUTS ***/
wire    STORE_BUF_LD_EN, STORE_BUF_LD_EN_buf1024;
wire    LOAD_BUF_LD_EN , LOAD_BUF_LD_EN_buf1024;
wire    LOAD_ADDR_LD_EN, LOAD_ADDR_LD_EN_buf1024;

bufferH1024$  bufferH1024$_STORE_BUF_LD_EN_buf1024(STORE_BUF_LD_EN_buf1024, STORE_BUF_LD_EN);
bufferH1024$  bufferH1024$_LOAD_BUF_LD_EN_buf1024 (LOAD_BUF_LD_EN_buf1024,  LOAD_BUF_LD_EN);
bufferH1024$  bufferH1024$_LOAD_ADDR_LD_EN_buf1024(LOAD_ADDR_LD_EN_buf1024, LOAD_ADDR_LD_EN);

wire    MEM_ADDR_GATE_ST, MEM_ADDR_GATE_ST_buf16,
        MEM_ADDR_GATE_LD, MEM_ADDR_GATE_LD_buf1024,
        MEM_DIO_GATE, MEM_DIO_GATE_buf256,
        DATA_BUS_GATE, DATA_BUS_GATE_buf256;


bufferH16$  bufferH16$_MEM_ADDR_GATE_ST_buf16(MEM_ADDR_GATE_ST_buf16, MEM_ADDR_GATE_ST);
bufferH1024$  bufferH1024$_MEM_ADDR_GATE_LD_buf1024(MEM_ADDR_GATE_LD_buf1024, MEM_ADDR_GATE_LD);
bufferH256$ bufferH256$_MEM_DIO_GATE_buf256(MEM_DIO_GATE_buf256, MEM_DIO_GATE);
bufferH256$ bufferH256$_DATA_BUS_GATE_buf256(DATA_BUS_GATE_buf256, DATA_BUS_GATE);

wire    MEM_BUSY_DRIVER_VALUE_buf1024, MEM_BUSY_DRIVER_VALUE_inv_prebuf;
nor3$    nor3$_MEM_BUSY_DRIVER_VALUE_inv_prebuf(MEM_BUSY_DRIVER_VALUE_inv_prebuf, Q2, Q1, Q0);
bufferHInv1024$ bufferHInv1024$_MEM_BUSY_DRIVER_VALUE_buf1024(MEM_BUSY_DRIVER_VALUE_buf1024, MEM_BUSY_DRIVER_VALUE_inv_prebuf);
tristate_bus_driver1$  tristate_bus_driver1$_MEM_BUSY(.enbar(1'b0), 
                                                      .in(MEM_BUSY_DRIVER_VALUE_buf1024), 
                                                      .out(MEM_BUSY));

wire    DATA_VALID_BAR_DRIVER_VALUE, NOT_MEM_BUSY_DRIVER_VALUE;
assign  DATA_VALID_BAR_DRIVER_VALUE = DATA_BUS_GATE_buf256;
inv1$   inv1$_NOT_MEM_BUSY_DRIVER_VALUE(NOT_MEM_BUSY_DRIVER_VALUE, MEM_BUSY_DRIVER_VALUE_buf1024);
tristate_bus_driver1$  tristate_bus_driver1$_DATA_VALID_BAR(.enbar(NOT_MEM_BUSY_DRIVER_VALUE), 
                                                            .in(DATA_VALID_BAR_DRIVER_VALUE), 
                                                            .out(DATA_VALID_BAR));

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

wire    [RANK_BIT_WIDTH-1:0]  STORE_BUFFER_DATA, STORE_BUFFER_DATA_buf256, STORE_BUFFER_DATA_WR_EN, STORE_BUFFER_DATA_WR_EN_GATED,
                              SHIFTED_DATA_BUS;

bufferH256$   bufferH256$_STORE_BUFFER_DATA_buf256[RANK_BIT_WIDTH-1:0](STORE_BUFFER_DATA_buf256, STORE_BUFFER_DATA);

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

/* LOAD BUFFER ADDRESS FOR RANK 0, 1, 2 */

wire    [RANK_ADDR_WIDTH-1:0]  LOAD_BUFFER_A_RANK0, LOAD_BUFFER_A_RANK0_CALC;

reg_n #(
  .WIDTH(RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_A_RANK0 (
  .clk(clk), .rst(rst),
  .en({RANK_ADDR_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(LOAD_BUFFER_A_RANK0_CALC),
  .q(LOAD_BUFFER_A_RANK0)
);

wire    [RANK_ADDR_WIDTH-1:0]   INCREMENTED_A_RANK0;

big_increment #(
  .WIDTH(RANK_ADDR_WIDTH)
) big_increment_INCREMENTED_RANK_ADDR (
  .a(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .s(INCREMENTED_A_RANK0)
);

wire LOAD_BUFFER_A_RANK0_CALC_DUMMY;

mux2_8$   mux2_8$_LOAD_BUFFER_A_RANK0_CALC( {LOAD_BUFFER_A_RANK0_CALC_DUMMY, LOAD_BUFFER_A_RANK0_CALC},
                                            {1'b0, ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]},
                                            {1'b0, INCREMENTED_A_RANK0},
                                            ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1]);

/* LOAD BUFFER ADDRESS FOR OTHER RANKS */

wire    [RANK_ADDR_WIDTH-1:0]  LOAD_BUFFER_A_OTHERS;

reg_n #(
  .WIDTH(RANK_ADDR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_A_OTHERS (
  .clk(clk), .rst(rst),
  .en({RANK_ADDR_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .q(LOAD_BUFFER_A_OTHERS)
);

/* LOAD BUFFER MUX SELECT */

wire    [RANK_IDX_WIDTH-1:0]                RANK_IDX_0, RANK_IDX_0_buf16,
                              RANK_IDX_1_D, RANK_IDX_1, RANK_IDX_1_buf16,
                              RANK_IDX_2_D, RANK_IDX_2, RANK_IDX_2_buf16,
                              RANK_IDX_3_D, RANK_IDX_3,
                                            RANK_IDX_SELECTED, RANK_IDX_SELECTED_buf64, RANK_IDX_SELECTED_DUMMY;

bufferH16$    bufferH16$_RANK_IDX_0_buf16[RANK_IDX_WIDTH-1:0](RANK_IDX_0_buf16, RANK_IDX_0);
bufferH16$    bufferH16$_RANK_IDX_1_buf16[RANK_IDX_WIDTH-1:0](RANK_IDX_1_buf16, RANK_IDX_1);
bufferH16$    bufferH16$_RANK_IDX_2_buf16[RANK_IDX_WIDTH-1:0](RANK_IDX_2_buf16, RANK_IDX_2);
bufferH64$    bufferH64$_RANK_IDX_SELECTED_buf64[RANK_IDX_WIDTH-1:0](RANK_IDX_SELECTED_buf64, RANK_IDX_SELECTED);

mux16_8b mux16_8b_RANK_IDX_SELECTED (
  .in0 ({4'd0, RANK_IDX_0_buf16}),
  .in1 ({4'd0, RANK_IDX_0_buf16}),
  .in2 ({4'd0, RANK_IDX_0_buf16}),
  .in3 ({4'd0, RANK_IDX_0_buf16}),
  .in4 ({4'd0, RANK_IDX_0_buf16}),
  .in5 ({4'd0, RANK_IDX_0_buf16}),
  .in6 ({4'd0, RANK_IDX_0_buf16}),
  .in7 ({4'd0, RANK_IDX_0_buf16}),
  .in8 ({4'd0, RANK_IDX_0_buf16}),
  .in9 ({4'd0, RANK_IDX_0_buf16}),
  .in10({4'd0, RANK_IDX_1_buf16}),
  .in11({4'd0, RANK_IDX_1_buf16}),
  .in12({4'd0, RANK_IDX_1_buf16}),
  .in13({4'd0, RANK_IDX_1_buf16}),
  .in14({4'd0, RANK_IDX_2_buf16}),
  .in15({4'd0, RANK_IDX_3}),
  .s0(counter_buf1024[1]),
  .s1(Q0),
  .s2(Q1),
  .s3(Q2),
  .outb({RANK_IDX_SELECTED_DUMMY, RANK_IDX_SELECTED})
);

reg_n #(
  .WIDTH(RANK_IDX_WIDTH),
  .USE_EN_BAR(0)
) reg_n_RANK_IDX_0 (
  .clk(clk), .rst(rst),
  .en({RANK_IDX_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]),
  .q(RANK_IDX_0)
);

PA_4b PA_4b_RANK_IDX_1_D (
  .in0(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]), .in1(4'd1),
	.s(RANK_IDX_1_D)
);

reg_n #(
  .WIDTH(RANK_IDX_WIDTH),
  .USE_EN_BAR(0)
) reg_n_RANK_IDX_1 (
  .clk(clk), .rst(rst),
  .en({RANK_IDX_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(RANK_IDX_1_D),
  .q(RANK_IDX_1)
);

PA_4b PA_4b_RANK_IDX_2_D (
  .in0(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]), .in1(4'd2),
	.s(RANK_IDX_2_D)
);

reg_n #(
  .WIDTH(RANK_IDX_WIDTH),
  .USE_EN_BAR(0)
) reg_n_RANK_IDX_2 (
  .clk(clk), .rst(rst),
  .en({RANK_IDX_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(RANK_IDX_2_D),
  .q(RANK_IDX_2)
);

PA_4b PA_4b_RANK_IDX_3_D (
  .in0(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]), .in1(4'd3),
	.s(RANK_IDX_3_D)
);

reg_n #(
  .WIDTH(RANK_IDX_WIDTH),
  .USE_EN_BAR(0)
) reg_n_RANK_IDX_3 (
  .clk(clk), .rst(rst),
  .en({RANK_IDX_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(RANK_IDX_3_D),
  .q(RANK_IDX_3)
);

/* LOAD BUFFER DATA (SERIALIZER) */

wire    [RANK_BIT_WIDTH-1:0]              LOAD_BUFFER_DATA, SELECTED_RANK_DIO, SELECTED_RANK_DIO_buf16;
wire    [RANK_BIT_WIDTH-1:0]              DIO_PER_RANK[0:RANK_COUNT-1];
wire    [RANK_COUNT*RANK_BIT_WIDTH-1:0]   DIO;
wire    [BUS_BIT_WIDTH-1:0]               DATA_BUS_DRIVER_VALUE;

bufferH16$    bufferH16$_SELECTED_RANK_DIO_buf16[RANK_BIT_WIDTH-1:0](SELECTED_RANK_DIO_buf16, SELECTED_RANK_DIO);

genvar r;
generate
  for (r = 0; r < RANK_COUNT; r = r + 1) begin : DIO_PER_RANK_GEN
    assign DIO_PER_RANK[r] = DIO[RANK_BIT_WIDTH*r+:RANK_BIT_WIDTH];
  end
endgenerate

wire [BUS_BIT_WIDTH-1:0]  LOAD_BUFFER_DRIVER_VALUE;

mux4$   mux4$_LOAD_BUFFER_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] ( LOAD_BUFFER_DRIVER_VALUE,
                                                            LOAD_BUFFER_DATA[BUS_BIT_WIDTH-1:0],
                                                            LOAD_BUFFER_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                            LOAD_BUFFER_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                            LOAD_BUFFER_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                            counter_buf1024[0],
                                                            counter_buf1024[1]);

generate
  for (r = 0; r < 8; r = r + 1) begin : MUX16_16b_SELECTED_RANK_DIO_GEN
    mux16_16b mux16_16b_inst (
      .in0 (DIO_PER_RANK[0 ][r*16 +: 16]),
      .in1 (DIO_PER_RANK[1 ][r*16 +: 16]),
      .in2 (DIO_PER_RANK[2 ][r*16 +: 16]),
      .in3 (DIO_PER_RANK[3 ][r*16 +: 16]),
      .in4 (DIO_PER_RANK[4 ][r*16 +: 16]),
      .in5 (DIO_PER_RANK[5 ][r*16 +: 16]),
      .in6 (DIO_PER_RANK[6 ][r*16 +: 16]),
      .in7 (DIO_PER_RANK[7 ][r*16 +: 16]),
      .in8 (DIO_PER_RANK[8 ][r*16 +: 16]),
      .in9 (DIO_PER_RANK[9 ][r*16 +: 16]),
      .in10(DIO_PER_RANK[10][r*16 +: 16]),
      .in11(DIO_PER_RANK[11][r*16 +: 16]),
      .in12(DIO_PER_RANK[12][r*16 +: 16]),
      .in13(DIO_PER_RANK[13][r*16 +: 16]),
      .in14(DIO_PER_RANK[14][r*16 +: 16]),
      .in15(DIO_PER_RANK[15][r*16 +: 16]),
      .s0(RANK_IDX_SELECTED_buf64[0]),
      .s1(RANK_IDX_SELECTED_buf64[1]),
      .s2(RANK_IDX_SELECTED_buf64[2]),
      .s3(RANK_IDX_SELECTED_buf64[3]),
      .outb(SELECTED_RANK_DIO[r*16 +: 16])
    );
  end
endgenerate

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{LOAD_BUF_LD_EN_buf1024}}), .d(SELECTED_RANK_DIO_buf16),
  .q(LOAD_BUFFER_DATA)
);

wire  [2:0] MEM_CTRL_Q_MUX, MEM_CTRL_Q_MUX_buf1024;

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

/*** DATA TO MAIN MEMORY (DIO declared above) ***/
wire    [RANK_ADDR_WIDTH-1:0]           A_RANK0, A_RANK1, A_RANK2, A_OTHERS;
wire    [RANK_COUNT*CHIPS_PER_RANK-1:0] WR, OE, CE;

assign A_RANK1 = A_RANK0;
assign A_RANK2 = A_RANK0;

tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_H(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[BUS_BIT_WIDTH-1:16]), 
                                                          .out(DATA_BUS[BUS_BIT_WIDTH-1:16]));
                                                                              
tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_L(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[15:0]), 
                                                          .out(DATA_BUS[15:0]));

genvar a, b;
generate
  for (a = 0; a < RANK_COUNT; a = a + 1) begin : PER_RANK_DIO_GEN
    for (b = 0; b < RANK_BIT_WIDTH / 16; b = b + 1) begin : PER_RANK_DIO_WORD_GEN
      tristate_bus_driver16$  tristate_bus_driver16$_DIO(.enbar(MEM_DIO_GATE_buf256), .in(STORE_BUFFER_DATA_buf256[16*b+:16]), .out(DIO[(RANK_BIT_WIDTH*a+16*b)+:16]));
    end
  end
endgenerate

tristateL$  tristateL$_LOAD_BUFFER_A_RANK0 [RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_LD_buf1024), .in(LOAD_BUFFER_A_RANK0),  .out(A_RANK0));
tristateL$  tristateL$_LOAD_BUFFER_A_OTHERS[RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_LD_buf1024), .in(LOAD_BUFFER_A_OTHERS), .out(A_OTHERS));

tristateL$  tristateL$_STORE_BUFFER_A_RANK0 [RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_ST_buf16), .in(STORE_BUFFER_A_RANK0),  .out(A_RANK0));
tristateL$  tristateL$_STORE_BUFFER_A_OTHERS[RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_ST_buf16), .in(STORE_BUFFER_A_OTHERS), .out(A_OTHERS));

/* Now, pick which OE, CE, and WR goes to memory */

assign OE = {256{MEM_ADDR_GATE_LD_buf1024}};
inv1$   inv1$_CE[255:0](CE, MEM_BUSY_DRIVER_VALUE_buf1024);

genvar j;
generate
  for (j = 0; j < 16; j = j + 1) begin : MEMORY_ENABLE_GEN
    mux8_16b   mux8_WR
                        ( 
                          WR[j*16 +: 16],

                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          STORE_BUFFER_WR[j*16 +: 16],
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},    

                          MEM_CTRL_Q_MUX_buf1024[0], MEM_CTRL_Q_MUX_buf1024[1], MEM_CTRL_Q_MUX_buf1024[2]
                        );
  end
endgenerate



/* PREFETCH LOGIC */

wire IS_IC_MEM_RD, IS_DC_MEM_RD, EITHER_ACK;
or2$    or2$_EITHER_ACK(EITHER_ACK, IC_MEM_RD_ACK, DC_MEM_RD_ACK);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_IS_IC_MEM_RD (
  .clk(clk), .rst(rst),
  .en(EITHER_ACK), .d(IC_MEM_RD_ACK),
  .q(IS_IC_MEM_RD)
);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_IS_DC_MEM_RD (
  .clk(clk), .rst(rst),
  .en(EITHER_ACK), .d(DC_MEM_RD_ACK),
  .q(IS_DC_MEM_RD)
);

wire IC_PLUS_2_LD_EN, IC_PLUS_3_LD_EN, DC_PLUS_2_LD_EN, DC_PLUS_3_LD_EN;
wire IC_PLUS_2_LD_EN_buf256, IC_PLUS_3_LD_EN_buf256, DC_PLUS_2_LD_EN_buf256, DC_PLUS_3_LD_EN_buf256;
wire [RANK_BIT_WIDTH-1:0]   IC_PLUS_2_DATA, IC_PLUS_3_DATA, DC_PLUS_2_DATA, DC_PLUS_3_DATA;

wire counter_bit_1_bar;
inv1$ inv1$_counter_bit_1_bar(counter_bit_1_bar, counter_buf1024[1]);

wire IC_PLUS_MISS, DC_PLUS_MISS;

wire IC_PLUS_3_LD_EN_INT, DC_PLUS_3_LD_EN_INT;
and3$ and3$_IC_PLUS_2_LD_EN(IC_PLUS_2_LD_EN, IC_PLUS_3_LD_EN, counter_bit_1_bar, IC_PLUS_MISS);
and2$ and2$_IC_PLUS_3_LD_EN(IC_PLUS_3_LD_EN, IC_PLUS_3_LD_EN_INT, IC_PLUS_MISS);
and4$ and4$_IC_PLUS_3_LD_EN_INT(IC_PLUS_3_LD_EN_INT, Q2, Q1, Q0, IS_IC_MEM_RD);
and3$ and3$_DC_PLUS_2_LD_EN(DC_PLUS_2_LD_EN, DC_PLUS_3_LD_EN, counter_bit_1_bar, DC_PLUS_MISS);
and2$ and2$_DC_PLUS_3_LD_EN(DC_PLUS_3_LD_EN, DC_PLUS_3_LD_EN_INT, DC_PLUS_MISS);
and4$ and4$_DC_PLUS_3_LD_EN_INT(DC_PLUS_3_LD_EN_INT, Q2, Q1, Q0, IS_DC_MEM_RD);

bufferH256$   bufferH256$_IC_PLUS_2_LD_EN_buf256(IC_PLUS_2_LD_EN_buf256, IC_PLUS_2_LD_EN);
bufferH256$   bufferH256$_IC_PLUS_3_LD_EN_buf256(IC_PLUS_3_LD_EN_buf256, IC_PLUS_3_LD_EN);
bufferH256$   bufferH256$_DC_PLUS_2_LD_EN_buf256(DC_PLUS_2_LD_EN_buf256, DC_PLUS_2_LD_EN);
bufferH256$   bufferH256$_DC_PLUS_3_LD_EN_buf256(DC_PLUS_3_LD_EN_buf256, DC_PLUS_3_LD_EN);

wire IC_PLUS_VALID, DC_PLUS_VALID;

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_VALID (
  .clk(clk), .rst(rst),
  .en(IC_PLUS_2_LD_EN_buf256), .d(1'b1),
  .q(IC_PLUS_VALID)
);

wire SET_OR_CLR_DC_PLUS_VALID;
or3$    or3$_SET_OR_CLR_DC_PLUS_VALID(SET_OR_CLR_DC_PLUS_VALID, DC_PLUS_2_LD_EN_buf256, DC_MEM_WR_ACK, DMA_MEM_WR_ACK);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_VALID (
  .clk(clk), .rst(rst),
  .en(SET_OR_CLR_DC_PLUS_VALID), .d(DC_PLUS_2_LD_EN_buf256),
  .q(DC_PLUS_VALID)
);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_2_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{IC_PLUS_2_LD_EN_buf256}}), .d(SELECTED_RANK_DIO_buf16),
  .q(IC_PLUS_2_DATA)
);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_3_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{IC_PLUS_3_LD_EN_buf256}}), .d(SELECTED_RANK_DIO_buf16),
  .q(IC_PLUS_3_DATA)
);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_2_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{DC_PLUS_2_LD_EN_buf256}}), .d(SELECTED_RANK_DIO_buf16),
  .q(DC_PLUS_2_DATA)
);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_3_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{DC_PLUS_3_LD_EN_buf256}}), .d(SELECTED_RANK_DIO_buf16),
  .q(DC_PLUS_3_DATA)
);

wire [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] IC_PLUS_ADDR, DC_PLUS_ADDR;
wire [RANK_ADDR_WIDTH-1:0] PLUS_ADDR_D;
wire IS_FIRST_2_RANKS, PLUS_ADDR_D_DUMMY;

nor3$   nor3$_IS_FIRST_2_RANKS(IS_FIRST_2_RANKS, RANK_IDX_2_buf16[3], RANK_IDX_2_buf16[2], RANK_IDX_2_buf16[1]);
mux2_8$   mux2_8$_PLUS_ADDR_D({PLUS_ADDR_D_DUMMY, PLUS_ADDR_D},
                              {1'b0, LOAD_BUFFER_A_OTHERS},
                              {1'b0, LOAD_BUFFER_A_RANK0},
                              IS_FIRST_2_RANKS);

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_ADDR (
  .clk(clk), .rst(rst),
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){IC_PLUS_2_LD_EN_buf256}}), .d({PLUS_ADDR_D, RANK_IDX_2_buf16}),
  .q(IC_PLUS_ADDR)
);

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_ADDR (
  .clk(clk), .rst(rst),
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){DC_PLUS_2_LD_EN_buf256}}), .d({PLUS_ADDR_D, RANK_IDX_2_buf16}),
  .q(DC_PLUS_ADDR)
);

wire IC_ADDR_HIT, IC_PLUS_HIT_D, IC_PLUS_HIT, DC_ADDR_HIT, DC_PLUS_HIT_D, DC_PLUS_HIT, DC_PLUS_HIT_buf16;
bufferH16$    bufferH16$_DC_PLUS_HIT_buf16(DC_PLUS_HIT_buf16, DC_PLUS_HIT);

generate 
  if (ROW_BUFFER_EN) begin 
    big_eq #(
      .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE)
    ) big_eq_IC_ADDR_HIT (
      .in0(ADDR_BUS[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]), .in1(IC_PLUS_ADDR),
      .eq(IC_ADDR_HIT)
    );

    big_eq #(
      .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE)
    ) big_eq_DC_ADDR_HIT (
      .in0(ADDR_BUS[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]), .in1(DC_PLUS_ADDR),
      .eq(DC_ADDR_HIT)
    );
  end else begin 
    assign IC_ADDR_HIT = 1'b0;
    assign DC_ADDR_HIT = 1'b0;
  end
endgenerate

wire IC_PLUS_MISS_D, DC_PLUS_MISS_D;

wire IC_PLUS_HIT_D_BAR, DC_PLUS_HIT_D_BAR;
nand3$   nand3$_IC_PLUS_HIT_D_BAR(IC_PLUS_HIT_D_BAR, IC_ADDR_HIT, IS_IC_MEM_RD, IC_PLUS_VALID);
nand3$   nand3$_DC_PLUS_HIT_D_BAR(DC_PLUS_HIT_D_BAR, DC_ADDR_HIT, IS_DC_MEM_RD, DC_PLUS_VALID);

inv1$   inv1$_IC_PLUS_HIT_D(IC_PLUS_HIT_D, IC_PLUS_HIT_D_BAR);
inv1$   inv1$_DC_PLUS_HIT_D(DC_PLUS_HIT_D, DC_PLUS_HIT_D_BAR);

and2$   and2$_IC_PLUS_MISS_D(IC_PLUS_MISS_D, IC_PLUS_HIT_D_BAR, IS_IC_MEM_RD);
and2$   and2$_DC_PLUS_MISS_D(DC_PLUS_MISS_D, DC_PLUS_HIT_D_BAR, IS_DC_MEM_RD);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_HIT (
  .clk(clk), .rst(rst),
  .en(LOAD_ADDR_LD_EN_buf1024), .d(IC_PLUS_HIT_D),
  .q(IC_PLUS_HIT)
);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_HIT (
  .clk(clk), .rst(rst),
  .en(LOAD_ADDR_LD_EN_buf1024), .d(DC_PLUS_HIT_D),
  .q(DC_PLUS_HIT)
);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_IC_PLUS_MISS (
  .clk(clk), .rst(rst),
  .en(LOAD_ADDR_LD_EN_buf1024), .d(IC_PLUS_MISS_D),
  .q(IC_PLUS_MISS)
);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_DC_PLUS_MISS (
  .clk(clk), .rst(rst),
  .en(LOAD_ADDR_LD_EN_buf1024), .d(DC_PLUS_MISS_D),
  .q(DC_PLUS_MISS)
);

wire [BUS_BIT_WIDTH-1:0] IC_PLUS_2_DRIVER_VALUE, IC_PLUS_3_DRIVER_VALUE, DC_PLUS_2_DRIVER_VALUE, DC_PLUS_3_DRIVER_VALUE;

mux4$   mux4$_IC_PLUS_2_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (   IC_PLUS_2_DRIVER_VALUE,
                                                            IC_PLUS_2_DATA[BUS_BIT_WIDTH-1:0],
                                                            IC_PLUS_2_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                            IC_PLUS_2_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                            IC_PLUS_2_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                            counter_buf1024[0],
                                                            counter_buf1024[1]);

mux4$   mux4$_IC_PLUS_3_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (   IC_PLUS_3_DRIVER_VALUE,
                                                            IC_PLUS_3_DATA[BUS_BIT_WIDTH-1:0],
                                                            IC_PLUS_3_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                            IC_PLUS_3_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                            IC_PLUS_3_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                            counter_buf1024[0],
                                                            counter_buf1024[1]);

mux4$   mux4$_DC_PLUS_2_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (   DC_PLUS_2_DRIVER_VALUE,
                                                            DC_PLUS_2_DATA[BUS_BIT_WIDTH-1:0],
                                                            DC_PLUS_2_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                            DC_PLUS_2_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                            DC_PLUS_2_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                            counter_buf1024[0],
                                                            counter_buf1024[1]);

mux4$   mux4$_DC_PLUS_3_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (   DC_PLUS_3_DRIVER_VALUE,
                                                            DC_PLUS_3_DATA[BUS_BIT_WIDTH-1:0],
                                                            DC_PLUS_3_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                            DC_PLUS_3_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                            DC_PLUS_3_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                            counter_buf1024[0],
                                                            counter_buf1024[1]);

wire final_state;
and3$   and3$_final_state(final_state, Q2, Q1, Q0);

mux8_16b   mux8_16b_DATA_BUS_DRIVER_VALUE_TOP(    DATA_BUS_DRIVER_VALUE   [31:16]  ,
                                                  LOAD_BUFFER_DRIVER_VALUE[31:16]  ,
                                                  LOAD_BUFFER_DRIVER_VALUE[31:16]  ,
                                                  DC_PLUS_2_DRIVER_VALUE  [31:16]  ,
                                                  DC_PLUS_3_DRIVER_VALUE  [31:16]  ,
                                                  IC_PLUS_2_DRIVER_VALUE  [31:16]  ,
                                                  IC_PLUS_3_DRIVER_VALUE  [31:16]  ,
                                                  ,
                                                  ,                                                            
                                                  final_state,
                                                  DC_PLUS_HIT_buf16,
                                                  IC_PLUS_HIT);

mux8_16b   mux8_16b_DATA_BUS_DRIVER_VALUE_BOT(    DATA_BUS_DRIVER_VALUE   [15:0]  ,
                                                  LOAD_BUFFER_DRIVER_VALUE[15:0]  ,
                                                  LOAD_BUFFER_DRIVER_VALUE[15:0]  ,
                                                  DC_PLUS_2_DRIVER_VALUE  [15:0]  ,
                                                  DC_PLUS_3_DRIVER_VALUE  [15:0]  ,
                                                  IC_PLUS_2_DRIVER_VALUE  [15:0]  ,
                                                  IC_PLUS_3_DRIVER_VALUE  [15:0]  ,
                                                  ,
                                                  ,                                                            
                                                  final_state,
                                                  DC_PLUS_HIT_buf16,
                                                  IC_PLUS_HIT);

wire SKIP_STATE, SKIP_STATE_INT;
or2$    or2$_SKIP_STATE_INT(SKIP_STATE_INT, IC_PLUS_HIT_D, DC_PLUS_HIT_D);
and2$   and2$_SKIP_STATE(SKIP_STATE, SKIP_STATE_INT, LOAD_ADDR_LD_EN_buf1024);

/* mcu_ctrl determines which OE, CE, and WR gets picked */

// wire  [2:0] MEM_CTRL_Q_MUX, MEM_CTRL_Q_MUX_buf1024;

bufferH1024$    bufferH1024$_MEM_CTRL_Q_MUX_buf1024[2:0](MEM_CTRL_Q_MUX_buf1024, MEM_CTRL_Q_MUX);

mcu_ctrl #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10)
) mcu_ctrl_inst (
  .rst(rst), .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK), .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .MEM_CTRL_Q_MUX(MEM_CTRL_Q_MUX)
);




/*** MAIN MEMORY INSTANTIATION ***/
main_memory #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10)

) main_memory_inst (
  .clk(clk), .rst(rst),
  .A_RANK0(A_RANK0), .A_RANK1(A_RANK1), .A_RANK2(A_RANK2), .A_OTHERS(A_OTHERS),
  .WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO)
);

/*** BEGIN AUTO-GENERATED CODE ***/

/* Inverters */
wire Q0_bar;
wire WRITE_DONE_bar;
inv1$ inv_1(WRITE_DONE_bar, WRITE_DONE);
wire L2B_CTR_bar;
inv1$ inv_2(L2B_CTR_bar, L2B_CTR);
wire SHORT_BRST_DONE_bar;
inv1$ inv_3(SHORT_BRST_DONE_bar, SHORT_BRST_DONE);
wire Q2_bar;
wire Q1_bar;

/* Product Expressions */
wire nand_0_0_0_out;
nand3$ nand_0_0_0(nand_0_0_0_out,Q1,Q0_bar,WRITE_DONE_bar);
wire nand_1_0_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,Q2_bar,Q1,Q0,SKIP_STATE);
wire nand_2_0_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE);
wire nand_3_0_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE_bar);
wire nand_4_0_0_out;
nand4$ nand_4_0_0(nand_4_0_0_out,Q2_bar,Q1_bar,Q0_bar,DMA_MEM_WR_ACK);
wire nand_5_0_0_out;
nand4$ nand_5_0_0(nand_5_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_WR_ACK);
wire nand_6_0_0_out;
nand4$ nand_6_0_0(nand_6_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR);
wire nand_7_0_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR_bar);
wire nand_8_0_0_out;
nand3$ nand_8_0_0(nand_8_0_0_out,Q2,Q0_bar,RD_EN_DONE);
wire nand_9_0_0_out;
nand4$ nand_9_0_0(nand_9_0_0_out,Q2_bar,Q1_bar,Q0_bar,IC_MEM_RD_ACK);
wire nand_10_0_0_out;
nand4$ nand_10_0_0(nand_10_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_RD_ACK);
wire nand_11_0_0_out;
nand3$ nand_11_0_0(nand_11_0_0_out,Q2_bar,Q1,Q0);
wire nand_12_0_0_out;
nand3$ nand_12_0_0(nand_12_0_0_out,Q2,Q1,L2B_CTR_bar);
wire nand_13_0_0_out;
nand3$ nand_13_0_0(nand_13_0_0_out,Q2,Q1,Q0_bar);
wire nand_14_0_0_out;
nand2$ nand_14_0_0(nand_14_0_0_out,Q2,Q0_bar);
wire nand_15_0_0_out;
nand2$ nand_15_0_0(nand_15_0_0_out,Q1_bar,Q0_bar);
wire nand_16_0_0_out;
inv1$ nand_16_0_0(nand_16_0_0_out, Q2_bar);
wire nand_17_0_0_out;
inv1$ nand_17_0_0(nand_17_0_0_out, Q2);

/* Sum Expressions */
wire nand_0_1_1_out;
nand4$ nand_0_0_1(D2,nand_0_1_1_out,nand_2_0_0_out,nand_3_0_0_out,nand_11_0_0_out);
and2$ nand_0_1_1(nand_0_1_1_out,nand_12_0_0_out,nand_14_0_0_out);
wire nand_1_1_1_out;
nand4$ nand_1_0_1(D1,nand_1_1_1_out,nand_0_0_0_out,nand_2_0_0_out,nand_6_0_0_out);
and4$ nand_1_1_1(nand_1_1_1_out,nand_9_0_0_out,nand_10_0_0_out,nand_12_0_0_out,nand_13_0_0_out);
wire nand_2_1_1_out;
wire nand_2_2_1_out;
nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_1_0_0_out,nand_3_0_0_out,nand_4_0_0_out);
and4$ nand_2_1_1(nand_2_1_1_out,nand_2_2_1_out,nand_5_0_0_out,nand_7_0_0_out,nand_8_0_0_out);
and4$ nand_2_2_1(nand_2_2_1_out,nand_9_0_0_out,nand_10_0_0_out,nand_12_0_0_out,nand_13_0_0_out);
nand3$ nand_3_0_1(MEM_ADDR_GATE_ST,nand_11_0_0_out,nand_15_0_0_out,nand_17_0_0_out);
inv1$ nand_4_0_1(MEM_ADDR_GATE_LD, nand_16_0_0_out);
wire nand_5_1_1_out;
nand4$ nand_5_0_1(MEM_DIO_GATE,nand_5_1_1_out,nand_6_0_0_out,nand_7_0_0_out,nand_11_0_0_out);
and2$ nand_5_1_1(nand_5_1_1_out,nand_15_0_0_out,nand_17_0_0_out);
nand2$ nand_6_0_1(DATA_BUS_GATE,nand_15_0_0_out,nand_16_0_0_out);
nand2$ nand_7_0_1(STORE_BUF_LD_EN,nand_6_0_0_out,nand_7_0_0_out);
inv1$ nand_8_0_1(LOAD_BUF_LD_EN, nand_14_0_0_out);
inv1$ nand_9_0_1(LOAD_ADDR_LD_EN, nand_11_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule