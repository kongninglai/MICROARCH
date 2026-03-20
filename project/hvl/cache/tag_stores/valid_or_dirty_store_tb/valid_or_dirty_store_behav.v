module valid_or_dirty_store_behav #(
  parameter NUM_SETS    = 8,
  parameter INDEX_WIDTH = $clog2(NUM_SETS),
  parameter NUM_WAYS    = 4,
  parameter WAY_WIDTH   = $clog2(NUM_WAYS)
) (
  input                                 clk, rst,
  input   [INDEX_WIDTH-1:0]             set_index,
  input                                 set_or_clr,
  input   [INDEX_WIDTH+WAY_WIDTH-1:0]   wr_en,
  input                                 wr_en_global,
  output  [NUM_WAYS-1:0]                out
);

reg [NUM_WAYS-1:0] store [0:NUM_SETS-1];

wire [INDEX_WIDTH-1:0] wr_set;
wire [WAY_WIDTH-1:0]   wr_way;

assign wr_set  = wr_en[INDEX_WIDTH+WAY_WIDTH-1:WAY_WIDTH];
assign wr_way  = wr_en[WAY_WIDTH-1:0];

integer i;

always @(posedge clk or negedge rst) begin
  if (!rst) begin
    for (i = 0; i < NUM_SETS; i = i + 1)
      store[i] <= {NUM_WAYS{1'b0}};
  end else if (wr_en_global) begin
    store[wr_set][wr_way] <= set_or_clr;
  end
end

assign out = store[set_index];

endmodule