module mcu #(
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
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

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
        MEM_ADDR_GATE_LD, MEM_ADDR_GATE_LD_buf16,
        MEM_DIO_GATE, MEM_DIO_GATE_buf256,
        DATA_BUS_GATE, DATA_BUS_GATE_buf256;


bufferH16$  bufferH16$_MEM_ADDR_GATE_ST_buf16(MEM_ADDR_GATE_ST_buf16, MEM_ADDR_GATE_ST);
bufferH16$  bufferH16$_MEM_ADDR_GATE_LD_buf16(MEM_ADDR_GATE_LD_buf16, MEM_ADDR_GATE_LD);
bufferH256$ bufferH256$_MEM_DIO_GATE_buf256(MEM_DIO_GATE_buf256, MEM_DIO_GATE);
bufferH256$ bufferH256$_DATA_BUS_GATE_buf256(DATA_BUS_GATE_buf256, DATA_BUS_GATE);

wire    MEM_BUSY_DRIVER_VALUE;
or3$    or3$_MEM_BUSY_DRIVER_VALUE(MEM_BUSY_DRIVER_VALUE, Q2, Q1, Q0);
tristate_bus_driver1$  tristate_bus_driver1$_MEM_BUSY(.enbar(1'b0), 
                                                      .in(MEM_BUSY_DRIVER_VALUE), 
                                                      .out(MEM_BUSY));

wire    DATA_VALID_BAR_DRIVER_VALUE, NOT_MEM_BUSY_DRIVER_VALUE;
assign  DATA_VALID_BAR_DRIVER_VALUE = DATA_BUS_GATE_buf256;
inv1$   inv1$_NOT_MEM_BUSY_DRIVER_VALUE(NOT_MEM_BUSY_DRIVER_VALUE, MEM_BUSY_DRIVER_VALUE);
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
  .en({RANK_ADDR_WIDTH{LOAD_ADDR_LD_EN_buf1024}}), .d(ADDR_BUS[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH]),
  .q(LOAD_BUFFER_A_OTHERS)
);

/* LOAD BUFFER MEM CTRL (WR, OE, CE) */

wire    [RANK_COUNT*CHIPS_PER_RANK-1:0]   LOAD_BUFFER_OE_DEMAND_CALC, LOAD_BUFFER_OE_DEMAND, 
                                          LOAD_BUFFER_OE_DEMAND_AND_PREFETCH_CALC, LOAD_BUFFER_OE_DEMAND_AND_PREFETCH, 
                                          LOAD_BUFFER_OE_PREFETCH_CALC, LOAD_BUFFER_OE_PREFETCH;

wire    [RANK_COUNT*CHIPS_PER_RANK-1:0]   LOAD_BUFFER_CE_DEMAND_CALC, LOAD_BUFFER_CE_DEMAND, 
                                          LOAD_BUFFER_CE_DEMAND_AND_PREFETCH_CALC, LOAD_BUFFER_CE_DEMAND_AND_PREFETCH, 
                                          LOAD_BUFFER_CE_PREFETCH_CALC, LOAD_BUFFER_CE_PREFETCH;

wire    [RANK_COUNT*CHIPS_PER_RANK-1:0]   LOAD_BUFFER_WR_DEMAND_CALC, LOAD_BUFFER_WR_DEMAND, 
                                          LOAD_BUFFER_WR_DEMAND_AND_PREFETCH_CALC, LOAD_BUFFER_WR_DEMAND_AND_PREFETCH, 
                                          LOAD_BUFFER_WR_PREFETCH_CALC, LOAD_BUFFER_WR_PREFETCH;

lshf_chunks_var_256b lshf_chunks_var_256b_LOAD_BUFFER_OE_DEMAND_CALC (
  .in({{(RANK_COUNT-1)*CHIPS_PER_RANK{1'b1}}, {CHIPS_PER_RANK{1'b0}}}),
  .shf_amt(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]),
  .out(LOAD_BUFFER_OE_DEMAND_CALC)
);

wire    [RANK_IDX_WIDTH-1:0]   INCREMENTED_RANK_NUMBER;

big_increment #(
  .WIDTH(RANK_IDX_WIDTH)
) big_increment_INCREMENTED_RANK_NUMBER (
  .a(ADDR_BUS[MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-1:MEM_ADDR_WIDTH-RANK_ADDR_WIDTH-4]),
  .s(INCREMENTED_RANK_NUMBER)
);

lshf_chunks_var_256b lshf_chunks_var_256b_LOAD_BUFFER_OE_PREFETCH_CALC (
  .in({{(RANK_COUNT-1)*CHIPS_PER_RANK{1'b1}}, {CHIPS_PER_RANK{1'b0}}}),
  .shf_amt(INCREMENTED_RANK_NUMBER),
  .out(LOAD_BUFFER_OE_PREFETCH_CALC)
);

and2$ and2$_LOAD_BUFFER_OE_DEMAND_AND_PREFETCH_CALC[RANK_COUNT*CHIPS_PER_RANK-1:0]( LOAD_BUFFER_OE_DEMAND_AND_PREFETCH_CALC,
                                                                                    LOAD_BUFFER_OE_DEMAND_CALC,
                                                                                    LOAD_BUFFER_OE_PREFETCH_CALC);

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_OE_DEMAND (
  .clk(clk), .rst(rst),
  .en({RANK_COUNT*CHIPS_PER_RANK{LOAD_ADDR_LD_EN_buf1024}}), .d(LOAD_BUFFER_OE_DEMAND_CALC),
  .q(LOAD_BUFFER_OE_DEMAND)
);

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_OE_DEMAND_AND_PREFETCH (
  .clk(clk), .rst(rst),
  .en({RANK_COUNT*CHIPS_PER_RANK{LOAD_ADDR_LD_EN_buf1024}}), .d(LOAD_BUFFER_OE_DEMAND_AND_PREFETCH_CALC),
  .q(LOAD_BUFFER_OE_DEMAND_AND_PREFETCH)
);

reg_n #(
  .WIDTH(RANK_COUNT*CHIPS_PER_RANK),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_OE_PREFETCH (
  .clk(clk), .rst(rst),
  .en({RANK_COUNT*CHIPS_PER_RANK{LOAD_ADDR_LD_EN_buf1024}}), .d(LOAD_BUFFER_OE_PREFETCH_CALC),
  .q(LOAD_BUFFER_OE_PREFETCH)
);

assign LOAD_BUFFER_CE_DEMAND_CALC = LOAD_BUFFER_OE_DEMAND_CALC;
assign LOAD_BUFFER_CE_DEMAND_AND_PREFETCH_CALC = LOAD_BUFFER_OE_DEMAND_AND_PREFETCH_CALC;
assign LOAD_BUFFER_CE_PREFETCH_CALC = LOAD_BUFFER_OE_PREFETCH_CALC;

assign LOAD_BUFFER_CE_DEMAND = LOAD_BUFFER_OE_DEMAND;
assign LOAD_BUFFER_CE_DEMAND_AND_PREFETCH = LOAD_BUFFER_OE_DEMAND_AND_PREFETCH;
assign LOAD_BUFFER_CE_PREFETCH = LOAD_BUFFER_OE_PREFETCH;

assign LOAD_BUFFER_WR_DEMAND_CALC = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};
assign LOAD_BUFFER_WR_DEMAND_AND_PREFETCH_CALC = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};
assign LOAD_BUFFER_WR_PREFETCH_CALC = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};

assign LOAD_BUFFER_WR_DEMAND = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};
assign LOAD_BUFFER_WR_DEMAND_AND_PREFETCH = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};
assign LOAD_BUFFER_WR_PREFETCH = {RANK_COUNT*CHIPS_PER_RANK{1'b1}};

/* LOAD BUFFER DATA (SERIALIZER) */

wire    [RANK_BIT_WIDTH-1:0]  LOAD_BUFFER_DATA;
wire    [RANK_BIT_WIDTH-1:0]  DIO;
wire    [BUS_BIT_WIDTH-1:0]   DATA_BUS_DRIVER_VALUE;

mux4$   mux4$_DATA_BUS_DRIVER_VALUE[BUS_BIT_WIDTH-1:0] (DATA_BUS_DRIVER_VALUE,
                                                        LOAD_BUFFER_DATA[BUS_BIT_WIDTH-1:0],
                                                        LOAD_BUFFER_DATA[2*BUS_BIT_WIDTH-1:BUS_BIT_WIDTH],
                                                        LOAD_BUFFER_DATA[3*BUS_BIT_WIDTH-1:2*BUS_BIT_WIDTH],
                                                        LOAD_BUFFER_DATA[4*BUS_BIT_WIDTH-1:3*BUS_BIT_WIDTH],
                                                        counter_buf1024[0],
                                                        counter_buf1024[1]);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_LOAD_BUFFER_DATA (
  .clk(clk), .rst(rst),
  .en({RANK_BIT_WIDTH{LOAD_BUF_LD_EN_buf1024}}), .d(DIO),
  .q(LOAD_BUFFER_DATA)
);

/* mcu_ctrl determines which OE, CE, and WR gets picked */

wire  [2:0] MEM_CTRL_Q_MUX, MEM_CTRL_Q_MUX_buf1024;

bufferH1024$    bufferH1024$_MEM_CTRL_Q_MUX_buf1024[2:0](MEM_CTRL_Q_MUX_buf1024, MEM_CTRL_Q_MUX);

mcu_ctrl #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10)
) mcu_ctrl_inst (
  .rst(rst), .clk(clk), 
  .DC_MEM_WR_ACK(DC_MEM_WR_ACK), .DMA_MEM_WR_ACK(DMA_MEM_WR_ACK),
  .DC_MEM_RD_ACK(DC_MEM_RD_ACK), .IC_MEM_RD_ACK(IC_MEM_RD_ACK),
  .MEM_CTRL_Q_MUX(MEM_CTRL_Q_MUX)
);

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
wire    [RANK_ADDR_WIDTH-1:0]           A_RANK0, A_OTHERS;
wire    [RANK_COUNT*CHIPS_PER_RANK-1:0] WR, OE, CE;

tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_H(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[BUS_BIT_WIDTH-1:16]), 
                                                          .out(DATA_BUS[BUS_BIT_WIDTH-1:16]));
                                                                              
tristate_bus_driver16$  tristate_bus_driver16$_DATA_BUS_L(.enbar(DATA_BUS_GATE_buf256), 
                                                          .in(DATA_BUS_DRIVER_VALUE[15:0]), 
                                                          .out(DATA_BUS[15:0]));

tristate_bus_driver1$  tristate_bus_driver1$_DIO[RANK_BIT_WIDTH-1:0](.enbar(MEM_DIO_GATE_buf256), .in(STORE_BUFFER_DATA), .out(DIO));

tristateL$  tristateL$_LOAD_BUFFER_A_RANK0 [RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_LD_buf16), .in(LOAD_BUFFER_A_RANK0),  .out(A_RANK0));
tristateL$  tristateL$_LOAD_BUFFER_A_OTHERS[RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_LD_buf16), .in(LOAD_BUFFER_A_OTHERS), .out(A_OTHERS));

tristateL$  tristateL$_STORE_BUFFER_A_RANK0 [RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_ST_buf16), .in(STORE_BUFFER_A_RANK0),  .out(A_RANK0));
tristateL$  tristateL$_STORE_BUFFER_A_OTHERS[RANK_ADDR_WIDTH-1:0](.enbar(MEM_ADDR_GATE_ST_buf16), .in(STORE_BUFFER_A_OTHERS), .out(A_OTHERS));

/* Now, pick which OE, CE, and WR goes to memory */

genvar j;
generate
  for (j = 0; j < 16; j = j + 1) begin : MEMORY_ENABLE_GEN
    mux8_16b   mux8_OE
                        ( 
                          OE[j*16 +: 16],

                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          {CHIPS_PER_RANK{1'b1}},
                          STORE_BUFFER_OE[j*16 +: 16],
                          LOAD_BUFFER_OE_DEMAND[j*16 +: 16],
                          LOAD_BUFFER_OE_DEMAND_AND_PREFETCH[j*16 +: 16],
                          LOAD_BUFFER_OE_PREFETCH[j*16 +: 16],    

                          MEM_CTRL_Q_MUX_buf1024[0], MEM_CTRL_Q_MUX_buf1024[1], MEM_CTRL_Q_MUX_buf1024[2]
                        );

    mux8_16b   mux8_CE
                                              ( 
                                                CE[j*16 +: 16],

                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                STORE_BUFFER_CE[j*16 +: 16],
                                                LOAD_BUFFER_CE_DEMAND[j*16 +: 16],
                                                LOAD_BUFFER_CE_DEMAND_AND_PREFETCH[j*16 +: 16],
                                                LOAD_BUFFER_CE_PREFETCH[j*16 +: 16],    

                                                MEM_CTRL_Q_MUX_buf1024[0], MEM_CTRL_Q_MUX_buf1024[1], MEM_CTRL_Q_MUX_buf1024[2]
                                              );

    mux8_16b   mux8_WR
                                              ( 
                                                WR[j*16 +: 16],

                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                {CHIPS_PER_RANK{1'b1}},
                                                STORE_BUFFER_WR[j*16 +: 16],
                                                LOAD_BUFFER_WR_DEMAND[j*16 +: 16],
                                                LOAD_BUFFER_WR_DEMAND_AND_PREFETCH[j*16 +: 16],
                                                LOAD_BUFFER_WR_PREFETCH[j*16 +: 16],    

                                                MEM_CTRL_Q_MUX_buf1024[0], MEM_CTRL_Q_MUX_buf1024[1], MEM_CTRL_Q_MUX_buf1024[2]
                                              );
  end
endgenerate





/*** MAIN MEMORY INSTANTIATION ***/
main_memory #(
  .MEM_BYTE_CAPACITY(MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10(CYCLE_TIME_X10)

) main_memory_inst (
  .clk(clk), .rst(rst),
  .A_RANK0(A_RANK0), .A_OTHERS(A_OTHERS),
  .WR(WR), .OE(OE), .CE(CE),
  .DIO(DIO)
);

/*** BEGIN AUTO-GENERATED CODE ***/

/* Inverters */
wire Q0_bar;
wire Q1_bar;
wire L2B_CTR_bar;
inv1$ inv_2(L2B_CTR_bar, L2B_CTR);
wire WRITE_DONE_bar;
inv1$ inv_3(WRITE_DONE_bar, WRITE_DONE);
wire Q2_bar;
wire SHORT_BRST_DONE_bar;
inv1$ inv_5(SHORT_BRST_DONE_bar, SHORT_BRST_DONE);

/* Product Expressions */
wire nand_0_0_0_out;
nand3$ nand_0_0_0(nand_0_0_0_out,Q1,Q0_bar,WRITE_DONE_bar);
wire nand_1_0_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,Q2_bar,Q1_bar,Q0_bar,DMA_MEM_WR_ACK);
wire nand_2_0_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_WR_ACK);
wire nand_3_0_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR);
wire nand_4_0_0_out;
nand3$ nand_4_0_0(nand_4_0_0_out,Q2,Q0_bar,RD_EN_DONE);
wire nand_5_0_0_out;
nand3$ nand_5_0_0(nand_5_0_0_out,Q2_bar,Q1,Q0);
wire nand_6_0_0_out;
nand4$ nand_6_0_0(nand_6_0_0_out,Q2_bar,Q1_bar,Q0_bar,IC_MEM_RD_ACK);
wire nand_7_0_0_out;
nand4$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1_bar,Q0_bar,DC_MEM_RD_ACK);
wire nand_8_0_0_out;
nand4$ nand_8_0_0(nand_8_0_0_out,Q2_bar,Q1_bar,Q0,L2B_CTR_bar);
wire nand_9_0_0_out;
nand4$ nand_9_0_0(nand_9_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE);
wire nand_10_0_0_out;
nand4$ nand_10_0_0(nand_10_0_0_out,Q2,Q1_bar,Q0,SHORT_BRST_DONE_bar);
wire nand_11_0_0_out;
nand3$ nand_11_0_0(nand_11_0_0_out,Q2,Q1,L2B_CTR_bar);
wire nand_12_0_0_out;
nand2$ nand_12_0_0(nand_12_0_0_out,Q2,Q0_bar);
wire nand_13_0_0_out;
nand2$ nand_13_0_0(nand_13_0_0_out,Q1,Q0);
wire nand_14_0_0_out;
inv1$ nand_14_0_0(nand_14_0_0_out, Q2_bar);
wire nand_15_0_0_out;
nand3$ nand_15_0_0(nand_15_0_0_out,Q2,Q1,Q0_bar);
wire nand_16_0_0_out;
nand2$ nand_16_0_0(nand_16_0_0_out,Q1_bar,Q0_bar);

/* Sum Expressions */
wire nand_0_1_1_out;
nand4$ nand_0_0_1(D2,nand_0_1_1_out,nand_5_0_0_out,nand_9_0_0_out,nand_10_0_0_out);
and2$ nand_0_1_1(nand_0_1_1_out,nand_11_0_0_out,nand_12_0_0_out);
wire nand_1_1_1_out;
nand4$ nand_1_0_1(D1,nand_1_1_1_out,nand_0_0_0_out,nand_3_0_0_out,nand_6_0_0_out);
and4$ nand_1_1_1(nand_1_1_1_out,nand_7_0_0_out,nand_9_0_0_out,nand_11_0_0_out,nand_15_0_0_out);
wire nand_2_1_1_out;
wire nand_2_2_1_out;
nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_1_0_0_out,nand_2_0_0_out,nand_4_0_0_out);
and4$ nand_2_1_1(nand_2_1_1_out,nand_2_2_1_out,nand_6_0_0_out,nand_7_0_0_out,nand_8_0_0_out);
and3$ nand_2_2_1(nand_2_2_1_out,nand_10_0_0_out,nand_11_0_0_out,nand_15_0_0_out);
wire nand_3_1_1_out;
nand4$ nand_3_0_1(MEM_ADDR_GATE_ST,nand_3_1_1_out,nand_9_0_0_out,nand_10_0_0_out,nand_13_0_0_out);
and2$ nand_3_1_1(nand_3_1_1_out,nand_15_0_0_out,nand_16_0_0_out);
nand2$ nand_4_0_1(MEM_ADDR_GATE_LD,nand_13_0_0_out,nand_14_0_0_out);
wire nand_5_1_1_out;
nand4$ nand_5_0_1(MEM_DIO_GATE,nand_5_1_1_out,nand_3_0_0_out,nand_8_0_0_out,nand_9_0_0_out);
and4$ nand_5_1_1(nand_5_1_1_out,nand_10_0_0_out,nand_13_0_0_out,nand_15_0_0_out,nand_16_0_0_out);
nand2$ nand_6_0_1(DATA_BUS_GATE,nand_14_0_0_out,nand_16_0_0_out);
nand2$ nand_7_0_1(STORE_BUF_LD_EN,nand_3_0_0_out,nand_8_0_0_out);
inv1$ nand_8_0_1(LOAD_BUF_LD_EN, nand_12_0_0_out);
inv1$ nand_9_0_1(LOAD_ADDR_LD_EN, nand_5_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule