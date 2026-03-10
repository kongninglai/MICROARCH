module data_store #(
  parameter RANK_BIT_WIDTH=128,
  parameter BUS_BIT_WIDTH=32,
  parameter CHIP_BIT_WIDTH=8,
  parameter RANK_BURST_SIZE=4,
  parameter BYTES_PER_BUS=4,
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter TAG_WIDTH=8
) (
  input   [INDEX_WIDTH-1:0]                             set_index,
  input   [NUM_WAYS*RANK_BURST_SIZE*BYTES_PER_BUS-1:0]  wr_en_bar_one_hot,
  input   [RANK_BIT_WIDTH-1:0]                          data_in,

  output  [NUM_WAYS*RANK_BIT_WIDTH-1:0]                 data_out
);

genvar i, j;
generate
  for (i = 0; i < NUM_WAYS; i = i + 1) begin : data_store_generation
    for (j = 0; j < RANK_BURST_SIZE * BYTES_PER_BUS; j = j + 1) begin : data_position_generation
      ram8b8w$ ram8b8w$_data_store_one_bus  (
                                              .A(set_index),
                                              .DIN(data_in[j*CHIP_BIT_WIDTH +: CHIP_BIT_WIDTH]),
                                              .OE(1'b0),
                                              .WR(wr_en_bar_one_hot[RANK_BURST_SIZE*BYTES_PER_BUS*i+j]), 
                                              .DOUT(data_out[(i*RANK_BIT_WIDTH+j*CHIP_BIT_WIDTH) +: CHIP_BIT_WIDTH])
                                            );
    end
  end
endgenerate

endmodule