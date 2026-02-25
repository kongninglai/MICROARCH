module disk_rank_behav #(
  parameter CHIP_BIT_WIDTH=8
) (
  input [3:0]     WR,
	input           rst, OE,
	inout [31:0]    DIO,
  output [31:0]  DMA_config
);

  reg [31:0] disk_rank_mem;
  assign DMA_config = disk_rank_mem;

  always @(*) begin
    if ((WR[3] == 1'b0)) begin
      disk_rank_mem[31:24] <= DIO[31:24];
    end
    if ((WR[2] == 1'b0)) begin
      disk_rank_mem[23:16] <= DIO[23:16];
    end
    if ((WR[1] == 1'b0)) begin
      disk_rank_mem[15:8] <= DIO[15:8];
    end
    if ((WR[0] == 1'b0)) begin
      disk_rank_mem[7:0] <= DIO[7:0];
    end
  end

  assign DIO =
  ((WR == 4'hF) && (OE == 1'b0))
    ? {
        disk_rank_mem
      }
    : {32{1'bz}};


endmodule