module tag_store #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter TAG_WIDTH=8
) (
  input   [INDEX_WIDTH-1:0]         set_index,
  input   [NUM_WAYS-1:0]            wr_en_bar_one_hot,
  input   [TAG_WIDTH-1:0]           tag_in,

  output  [NUM_WAYS*TAG_WIDTH-1:0]  tag_out
);

genvar i;
generate
  for (i = 0; i < NUM_WAYS; i = i + 1) begin : tag_store_generatino
    ram8b8w$ ram8b8w$_tag_store_one_way (
                                          .A(set_index),
                                          .DIN(tag_in),
                                          .OE(1'b0),
                                          .WR(wr_en_bar_one_hot[i]), 
                                          .DOUT(tag_out[i*TAG_WIDTH +: TAG_WIDTH])
                                        );
  end
endgenerate

endmodule