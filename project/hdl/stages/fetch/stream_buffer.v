module stream_buffer #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15
) (
  input                                       clk, rst,
  input   [RANK_BURST_SIZE-1:0]               stream_buffer_wr_mask,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  cache_addr, cache_controller_next_line_addr,
  input   [RANK_BIT_WIDTH-1:0]                DATA_BUS_SHF,
  input                                       cache_controller_set_valid,

  output                                      stream_buffer_hit,
  output                                      stream_buffer_miss,
  output  [RANK_BIT_WIDTH-1:0]                stream_buffer_data
);


/*** NEW DATA WRITE LOGIC ***/

wire    [RANK_BURST_SIZE-1:0]         stream_buffer_wr_mask_buf64;

bufferH64$    bufferH64$_stream_buffer_wr_mask_buf64[RANK_BURST_SIZE-1:0]
              (stream_buffer_wr_mask_buf64, stream_buffer_wr_mask);

reg_n #(
  .WIDTH(RANK_BIT_WIDTH),
  .USE_EN_BAR(0)
) reg_n_stream_buffer_data (
  .clk(clk), .rst(rst),
  .en({{BUS_BIT_WIDTH{stream_buffer_wr_mask_buf64[RANK_BURST_SIZE-1]}},
       {BUS_BIT_WIDTH{stream_buffer_wr_mask_buf64[RANK_BURST_SIZE-2]}},
       {BUS_BIT_WIDTH{stream_buffer_wr_mask_buf64[RANK_BURST_SIZE-3]}},
       {BUS_BIT_WIDTH{stream_buffer_wr_mask_buf64[0]}}}), .d(DATA_BUS_SHF),
  .q(stream_buffer_data)
);

/*** VALID BIT ***/

wire    stream_buffer_valid;

wire    cache_controller_set_valid_buf16;

bufferH16$    bufferH16$_cache_controller_set_valid_buf16
              (cache_controller_set_valid_buf16, cache_controller_set_valid);

reg_n #(
  .WIDTH(1),
  .USE_EN_BAR(0)
) reg_n_stream_buffer_valid (
  .clk(clk), .rst(rst),
  .en(cache_controller_set_valid_buf16), .d(1'b1),
  .q(stream_buffer_valid)
);

/*** ADDRESS ***/

wire    [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE] stream_buffer_next_line_addr;

reg_n #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_stream_buffer_next_line_addr (
  .clk(clk), .rst(rst),
  .en({MEM_ADDR_WIDTH-RANK_BURST_SIZE{cache_controller_set_valid_buf16}}), .d(cache_controller_next_line_addr),
  .q(stream_buffer_next_line_addr)
);

/*** HIT / MISS LOGIC ***/

wire stream_buffer_hit_int, stream_buffer_miss_int, not_writing;

big_eq #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE+1)
) big_eq_stream_buffer_hit_int (
  .in0({stream_buffer_valid, stream_buffer_next_line_addr}), .in1({1'b1, cache_addr}),
  .eq(stream_buffer_hit_int)
);

big_neq #(
  .WIDTH(MEM_ADDR_WIDTH-RANK_BURST_SIZE+1)
) big_neq_stream_buffer_miss_int (
  .in0({stream_buffer_valid, stream_buffer_next_line_addr}), .in1({1'b1, cache_addr}),
  .neq(stream_buffer_miss_int)
);

nor4$   nor4$_not_writing(not_writing, stream_buffer_wr_mask[0], stream_buffer_wr_mask[1],
                                       stream_buffer_wr_mask[2], stream_buffer_wr_mask[3]);
or4$         or4$_writing(writing,     stream_buffer_wr_mask[0], stream_buffer_wr_mask[1],
                                       stream_buffer_wr_mask[2], stream_buffer_wr_mask[3]);

and2$   and2$_stream_buffer_hit(stream_buffer_hit, stream_buffer_hit_int, not_writing);
or2$    or2$_stream_buffer_miss(stream_buffer_miss, stream_buffer_miss_int, writing);

endmodule