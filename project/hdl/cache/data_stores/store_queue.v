module store_queue #(
  parameter MEM_BYTE_CAPACITY=32768,
  parameter MEM_ADDR_WIDTH=$clog2(MEM_BYTE_CAPACITY),

  parameter CHIP_BIT_WIDTH=8,
  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  parameter CHIPS_PER_RANK=RANK_BIT_WIDTH/CHIP_BIT_WIDTH,

  parameter PHYS_LINE_BIT_WIDTH=MEM_ADDR_WIDTH-RANK_BURST_SIZE,
  parameter BYTES_PER_BUS=4,

  /**
    * ORDER (MSB to LSB):
    * 
    * PENDING      - alone
    *
    * DATA         - [154:27]
    * PHYS_ADDR    - [26:16]
    * DATA_WR_MASK - [15:0]
    *
    **/
  parameter ENTRY_BIT_WIDTH=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH+RANK_BIT_WIDTH,
  parameter PHYS_ADDR_TOP_BIT=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH-1,
  parameter DATA_BOT_BIT=CHIPS_PER_RANK+PHYS_LINE_BIT_WIDTH,

  parameter NUM_ENTRIES=4,
  parameter PTR_WIDTH=$clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH=PTR_WIDTH+1,
  parameter MULTI_WRITE_AMT=2
) (
  input                                       clk,
  input                                       rst_n,
  input   [MULTI_WRITE_AMT-1:0]               wr,
  input                                       rd,
  input   [ENTRY_BIT_WIDTH-1:0]               data_in0,
  input   [ENTRY_BIT_WIDTH-1:0]               data_in1,

  output                                      empty,
  output                                      full,
  output  [COUNT_WIDTH-1:0]                   entry_count,
  output  [RANK_BIT_WIDTH-1:0]                STOREQ_DATA,
  output  [RANK_BURST_SIZE*BYTES_PER_BUS-1:0] STOREQ_DATA_WR_MASK,
  output  [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  STOREQ_PHYS_ADDR
);

/*** WRITE POINTER LOGIC ***/

wire    [NUM_ENTRIES-1:0]       wr_one_hot, wr_plus_1_one_hot, wr_one_hot_gated, wr_plus_1_one_hot_gated;
wire    [PTR_WIDTH-1:0]         wr_ptr, wr_ptr_plus_1, wr_ptr_plus_2, wr_ptr_next;

big_increment #(
  .WIDTH(PTR_WIDTH)
) big_increment_wr_ptr_plus_1 (
  .a(wr_ptr),
  .s(wr_ptr_plus_1)
);

big_increment #(
  .WIDTH(PTR_WIDTH)
) big_increment_wr_ptr_plus_2 (
  .a(wr_ptr_plus_1),
  .s(wr_ptr_plus_2)
);

mux2$   mux2$_wr_ptr_next[PTR_WIDTH-1:0](wr_ptr_next, wr_ptr_plus_1, wr_ptr_plus_2, wr[1]);

reg_n #(
  .WIDTH(PTR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_wr_ptr (
  .clk(clk), .rst(rst_n),
  .en({PTR_WIDTH{wr[0]}}), .d(wr_ptr_next),
  .q(wr_ptr)
);

/*** READ POINTER LOGIC ***/

wire    [NUM_ENTRIES-1:0]       rd_one_hot, rd_one_hot_gated;
wire    [PTR_WIDTH-1:0]         rd_ptr, rd_ptr_plus_1;

big_increment #(
  .WIDTH(PTR_WIDTH)
) big_increment_rd_ptr_plus_1 (
  .a(rd_ptr),
  .s(rd_ptr_plus_1)
);

reg_n #(
  .WIDTH(PTR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_rd_ptr (
  .clk(clk), .rst(rst_n),
  .en({PTR_WIDTH{rd}}), .d(rd_ptr_plus_1),
  .q(rd_ptr)
);

/*** ENTRY COUNT LOGIC ***/

wire    [COUNT_WIDTH-1:0]       entry_count_plus_1, entry_count_plus_2, entry_count_minus_1, entry_count_next;

big_increment #(
  .WIDTH(COUNT_WIDTH)
) big_increment_entry_count_plus_1 (
  .a(entry_count),
  .s(entry_count_plus_1)
);

big_increment #(
  .WIDTH(COUNT_WIDTH)
) big_increment_entry_count_plus_2 (
  .a(entry_count_plus_1),
  .s(entry_count_plus_2)
);

big_decrement #(
  .WIDTH(COUNT_WIDTH)
) big_decrement_entry_count_plus_1 (
  .a(entry_count),
  .s(entry_count_minus_1)
);

mux3$   mux3$_entry_count_next[COUNT_WIDTH-1:0](entry_count_next,
                                                entry_count_plus_1, 
                                                entry_count_minus_1,
                                                entry_count_plus_2,
                                                rd, wr[1]);

wire    update_entry_count;

or2$    or2$_update_entry_count(update_entry_count, wr[0], rd);

reg_n #(
  .WIDTH(COUNT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_entry_count (
  .clk(clk), .rst(rst_n),
  .en({COUNT_WIDTH{update_entry_count}}), .d(entry_count_next),
  .q(entry_count)
);

/*** ONE-HOT RD / WR LOGIC ***/

decoder2_4$   decoder2_4$_wr_one_hot(.SEL(wr_ptr), .Y(wr_one_hot), .YBAR());
decoder2_4$   decoder2_4$_wr_plus_1_one_hot(.SEL(wr_ptr_plus_1), .Y(wr_plus_1_one_hot), .YBAR());

decoder2_4$   decoder2_4$_rd_one_hot(.SEL(rd_ptr), .Y(rd_one_hot), .YBAR());

and2$         and2$_wr_one_hot_gated[NUM_ENTRIES-1:0](wr_one_hot_gated, wr_one_hot, wr[0]);
and2$         and2$_wr_plus_1_one_hot_gated[NUM_ENTRIES-1:0](wr_plus_1_one_hot_gated, wr_plus_1_one_hot, wr[0]);
and2$         and2$_rd_one_hot_gated[NUM_ENTRIES-1:0](rd_one_hot_gated, rd_one_hot, rd);

wire    [NUM_ENTRIES-1:0]   wr_one_hot_gated_combined, wr_one_hot_gated_final;

or2$          or2$_wr_one_hot_gated_combined[NUM_ENTRIES-1:0](wr_one_hot_gated_combined, wr_one_hot_gated, wr_plus_1_one_hot_gated);
mux2$         mux2$_wr_one_hot_gated_final[NUM_ENTRIES-1:0](wr_one_hot_gated_final, wr_one_hot_gated, wr_one_hot_gated_combined, wr[1]);

/*** ENTRY INSTANTIATION ***/

wire    [ENTRY_BIT_WIDTH-1:0]   data_out_full[0:NUM_ENTRIES-1];
wire    [NUM_ENTRIES-1:0]       pending_full;

wire    [ENTRY_BIT_WIDTH-1:0]   data_in_even_odd[0:1];
wire    [4:0]                   data_in_even_odd_dummy[0:1];

genvar i;

generate
  for (i = 0; i < 9; i = i + 1) begin : DATA_IN_MUX2_16b_GEN
    mux2_16$ mux2_16_data_in_evens (
      .IN0 (data_in0[i*16 +: 16]),
      .IN1 (data_in1[i*16 +: 16]),
      .S0(wr_ptr[0]),
      .Y(data_in_even_odd[0][i*16 +: 16])
    );
    mux2_16$ mux2_16_data_in_odds (
      .IN0 (data_in1[i*16 +: 16]),
      .IN1 (data_in0[i*16 +: 16]),
      .S0(wr_ptr[0]),
      .Y(data_in_even_odd[1][i*16 +: 16])
    );
  end
endgenerate

mux2_16$ mux2_16_data_in_evens_last (
  .IN0 ({5'd0, data_in0[ENTRY_BIT_WIDTH-1:9*16]}),
  .IN1 ({5'd0, data_in1[ENTRY_BIT_WIDTH-1:9*16]}),
  .S0(wr_ptr[0]),
  .Y({data_in_even_odd_dummy[0], data_in_even_odd[0][ENTRY_BIT_WIDTH-1:9*16]})
);

mux2_16$ mux2_16_data_in_odds_last (
  .IN0 ({5'd0, data_in1[ENTRY_BIT_WIDTH-1:9*16]}),
  .IN1 ({5'd0, data_in0[ENTRY_BIT_WIDTH-1:9*16]}),
  .S0(wr_ptr[0]),
  .Y({data_in_even_odd_dummy[1], data_in_even_odd[1][ENTRY_BIT_WIDTH-1:9*16]})
);

generate
  for (i = 0; i < NUM_ENTRIES; i = i + 1) begin : STORE_QUEUE_ENTRY_GEN
    store_queue_entry store_queue_entry_inst (
      .clk(clk),
      .rst_n(rst_n),
      .wr(wr_one_hot_gated_final[i]),
      .rd(rd_one_hot_gated[i]),
      .data_in(data_in_even_odd[i % 2]),
      .data_out(data_out_full[i]),
      .pending(pending_full[i])
    );
  end
endgenerate

/*** DATA OUTPUT SELECTION ***/

generate
  for (i = 0; i < 8; i = i + 1) begin : STOREQ_DATA_MUX4_16b_GEN
    mux4_16$ mux4_16_STOREQ_DATA (
      .IN0 (data_out_full[0][(DATA_BOT_BIT+i*16) +: 16]),
      .IN1 (data_out_full[1][(DATA_BOT_BIT+i*16) +: 16]),
      .IN2 (data_out_full[2][(DATA_BOT_BIT+i*16) +: 16]),
      .IN3 (data_out_full[3][(DATA_BOT_BIT+i*16) +: 16]),
      .S0(rd_ptr[0]),
      .S1(rd_ptr[1]),
      .Y(STOREQ_DATA[i*16 +: 16])
    );
  end
endgenerate

wire    [4:0]   STOREQ_PHYS_ADDR_DUMMY;

mux4_16$ mux4_16_STOREQ_PHYS_ADDR (
  .IN0 ({5'd0, data_out_full[0][PHYS_ADDR_TOP_BIT:CHIPS_PER_RANK]}),
  .IN1 ({5'd0, data_out_full[1][PHYS_ADDR_TOP_BIT:CHIPS_PER_RANK]}),
  .IN2 ({5'd0, data_out_full[2][PHYS_ADDR_TOP_BIT:CHIPS_PER_RANK]}),
  .IN3 ({5'd0, data_out_full[3][PHYS_ADDR_TOP_BIT:CHIPS_PER_RANK]}),
  .S0(rd_ptr[0]),
  .S1(rd_ptr[1]),
  .Y({STOREQ_PHYS_ADDR_DUMMY, STOREQ_PHYS_ADDR})
);

mux4_16$ mux4_16_STOREQ_DATA_WR_MASK (
  .IN0 (data_out_full[0][CHIPS_PER_RANK-1:0]),
  .IN1 (data_out_full[1][CHIPS_PER_RANK-1:0]),
  .IN2 (data_out_full[2][CHIPS_PER_RANK-1:0]),
  .IN3 (data_out_full[3][CHIPS_PER_RANK-1:0]),
  .S0(rd_ptr[0]),
  .S1(rd_ptr[1]),
  .Y(STOREQ_DATA_WR_MASK)
);

/*** STATUS LOGIC ***/

wire    three_entries;

and2$   and2$_three_entries(three_entries, entry_count[0], entry_count[1]);
or2$    or2$_full(full, three_entries, entry_count[2]);

nor3$   nor3$_empty(empty, entry_count[0], entry_count[1], entry_count[2]);

endmodule