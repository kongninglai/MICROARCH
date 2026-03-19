module valid_or_dirty_store #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS)
) (
  input                                 clk, rst,
  input   [INDEX_WIDTH-1:0]             set_index,
  input                                 set_or_clr,
  input   [INDEX_WIDTH+WAY_WIDTH-1:0]   wr_en,
  input                                 wr_en_global,

  output  [NUM_WAYS-1:0]                out
);

wire                  set_or_clr_buf64;

bufferH64$    bufferH64$_set_or_clr_buf64(set_or_clr_buf64, set_or_clr);

wire                  wr_en_global_buf64;

bufferH64$    bufferH64$_wr_en_global_buf64(wr_en_global_buf64, wr_en_global);

wire  [NUM_SETS-1:0]  wr_en_one_hot_set;
wire  [NUM_WAYS-1:0]  wr_en_one_hot_way, wr_en_one_hot_way_buf16;

decoder3_8$   decoder3_8$_wr_en_one_hot_set(.SEL(wr_en[INDEX_WIDTH+WAY_WIDTH-1:WAY_WIDTH]), 
                                            .Y(wr_en_one_hot_set), 
                                            .YBAR());

decoder2_4$   decoder2_4$_wr_en_one_hot_way(.SEL(wr_en[WAY_WIDTH-1:0]), 
                                            .Y(wr_en_one_hot_way), 
                                            .YBAR());

bufferH16$    bufferH16$_wr_en_one_hot_way_buf16[NUM_WAYS-1:0](wr_en_one_hot_way_buf16, wr_en_one_hot_way);

wire  [NUM_SETS*NUM_WAYS-1:0] full_store;

genvar i, j;
generate
  for (i = 0; i < NUM_SETS; i = i + 1) begin : valid_per_set
    for (j = 0; j < NUM_WAYS; j = j + 1) begin : valid_per_way
      wire    active_cache_line;

      and3$   and3$_active_cache_line(active_cache_line, 
                                      wr_en_one_hot_set[i],
                                      wr_en_one_hot_way_buf16[j],
                                      wr_en_global_buf64);

      reg_n #(
        .WIDTH(1),
        .USE_EN_BAR(0)
      ) reg_n_stream_buffer_next_line_addr (
        .clk(clk), .rst(rst),
        .en(active_cache_line), .d(set_or_clr_buf64),
        .q(full_store[i*NUM_WAYS+j])
      );
    end
  end
endgenerate

genvar w;
generate
  for (w = 0; w < NUM_WAYS; w = w + 1) begin : mux_bits
    mux8 mux8_out (
      .outb(out[w]),
      .in0(full_store[0*NUM_WAYS + w]),
      .in1(full_store[1*NUM_WAYS + w]),
      .in2(full_store[2*NUM_WAYS + w]),
      .in3(full_store[3*NUM_WAYS + w]),
      .in4(full_store[4*NUM_WAYS + w]),
      .in5(full_store[5*NUM_WAYS + w]),
      .in6(full_store[6*NUM_WAYS + w]),
      .in7(full_store[7*NUM_WAYS + w]),
      .s0(set_index[0]),
      .s1(set_index[1]),
      .s2(set_index[2])
    );
  end
endgenerate

endmodule