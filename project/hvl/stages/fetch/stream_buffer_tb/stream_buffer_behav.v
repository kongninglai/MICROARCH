module stream_buffer_behav #(
  parameter   RANK_BIT_WIDTH=128,
  parameter   BUS_BIT_WIDTH=32,
  parameter   RANK_BURST_SIZE=4,
  parameter   MEM_ADDR_WIDTH=15
) (
  input                                       clk,
  input                                       rst,
  input   [RANK_BURST_SIZE-1:0]               stream_buffer_wr_mask,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  icache_addr,
  input   [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]  icache_controller_next_line_addr,
  input   [RANK_BIT_WIDTH-1:0]                DATA_BUS_SHF,
  input                                       icache_controller_set_valid,

  output                                      stream_buffer_hit,
  output                                      stream_buffer_miss,
  output  reg [RANK_BIT_WIDTH-1:0]            stream_buffer_data
);

reg stream_buffer_valid;
reg [MEM_ADDR_WIDTH-RANK_BURST_SIZE-1:0] stream_buffer_next_line_addr;

// Pipeline registers to capture inputs arriving just after clk edge
reg [RANK_BURST_SIZE-1:0] wr_mask_d;
reg [RANK_BIT_WIDTH-1:0]  data_bus_d;
reg                        set_valid_d;
reg [MEM_ADDR_WIDTH-RANK_BURST_SIZE-1:0] next_line_addr_d;

integer i;

always @(posedge clk or negedge rst) begin
  if (~rst) begin
    wr_mask_d <= 0;
    data_bus_d <= 0;
    set_valid_d <= 0;
    next_line_addr_d <= 0;
  end else begin
    wr_mask_d <= stream_buffer_wr_mask;
    data_bus_d <= DATA_BUS_SHF;
    set_valid_d <= icache_controller_set_valid;
    next_line_addr_d <= icache_controller_next_line_addr;
  end
end

always @(posedge clk or negedge rst) begin
  if (~rst)
    stream_buffer_data <= {RANK_BIT_WIDTH{1'b0}};
  else begin
    for (i = 0; i < RANK_BURST_SIZE; i = i + 1)
      if (wr_mask_d[i])
        stream_buffer_data[i*BUS_BIT_WIDTH +: BUS_BIT_WIDTH]
          <= data_bus_d[i*BUS_BIT_WIDTH +: BUS_BIT_WIDTH];
  end
end

always @(posedge clk or negedge rst) begin
  if (~rst)
    stream_buffer_valid <= 1'b0;
  else if (set_valid_d)
    stream_buffer_valid <= 1'b1;
end

always @(posedge clk or negedge rst) begin
  if (~rst)
    stream_buffer_next_line_addr <= {(MEM_ADDR_WIDTH-RANK_BURST_SIZE){1'b0}};
  else if (set_valid_d)
    stream_buffer_next_line_addr <= next_line_addr_d;
end

assign stream_buffer_hit  =
  stream_buffer_valid &&
  (stream_buffer_next_line_addr == icache_addr);

assign stream_buffer_miss = ~stream_buffer_hit;

endmodule