module cache_controller #(
  parameter   STREAM_BUFFER_EN=1'b1,
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
  output    [NUM_WAYS-1:0]                          CC_TAG_WR_MASK_OUT,
  output    [TAG_WIDTH-1:0]                         CC_TAG_IN,

  /*** TO VALID STORE ***/
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

wire        Q2_prebuf,Q1_prebuf,Q0_prebuf;
wire        Q2_bar_prebuf,Q1_bar_prebuf,Q0_bar_prebuf;

bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);

/*** STATE MACHINE OUTPUTS ***/

wire          ARB_ACK_RECV;
wire          ARB_ACK_RECV_bar;
nor3$ nor_3(ARB_ACK_RECV_bar, ACKS[2], ACKS[1], ACKS[0]);
inv1$  inv_3$_(ARB_ACK_RECV, ARB_ACK_RECV_bar);

/* DECLARATIONS */
wire          FSM_LD_REGS, FSM_SHF_DATA_WR_MASK, FSM_TAG_WR_MASK_MUX,
              FSM_SB_WR_EN, FSM_SET_SB_VALID,
              FSM_WR_DATA_MUX, FSM_HIT_DATA_MUX, FSM_ADDR_MUX, FSM_GATE_RQ,
              FSM_ADDR_BUS_ENBAR, 
              FSM_IN_010;

wire  [1:0]   FSM_DATA_WR_MASK_MUX, FSM_DATA_BUS_SHF_MUX_buf16;

/* COUNTER */

wire  [2:0] counter, counter_buf16, inc_counter, next_counter;

bufferH16$   bufferH16$_counter_buf16[2:0](counter_buf16, counter);

big_increment #(
  .WIDTH(3)
) big_increment_inc_counter (
  .a(counter_buf16),
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

big_eq  #(.WIDTH(3)) done_CACHE_FILL_DONE (.in0(counter_buf16), .in1(W_CT_CACHE_FILL_DONE     ), .eq(CACHE_FILL_DONE  ));
big_eq  #(.WIDTH(3)) done_SB_FILL_DONE    (.in0(counter_buf16), .in1(W_CT_SB_FILL_DONE        ), .eq(SB_FILL_DONE     ));

/* Easy Counter-Related Wires */

wire    [RANK_BURST_SIZE-1:0]               CC_STREAM_BUF_WR_MASK, CC_STREAM_BUF_WR_MASK_GATED;

decoder2_4$   decoder2_4$_CC_STREAM_BUF_WR_MASK(.SEL(counter_buf16[1:0]),
                                                 .Y(CC_STREAM_BUF_WR_MASK), .YBAR());

and2$         and2$_CC_STREAM_BUF_WR_MASK_GATED[RANK_BURST_SIZE-1:0](CC_STREAM_BUF_WR_MASK_GATED,
                                                                      CC_STREAM_BUF_WR_MASK,
                                                                      {RANK_BURST_SIZE{FSM_SB_WR_EN}});

and2$         and2$_FSM_HIT_DATA_MUX(FSM_HIT_DATA_MUX, CACHE_MISS, CC_STREAM_BUF_HIT);

wire  FSM_HIT_DATA_MUX_buf16;
bufferH16$    bufferH16$_FSM_HIT_DATA_MUX_buf16(FSM_HIT_DATA_MUX_buf16, FSM_HIT_DATA_MUX);

assign  FSM_DATA_BUS_SHF_MUX_buf16 = counter_buf16[1:0];

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


genvar j;

generate
  for (j = 0; j < 8; j = j + 1) begin : mux4_16_GEN_DATA_BUS_SHF
    mux4_16$   mux4_16$_DATA_BUS_SHF  
                                        (
                                          DATA_BUS_SHF[j*16 +: 16],

                                          DATA_BUS_ZEXT[j*16 +: 16],
                                          DATA_BUS_SHF_01[j*16 +: 16],
                                          DATA_BUS_SHF_10[j*16 +: 16],
                                          DATA_BUS_SHF_11[j*16 +: 16],

                                          FSM_DATA_BUS_SHF_MUX_buf16[0],
                                          FSM_DATA_BUS_SHF_MUX_buf16[1]
                                        );
  end
endgenerate

/*** REGISTERS ***/

wire  [NUM_WAYS*RANK_BURST_SIZE-1:0]          D0_CC_DATA_WR_MASK_OUT_01, D1_CC_DATA_WR_MASK_OUT_01, 
                                              D_CC_DATA_WR_MASK_OUT_01, D_CC_DATA_WR_MASK_OUT_11;
wire  [NUM_WAYS-1:0]                          D_CC_TAG_WR_MASK_OUT_1;
wire  [INDEX_WIDTH+WAY_WIDTH-1:0]             D_CC_VALID_WR_EN_1, D_CC_VALID_WR_EN_1_buf16;

bufferH16$    bufferH16$_D_CC_VALID_WR_EN_1_buf16[INDEX_WIDTH+WAY_WIDTH-1:0](D_CC_VALID_WR_EN_1_buf16, D_CC_VALID_WR_EN_1);

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

mux2_16$   mux2_16$_D_CC_DATA_WR_MASK_OUT_01 (
                                                D_CC_DATA_WR_MASK_OUT_01,
                                                D0_CC_DATA_WR_MASK_OUT_01,
                                                D1_CC_DATA_WR_MASK_OUT_01,
                                                FSM_SHF_DATA_WR_MASK
                                              );

wire    LD_CC_DATA_WR_MASK_OUT_01, LD_CC_DATA_WR_MASK_OUT_01_buf16;

wire    FSM_LD_REGS_buf64;

bufferH64$    bufferH64$_FSM_LD_REGS_buf64(FSM_LD_REGS_buf64, FSM_LD_REGS);

or2$    or2$_LD_CC_DATA_WR_MASK_OUT_01(LD_CC_DATA_WR_MASK_OUT_01,
                                        FSM_SHF_DATA_WR_MASK,
                                        FSM_LD_REGS_buf64);

bufferH16$    bufferH16$_LD_CC_DATA_WR_MASK_OUT_01_buf16(LD_CC_DATA_WR_MASK_OUT_01_buf16, LD_CC_DATA_WR_MASK_OUT_01);

reg_n #(
  .WIDTH(NUM_WAYS*RANK_BURST_SIZE),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) reg_n_Q_CC_DATA_WR_MASK_OUT_01 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS*RANK_BURST_SIZE{LD_CC_DATA_WR_MASK_OUT_01_buf16}}), .d(D_CC_DATA_WR_MASK_OUT_01),
  .q(Q_CC_DATA_WR_MASK_OUT_01)
);

reg_n #(
  .WIDTH(NUM_WAYS*RANK_BURST_SIZE),
  .USE_EN_BAR(0),
  .RESET_TO_ONES(1)
) reg_n_Q_CC_DATA_WR_MASK_OUT_10 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS*RANK_BURST_SIZE{FSM_LD_REGS_buf64}}), .d(D_CC_DATA_WR_MASK_OUT_11),
  .q(Q_CC_DATA_WR_MASK_OUT_10)
);

reg_n #(
  .WIDTH(NUM_WAYS),
  .USE_EN_BAR(0)
) reg_n_Q_CC_TAG_WR_MASK_OUT_1 (
  .clk(clk), .rst(rst),
  .en({NUM_WAYS{FSM_LD_REGS_buf64}}), .d(D_CC_TAG_WR_MASK_OUT_1),
  .q(Q_CC_TAG_WR_MASK_OUT_1)
);

reg_n #(
  .WIDTH(INDEX_WIDTH+WAY_WIDTH),
  .USE_EN_BAR(0)
) reg_n_Q_CC_VALID_WR_EN_1 (
  .clk(clk), .rst(rst),
  .en({(INDEX_WIDTH+WAY_WIDTH){FSM_LD_REGS_buf64}}), .d(D_CC_VALID_WR_EN_1_buf16),
  .q(Q_CC_VALID_WR_EN_1)
);

wire [2:0] CC_VALID_WR_EN_DUMMY;

mux2_8$   mux2_8$_CC_VALID_WR_EN    (
                                      {CC_VALID_WR_EN_DUMMY, CC_VALID_WR_EN}, 
                                      {3'b000, {INDEX_WIDTH+WAY_WIDTH{1'b0}}},
                                      {3'b000, Q_CC_VALID_WR_EN_1},
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
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){FSM_LD_REGS_buf64}}), .d(CACHE_PHYS_ADDR),
  .q(Q_CC_ADDR_OUT_1)
);

assign CC_TAG_IN = Q_CC_ADDR_OUT_1[MEM_ADDR_WIDTH-1:MEM_ADDR_WIDTH-1-7];

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
  .en({(MEM_ADDR_WIDTH-RANK_BURST_SIZE){FSM_LD_REGS_buf64}}), .d(D_CC_NL_PHYS_ADDR),
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
  .en({(3){FSM_LD_REGS_buf64}}), .d(D_CC_RD_RQ),
  .q(Q_CC_RD_RQ)
);

/*** STREAM BUFFER ***/

wire    [RANK_BIT_WIDTH-1:0]                SB_DATA_OUT;

stream_buffer #(
  .STREAM_BUFFER_EN(STREAM_BUFFER_EN)
) stream_buffer_inst (
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

wire  [4:0] CC_ADDR_OUT_DUMMY;

mux2_16$   mux2_16$_CC_ADDR_OUT (
                                  {CC_ADDR_OUT_DUMMY, CC_ADDR_OUT},

                                  {5'd0, CACHE_PHYS_ADDR},
                                  {5'd0, Q_CC_ADDR_OUT_1},

                                  FSM_ADDR_MUX
                                );

wire    FSM_WR_DATA_MUX_buf16;

bufferH16$    bufferH16$_FSM_WR_DATA_MUX_buf16(FSM_WR_DATA_MUX_buf16, FSM_WR_DATA_MUX);

generate
  for (j = 0; j < 8; j = j + 1) begin : MUX2_16b_GEN_DATA
    mux2_16$   mux2_16$_CC_WR_DATA_OUT  (
                                          CC_WR_DATA_OUT[j*16 +: 16],

                                          DATA_BUS_SHF[j*16 +: 16],
                                          SB_DATA_OUT[j*16 +: 16],

                                          FSM_WR_DATA_MUX_buf16
                                        );
  end
endgenerate

generate
  for (j = 0; j < 8; j = j + 1) begin : MUX2_16b_GEN
    mux2_16$   mux2_16$_CC_HIT_DATA_OUT (
                                          CC_HIT_DATA_OUT[j*16 +: 16],

                                          CACHE_RD_DATA[j*16 +: 16],
                                          SB_DATA_OUT[j*16 +: 16],

                                          FSM_HIT_DATA_MUX_buf16
                                        );
  end
endgenerate

mux4_16$  mux4_16$_CC_DATA_WR_MASK_OUT
                                                            (
                                                              CC_DATA_WR_MASK_OUT,

                                                              CC_DATA_WR_MASK_DEFAULT,
                                                              Q_CC_DATA_WR_MASK_OUT_01,
                                                              Q_CC_DATA_WR_MASK_OUT_10,
                                                              CC_DATA_WR_MASK_DEFAULT,

                                                              FSM_DATA_WR_MASK_MUX[0],
                                                              FSM_DATA_WR_MASK_MUX[1]
                                                            );

wire [3:0] CC_TAG_WR_MASK_OUT_DUMMY;

mux2_8$   mux2_8$_CC_TAG_WR_MASK_OUT  (
                                        {CC_TAG_WR_MASK_OUT_DUMMY, CC_TAG_WR_MASK_OUT},

                                        {4'b0000, {NUM_WAYS{1'b1}}},
                                        {4'b0000, Q_CC_TAG_WR_MASK_OUT_1},

                                        FSM_TAG_WR_MASK_MUX
                                      );

/*** BUS DRIVERS ***/

wire  ADDR_BUS_DUMMY;

tristate_bus_driver16$   tristate_bus_driver16$_ADDR_BUS
                                                       (
                                                          .enbar(FSM_ADDR_BUS_ENBAR),
                                                          .in({1'b0, Q_CC_ADDR_OUT_1, 4'b0000}),
                                                          .out({ADDR_BUS_DUMMY, ADDR_BUS})
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
        wire Q0_bar;
        wire Q1_bar;
        wire Q2_bar;
        wire CACHE_FILL_DONE_bar;
        inv1$ inv_3(CACHE_FILL_DONE_bar, CACHE_FILL_DONE);
        wire DATA_VALID_BAR_bar;
        inv1$ inv_4(DATA_VALID_BAR_bar, DATA_VALID_BAR);
        wire SB_FILL_DONE_bar;
        inv1$ inv_6(SB_FILL_DONE_bar, SB_FILL_DONE);

        /* Product Expressions */
        wire nand_0_0_0_out;
        wire nand_0_1_0_out;
        nand4$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,Q2_bar,Q1_bar,Q0_bar);
        and2$ nand_0_1_0(nand_0_1_0_out,CACHE_MISS,CC_STREAM_BUF_HIT);
        wire nand_1_0_0_out;
        nand4$ nand_1_0_0(nand_1_0_0_out,Q2_bar,Q1,Q0_bar,DATA_VALID_BAR_bar);
        wire nand_2_0_0_out;
        nand4$ nand_2_0_0(nand_2_0_0_out,Q2_bar,Q1_bar,Q0_bar,CACHE_MISS);
        wire nand_3_0_0_out;
        nand4$ nand_3_0_0(nand_3_0_0_out,Q2,Q1_bar,Q0,SB_FILL_DONE);
        wire nand_4_0_0_out;
        nand4$ nand_4_0_0(nand_4_0_0_out,Q2,Q1_bar,Q0,SB_FILL_DONE_bar);
        wire nand_5_0_0_out;
        nand3$ nand_5_0_0(nand_5_0_0_out,Q2,Q1,Q0_bar);
        wire nand_6_0_0_out;
        nand4$ nand_6_0_0(nand_6_0_0_out,Q2_bar,Q1_bar,Q0,ARB_ACK_RECV);
        wire nand_7_0_0_out;
        nand3$ nand_7_0_0(nand_7_0_0_out,Q2_bar,Q1_bar,Q0_bar);
        wire nand_8_0_0_out;
        nand4$ nand_8_0_0(nand_8_0_0_out,Q2_bar,Q1_bar,Q0,ARB_ACK_RECV_bar);
        wire nand_9_0_0_out;
        nand3$ nand_9_0_0(nand_9_0_0_out,Q2,Q1,Q0);
        wire nand_10_0_0_out;
        nand4$ nand_10_0_0(nand_10_0_0_out,Q2_bar,Q1,Q0,CACHE_FILL_DONE);
        wire nand_11_0_0_out;
        nand4$ nand_11_0_0(nand_11_0_0_out,Q2_bar,Q1,Q0,CACHE_FILL_DONE_bar);
        wire nand_12_0_0_out;
        nand3$ nand_12_0_0(nand_12_0_0_out,Q2_bar,Q1,Q0_bar);
        wire nand_13_0_0_out;
        nand3$ nand_13_0_0(nand_13_0_0_out,Q2,Q1_bar,Q0_bar);

        /* Sum Expressions */
        wire nand_0_1_1_out;
        nand4$ nand_0_0_1(D2,nand_0_1_1_out,nand_0_0_0_out,nand_3_0_0_out,nand_4_0_0_out);
        and2$ nand_0_1_1(nand_0_1_1_out,nand_10_0_0_out,nand_13_0_0_out);
        wire nand_1_1_1_out;
        nand4$ nand_1_0_1(D1,nand_1_1_1_out,nand_0_0_0_out,nand_3_0_0_out,nand_6_0_0_out);
        and2$ nand_1_1_1(nand_1_1_1_out,nand_11_0_0_out,nand_12_0_0_out);
        wire nand_2_1_1_out;
        nand4$ nand_2_0_1(D0,nand_2_1_1_out,nand_1_0_0_out,nand_2_0_0_out,nand_4_0_0_out);
        and3$ nand_2_1_1(nand_2_1_1_out,nand_8_0_0_out,nand_11_0_0_out,nand_13_0_0_out);
        inv1$ nand_3_0_1(FSM_LD_REGS, nand_2_0_0_out);
        nand3$ nand_4_0_1(FSM_SHF_DATA_WR_MASK,nand_1_0_0_out,nand_10_0_0_out,nand_11_0_0_out);
        nand4$ nand_5_0_1(FSM_DATA_WR_MASK_MUX[0],nand_10_0_0_out,nand_11_0_0_out,nand_12_0_0_out,nand_13_0_0_out);
        inv1$ nand_6_0_1(FSM_DATA_WR_MASK_MUX[1], nand_9_0_0_out);
        nand2$ nand_7_0_1(FSM_TAG_WR_MASK_MUX,nand_9_0_0_out,nand_13_0_0_out);
        nand3$ nand_8_0_1(FSM_SB_WR_EN,nand_3_0_0_out,nand_4_0_0_out,nand_5_0_0_out);
        inv1$ nand_9_0_1(FSM_SET_SB_VALID, nand_5_0_0_out);
        inv1$ nand_10_0_1(FSM_WR_DATA_MUX, nand_9_0_0_out);
        wire nand_11_1_1_out;
        nand4$ nand_11_0_1(FSM_ADDR_MUX,nand_11_1_1_out,nand_9_0_0_out,nand_10_0_0_out,nand_11_0_0_out);
        and2$ nand_11_1_1(nand_11_1_1_out,nand_12_0_0_out,nand_13_0_0_out);
        nand2$ nand_12_0_1(FSM_GATE_RQ,nand_6_0_0_out,nand_8_0_0_out);
        nand3$ nand_13_0_1(FSM_ADDR_BUS_ENBAR,nand_7_0_0_out,nand_8_0_0_out,nand_9_0_0_out);
        wire nand_14_1_1_out;
        nand4$ nand_14_0_1(CC_FSM_FILL_BUSY,nand_14_1_1_out,nand_6_0_0_out,nand_8_0_0_out,nand_10_0_0_out);
        and3$ nand_14_1_1(nand_14_1_1_out,nand_11_0_0_out,nand_12_0_0_out,nand_13_0_0_out);
        inv1$ nand_15_0_1(FSM_IN_010, nand_12_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0_prebuf, Q0_bar_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, Q1_prebuf, Q1_bar_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, Q2_prebuf, Q2_bar_prebuf, rst, 1'b1);

/* INVERT STATE BITS */

bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);

endmodule