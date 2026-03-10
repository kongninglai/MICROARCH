module cache_controller #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15,
  parameter   NUM_SETS=8,
  parameter   INDEX_WIDTH=$clog2(NUM_SETS),
  parameter   NUM_WAYS=4,
  parameter   WAY_WIDTH=$clog2(NUM_WAYS),
  parameter   TAG_WIDTH=8,

  parameter   V_CT_CACHE_FILL_DONE=2,
  parameter   V_CT_SB_FILL_DONE=6
) (
  input                                             rst, clk, 
  input     [2:0]                                   KB_PFN, DMA_PFN,

  /*** BUS SIGNALS ***/               
  input     [BUS_BIT_WIDTH-1:0]                     DATA_BUS,
  input     [2:0]                                   ACKS,
  input                                             DATA_VALID_BAR,
  output    [MEM_ADDR_WIDTH-1:0]                    ADDR_BUS,
  output    [2:0]                                   REQS,

  /*** BETWEEN CACHE CONTROLLER & CACHE ***/                
  input                                             CACHE_MISS,
  input     [RANK_BIT_WIDTH-1:0]                    CACHE_RD_DATA,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CACHE_PHYS_ADDR,
  input     [WAY_WIDTH-1:0]                         CACHE_VICT_WAY,

  output                                            CC_STREAM_BUF_HIT, CC_FSM_FILL_BUSY,
  output    [RANK_BIT_WIDTH-1:0]                    CC_WR_DATA_OUT, CC_HIT_DATA_OUT,
  output    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT,
  output    [NUM_WAYS*RANK_BURST_SIZE-1:0]          CC_DATA_WR_MASK_OUT,

  /*** TO TAG STORE ***/
  output    [INDEX_WIDTH-1:0]                       CC_TAG_VALID_SET_INDEX,
  output    [NUM_WAYS-1:0]                          CC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         CC_TAG_IN,

  /*** TO VALID STORE (ALONG WITH CC_TAG_VALID_SET_INDEX) ***/
  output                                            CC_VALID_SET_OR_CLR,
  output    [INDEX_WIDTH+WAY_WIDTH-1:0]             CC_VALID_WR_EN,
  output                                            CC_FSM_VALID_WR_EN_GLOBAL
);

/*** REWRITE COUNTER VALUES AS WIRES ***/

wire    [0:0]   CACHE_FILL_DONE  ,
                SB_FILL_DONE     ;

wire    [2:0]   W_CT_CACHE_FILL_DONE  ,
                W_CT_SB_FILL_DONE     ;

assign          W_CT_CACHE_FILL_DONE       = V_CT_CACHE_FILL_DONE     ;  
assign          W_CT_SB_FILL_DONE          = V_CT_SB_FILL_DONE        ;  

/*** STATE BITS ***/
wire  [2:0] STATE, NEXT_STATE;
wire        Q2,Q1,Q0;
wire        D2,D1,D0;

assign STATE        = {Q2, Q1, Q0};
assign NEXT_STATE   = {D2, D1, D0};

/*** STATE MACHINE OUTPUTS ***/

wire          ARB_ACK_RECV;
or3$  or3$_(ARB_ACK_RECV, ACKS[2], ACKS[1], ACKS[0]);

/* DECLARATIONS */
wire          FSM_LD_REGS, FSM_SHF_DATA_WR_MASK, FSM_TAG_WR_MASK_MUX,
              FSM_SB_WR_EN, FSM_SET_SB_VALID,
              FSM_WR_DATA_MUX, FSM_HIT_DATA_MUX, FSM_ADDR_MUX,
              FSM_ADDR_BUS_ENBAR, 
              FSM_IN_010;

wire  [1:0]   FSM_DATA_WR_MASK_MUX, FSM_DATA_BUS_SHF_MUX;

/* COUNTER */

wire  [2:0] counter, inc_counter, next_counter;

big_increment #(
  .WIDTH(3)
) big_increment_inc_counter (
  .a(counter),
  .s(inc_counter)
);

wire CLR_CTR, no_state_change;

big_eq #(
  .WIDTH(3)
) big_eq_no_state_change (
  .in0(STATE), .in1(NEXT_STATE),
  .eq(no_state_change)
);

and2$   and2$_CLR_CTR(CLR_CTR, FSM_IN_010, no_state_change);

mux2$   mux2$_next_counter[2:0](next_counter, inc_counter, 3'd0, CLR_CTR);

reg_n #(
  .WIDTH(3),
  .USE_EN_BAR(0)
) reg_n_counter (
  .clk(clk), .rst(rst),
  .en({3{1'b1}}), .d(next_counter),
  .q(counter)
);

/* "State Done" Counter Comparators */

big_eq  #(.WIDTH(3)) done_CACHE_FILL_DONE (.in0(counter), .in1(W_CT_CACHE_FILL_DONE     ), .eq(CACHE_FILL_DONE  ));
big_eq  #(.WIDTH(3)) done_SB_FILL_DONE    (.in0(counter), .in1(W_CT_SB_FILL_DONE        ), .eq(SB_FILL_DONE     ));

/* Easy Counter-Related Wires */

wire    [RANK_BURST_SIZE-1:0]               CC_STREAM_BUF_WR_MASK, CC_STREAM_BUF_WR_MASK_GATED;

decoder2_4$   decoder2_4$_CC_STREAM_BUF_WR_MASK(.SEL(counter[1:0]),
                                                 .Y(CC_STREAM_BUF_WR_MASK), .YBAR());

and2$         and2$_CC_STREAM_BUF_WR_MASK_GATED[RANK_BURST_SIZE-1:0](CC_STREAM_BUF_WR_MASK_GATED,
                                                                      CC_STREAM_BUF_WR_MASK,
                                                                      {RANK_BURST_SIZE{FSM_SB_WR_EN}});

and2$         and2$_FSM_HIT_DATA_MUX(FSM_HIT_DATA_MUX, CACHE_MISS, CC_STREAM_BUF_HIT);

assign  FSM_DATA_BUS_SHF_MUX = counter[1:0];

assign  CC_FSM_VALID_WR_EN_GLOBAL = FSM_TAG_WR_MASK_MUX;


wire  [NUM_WAYS*RANK_BURST_SIZE-1:0] CC_DATA_WR_MASK_DEFAULT;

assign CC_DATA_WR_MASK_DEFAULT = {NUM_WAYS*RANK_BURST_SIZE{1'b1}};

/*** DATA BUS SHIFTING LOGIC ***/

wire [RANK_BIT_WIDTH-1:0]  DATA_BUS_ZEXT, DATA_BUS_SHF_01, DATA_BUS_SHF_10, DATA_BUS_SHF_11, DATA_BUS_SHF;

ze #(
  .INP_WIDTH(BUS_BIT_WIDTH),
  .OUT_WIDTH(RANK_BIT_WIDTH)
) ze_DATA_BUS_ZEXT (
  .in(DATA_BUS),
  .out(DATA_BUS_ZEXT)   
);

lshf_const #(
  .WIDTH(RANK_BIT_WIDTH),
  .SHF_AMT(BUS_BIT_WIDTH)
) lshf_const_01 (
  .in(DATA_BUS_ZEXT),
  .out(DATA_BUS_SHF_01)
);

lshf_const #(
  .WIDTH(RANK_BIT_WIDTH),
  .SHF_AMT(2*BUS_BIT_WIDTH)
) lshf_const_10 (
  .in(DATA_BUS_ZEXT),
  .out(DATA_BUS_SHF_10)
);

lshf_const #(
  .WIDTH(RANK_BIT_WIDTH),
  .SHF_AMT(3*BUS_BIT_WIDTH)
) lshf_const_11 (
  .in(DATA_BUS_ZEXT),
  .out(DATA_BUS_SHF_11)
);

mux4$   mux4$_DATA_BUS_SHF[RANK_BIT_WIDTH-1:0]  (
                                                  DATA_BUS_SHF,

                                                  DATA_BUS_ZEXT,
                                                  DATA_BUS_SHF_01,
                                                  DATA_BUS_SHF_10,
                                                  DATA_BUS_SHF_11,

                                                  FSM_DATA_BUS_SHF_MUX[0],
                                                  FSM_DATA_BUS_SHF_MUX[1]
                                                );

/*** REGISTERS ***/

wire  [NUM_WAYS*RANK_BURST_SIZE-1:0]          D0_CC_DATA_WR_MASK_OUT_01, D1_CC_DATA_WR_MASK_OUT_01, 
                                              D_CC_DATA_WR_MASK_OUT_01, D_CC_DATA_WR_MASK_OUT_11;
wire  [NUM_WAYS-1:0]                          D_CC_TAG_WR_MASK_OUT_1;
wire  [INDEX_WIDTH+WAY_WIDTH-1:0]             D_CC_VALID_WR_EN_1;

we_logic_block we_logic_block_inst (           
  .CACHE_PHYS_ADDR(CACHE_PHYS_ADDR),
  .CACHE_VICT_WAY(CACHE_VICT_WAY),
  .DATA_WR_MASK_OUT(D0_CC_DATA_WR_MASK_OUT_01),
  .SB_DATA_WR_MASK_OUT(D_CC_DATA_WR_MASK_OUT_11),
  .TAG_WR_MASK_OUT(D_CC_TAG_WR_MASK_OUT_1),
  .VALID_WR_EN(D_CC_VALID_WR_EN_1)
);

wire  [NUM_WAYS*RANK_BURST_SIZE-1:0]          Q_CC_DATA_WR_MASK_OUT_01, Q_CC_DATA_WR_MASK_OUT_10;
wire  [NUM_WAYS-1:0]                          Q_CC_TAG_WR_MASK_OUT_1;
wire  [INDEX_WIDTH+WAY_WIDTH-1:0]             Q_CC_VALID_WR_EN_1;

lshf_const #(
  .WIDTH(NUM_WAYS*RANK_BURST_SIZE),
  .SHF_AMT(1),
  .SHF_ONES(1)
) lshf_const_D1_CC_DATA_WR_MASK_OUT_01 (
  .in(Q_CC_DATA_WR_MASK_OUT_01),
  .out(D1_CC_DATA_WR_MASK_OUT_01)
);

mux2$   mux2$_D_CC_DATA_WR_MASK_OUT_01[NUM_WAYS*RANK_BURST_SIZE-1:0](
                                                                                D_CC_DATA_WR_MASK_OUT_01,
                                                                                D0_CC_DATA_WR_MASK_OUT_01,
                                                                                D1_CC_DATA_WR_MASK_OUT_01,
                                                                                FSM_SHF_DATA_WR_MASK
                                                                              );

wire    LD_CC_DATA_WR_MASK_OUT_01;

or2$    or2$_LD_CC_DATA_WR_MASK_OUT_01(LD_CC_DATA_WR_MASK_OUT_01,
                                        FSM_SHF_DATA_WR_MASK,
                                        FSM_LD_REGS);

reg_n #(
  .WIDTH(NUM_WAYS*RANK_BURST_SIZE),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) reg_n_Q_CC_DATA_WR_MASK_OUT_01 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS*RANK_BURST_SIZE{LD_CC_DATA_WR_MASK_OUT_01}}), .d(D_CC_DATA_WR_MASK_OUT_01),
  .q(Q_CC_DATA_WR_MASK_OUT_01)
);

reg_n #(
  .WIDTH(NUM_WAYS*RANK_BURST_SIZE),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) reg_n_Q_CC_DATA_WR_MASK_OUT_10 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS*RANK_BURST_SIZE{FSM_LD_REGS}}), .d(D_CC_DATA_WR_MASK_OUT_11),
  .q(Q_CC_DATA_WR_MASK_OUT_10)
);

reg_n #(
  .WIDTH(NUM_WAYS),
  .USE_EN_BAR(0)
) reg_n_Q_CC_TAG_WR_MASK_OUT_1 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS{FSM_LD_REGS}}), .d(D_CC_TAG_WR_MASK_OUT_1),
  .q(Q_CC_TAG_WR_MASK_OUT_1)
);

reg_n #(
  .WIDTH(INDEX_WIDTH+WAY_WIDTH),
  .USE_EN_BAR(0)
) reg_n_Q_CC_VALID_WR_EN_1 (
  .clk(clk), .rst(rst),
  .en({(INDEX_WIDTH+WAY_WIDTH){FSM_LD_REGS}}), .d(D_CC_VALID_WR_EN_1),
  .q(Q_CC_VALID_WR_EN_1)
);

mux2$   mux2$_CC_VALID_WR_EN[INDEX_WIDTH+WAY_WIDTH-1:0](
                                                          CC_VALID_WR_EN, 
                                                          {INDEX_WIDTH+WAY_WIDTH{1'b0}},
                                                          Q_CC_VALID_WR_EN_1,
                                                          FSM_TAG_WR_MASK_MUX
                                                        );
assign CC_VALID_SET_OR_CLR = 1'b1;

wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      D_CC_ADDR_OUT_1, D_CC_NL_PHYS_ADDR;
wire  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      Q_CC_ADDR_OUT_1, Q_CC_NL_PHYS_ADDR;

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_Q_CC_ADDR_OUT_1 (
  .clk(clk), .rst(rst),
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){FSM_LD_REGS}}), .d(CACHE_PHYS_ADDR),
  .q(Q_CC_ADDR_OUT_1)
);

assign CC_TAG_IN = Q_CC_ADDR_OUT_1[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7];
assign CC_TAG_VALID_SET_INDEX = Q_CC_ADDR_OUT_1[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE];

big_increment #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE)
) big_increment_D_CC_NL_PHYS_ADDR (
  .a(CACHE_PHYS_ADDR),
  .s(D_CC_NL_PHYS_ADDR)
);

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_Q_CC_NL_PHYS_ADDR (
  .clk(clk), .rst(rst),
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){FSM_LD_REGS}}), .d(D_CC_NL_PHYS_ADDR),
  .q(Q_CC_NL_PHYS_ADDR)
);

wire  [2:0] D_CC_RD_RQ;
wire  [2:0] Q_CC_RD_RQ;

io_addr_logic_block io_addr_logic_block_inst (
  .KB_PFN(KB_PFN), .DMA_PFN(DMA_PFN), .PFN(CACHE_PHYS_ADDR[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-3]),
  .WHICH_IO(D_CC_RD_RQ)
);

reg_n #(
  .WIDTH(3),
  .USE_EN_BAR(0)
) reg_n_Q_CC_RD_RQ (
  .clk(clk), .rst(rst),
  .en({(3){FSM_LD_REGS}}), .d(D_CC_RD_RQ),
  .q(Q_CC_RD_RQ)
);

/*** STREAM BUFFER ***/

wire    [RANK_BIT_WIDTH-1:0]                SB_DATA_OUT;

stream_buffer stream_buffer_inst (
  .clk(clk), .rst(rst),
  .stream_buffer_wr_mask(CC_STREAM_BUF_WR_MASK_GATED),
  .cache_addr(CACHE_PHYS_ADDR), .cache_controller_next_line_addr(Q_CC_NL_PHYS_ADDR),
  .DATA_BUS_SHF(DATA_BUS_SHF),
  .cache_controller_set_valid(FSM_SET_SB_VALID),
  .stream_buffer_hit(CC_STREAM_BUF_HIT),
  .stream_buffer_miss(),
  .stream_buffer_data(SB_DATA_OUT)
);

/*** OUTPUT MUXES ***/

mux2$   mux2$_CC_ADDR_OUT[MEM_ADDR_WIDTH-1:RANK_BURST_SIZE](
                                                              CC_ADDR_OUT,

                                                              CACHE_PHYS_ADDR,
                                                              Q_CC_ADDR_OUT_1,

                                                              FSM_ADDR_MUX
                                                            );
mux2$   mux2$_CC_WR_DATA_OUT[RANK_BIT_WIDTH-1:0]           (
                                                              CC_WR_DATA_OUT,

                                                              DATA_BUS_SHF,
                                                              SB_DATA_OUT,

                                                              FSM_WR_DATA_MUX
                                                            );
mux2$   mux2$_CC_HIT_DATA_OUT[RANK_BIT_WIDTH-1:0]          (
                                                              CC_HIT_DATA_OUT,

                                                              CACHE_RD_DATA,
                                                              SB_DATA_OUT,

                                                              FSM_HIT_DATA_MUX
                                                            );

mux4$   mux4$_CC_DATA_WR_MASK_OUT[NUM_WAYS*RANK_BURST_SIZE-1:0]
                                                            (
                                                              CC_DATA_WR_MASK_OUT,

                                                              CC_DATA_WR_MASK_DEFAULT,
                                                              Q_CC_DATA_WR_MASK_OUT_01,
                                                              Q_CC_DATA_WR_MASK_OUT_10,
                                                              CC_DATA_WR_MASK_DEFAULT,

                                                              FSM_DATA_WR_MASK_MUX[0],
                                                              FSM_DATA_WR_MASK_MUX[1]
                                                            );

mux2$   mux2$_CC_TAG_WR_MASK_OUT[NUM_WAYS-1:0]             (
                                                              CC_TAG_WR_MASK_OUT,

                                                              {NUM_WAYS{1'b1}},
                                                              Q_CC_TAG_WR_MASK_OUT_1,

                                                              FSM_TAG_WR_MASK_MUX
                                                            );

/*** BUS DRIVERS ***/

tristate_bus_driver1$   tristate_bus_driver1$_ADDR_BUS[MEM_ADDR_WIDTH-1:0]
                                                       (
                                                          .enbar(FSM_ADDR_BUS_ENBAR),
                                                          .in({Q_CC_ADDR_OUT_1, 4'b0000}),
                                                          .out(ADDR_BUS)
                                                       );

wire  [2:0]   REQS_GATED;
and2$   and2$_REQS_GATED[2:0](REQS_GATED, Q_CC_RD_RQ, FSM_GATE_RQ);

tristate_bus_driver1$   tristate_bus_driver1$_REQS[2:0]
                                                       (
                                                          .enbar(1'b0),
                                                          .in(REQS_GATED),
                                                          .out(REQS)
                                                       );

/* Inverters */
wire Q2_bar;
wire Q0_bar;
wire SB_FILL_DONE_bar;
inv1$ inv_2(SB_FILL_DONE_bar, SB_FILL_DONE);
wire Q1_bar;
wire ARB_ACK_RECV_bar;
inv1$ inv_4(ARB_ACK_RECV_bar, ARB_ACK_RECV);
wire CACHE_FILL_DONE_bar;
inv1$ inv_5(CACHE_FILL_DONE_bar, CACHE_FILL_DONE);
wire DATA_VALID_BAR_bar;
inv1$ inv_6(DATA_VALID_BAR_bar, DATA_VALID_BAR);

/* Product Expressions */
wire and_0_0_out;
wire and_0_1_out;
and4$ and_0_0(and_0_0_out,and_0_1_out,Q2_bar,Q1_bar,Q0_bar);
and2$ and_0_1(and_0_1_out,CACHE_MISS,CC_STREAM_BUF_HIT);
wire and_1_0_out;
and4$ and_1_0(and_1_0_out,Q2_bar,Q1,Q0_bar,DATA_VALID_BAR_bar);
wire and_2_0_out;
and4$ and_2_0(and_2_0_out,Q2_bar,Q1_bar,Q0_bar,CACHE_MISS);
wire and_3_0_out;
and4$ and_3_0(and_3_0_out,Q2,Q1_bar,Q0,SB_FILL_DONE);
wire and_4_0_out;
and4$ and_4_0(and_4_0_out,Q2,Q1_bar,Q0,SB_FILL_DONE_bar);
wire and_5_0_out;
and4$ and_5_0(and_5_0_out,Q2_bar,Q1_bar,Q0,ARB_ACK_RECV);
wire and_6_0_out;
and4$ and_6_0(and_6_0_out,Q2_bar,Q1_bar,Q0,ARB_ACK_RECV_bar);
wire and_7_0_out;
and3$ and_7_0(and_7_0_out,Q2,Q1,Q0_bar);
wire and_8_0_out;
and3$ and_8_0(and_8_0_out,Q2,Q1,Q0);
wire and_9_0_out;
and4$ and_9_0(and_9_0_out,Q2_bar,Q1,Q0,CACHE_FILL_DONE);
wire and_10_0_out;
assign and_10_0_out = Q1_bar;
wire and_11_0_out;
and3$ and_11_0(and_11_0_out,Q2_bar,Q1,Q0_bar);
wire and_12_0_out;
and4$ and_12_0(and_12_0_out,Q2_bar,Q1,Q0,CACHE_FILL_DONE_bar);
wire and_13_0_out;
and3$ and_13_0(and_13_0_out,Q2,Q1_bar,Q0_bar);

/* Sum Expressions */
wire or_0_1_out;
or4$ or_0_0(D2,or_0_1_out,and_0_0_out,and_3_0_out,and_4_0_out);
or2$ or_0_1(or_0_1_out,and_9_0_out,and_13_0_out);
wire or_1_1_out;
or4$ or_1_0(D1,or_1_1_out,and_0_0_out,and_3_0_out,and_5_0_out);
or2$ or_1_1(or_1_1_out,and_11_0_out,and_12_0_out);
wire or_2_1_out;
or4$ or_2_0(D0,or_2_1_out,and_1_0_out,and_2_0_out,and_4_0_out);
or3$ or_2_1(or_2_1_out,and_6_0_out,and_12_0_out,and_13_0_out);
assign FSM_LD_REGS = and_2_0_out;
or3$ or_4_0(FSM_SHF_DATA_WR_MASK,and_1_0_out,and_9_0_out,and_12_0_out);
or4$ or_5_0(FSM_DATA_WR_MASK_MUX[0],and_9_0_out,and_11_0_out,and_12_0_out,and_13_0_out);
assign FSM_DATA_WR_MASK_MUX[1] = and_8_0_out;
or2$ or_7_0(FSM_TAG_WR_MASK_MUX,and_8_0_out,and_13_0_out);
or3$ or_8_0(FSM_SB_WR_EN,and_3_0_out,and_4_0_out,and_7_0_out);
assign FSM_SET_SB_VALID = and_7_0_out;
assign FSM_WR_DATA_MUX = and_8_0_out;
wire or_11_1_out;
or4$ or_11_0(FSM_ADDR_MUX,or_11_1_out,and_8_0_out,and_9_0_out,and_11_0_out);
or2$ or_11_1(or_11_1_out,and_12_0_out,and_13_0_out);
or2$ or_12_0(FSM_GATE_RQ,and_5_0_out,and_6_0_out);
wire or_13_1_out;
or4$ or_13_0(FSM_ADDR_BUS_ENBAR,or_13_1_out,and_7_0_out,and_8_0_out,and_9_0_out);
or2$ or_13_1(or_13_1_out,and_10_0_out,and_12_0_out);
wire or_14_1_out;
or4$ or_14_0(CC_FSM_FILL_BUSY,or_14_1_out,and_5_0_out,and_6_0_out,and_9_0_out);
or3$ or_14_1(or_14_1_out,and_11_0_out,and_12_0_out,and_13_0_out);
assign FSM_IN_010 = and_11_0_out;

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);
dff$ dff_1(clk, D1, Q1, Q1_bar, rst, 1'b1);
dff$ dff_2(clk, D2, Q2, Q2_bar, rst, 1'b1);

endmodule