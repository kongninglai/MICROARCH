module iq_de_to_rr_behav #(
  parameter ENTRY_BIT_WIDTH = 317,
  parameter VALID_BIT       = 218,
  parameter NUM_ENTRIES     = 4,
  parameter PTR_WIDTH       = $clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH     = PTR_WIDTH + 1
) (
  input                           clk,
  input                           rst_n,
  input                           wr,
  input                           rd,
  input                           flush,
  input   [ENTRY_BIT_WIDTH-1:0]   data_in,

  output                          empty,
  output                          full,
  output  [COUNT_WIDTH-1:0]       entry_count,
  output  [ENTRY_BIT_WIDTH-1:0]   data_out,
  output                          head_valid
);

  reg [ENTRY_BIT_WIDTH-1:0] mem [0:NUM_ENTRIES-1];
  reg [PTR_WIDTH-1:0]       wr_ptr;
  reg [PTR_WIDTH-1:0]       rd_ptr;
  reg [COUNT_WIDTH-1:0]     count;

  integer idx;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count  <= 0;
      for (idx = 0; idx < NUM_ENTRIES; idx = idx + 1)
        mem[idx] <= 0;
    end else if (flush) begin
      count  <= 0;
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (wr) begin
        mem[wr_ptr] <= data_in;
        wr_ptr      <= (wr_ptr + 1) % NUM_ENTRIES;
      end
      if (rd) begin
        rd_ptr <= (rd_ptr + 1) % NUM_ENTRIES;
      end
      if (wr && !(rd))
        count <= count + 1;
      else if (rd && !(wr))
        count <= count - 1;
    end
  end

  assign entry_count = count;
  assign empty       = (count == 0);
  assign full        = (count == NUM_ENTRIES);
  assign data_out    = mem[rd_ptr];
  assign head_valid  = mem[rd_ptr][VALID_BIT];

endmodule
