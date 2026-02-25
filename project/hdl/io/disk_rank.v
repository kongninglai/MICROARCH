module disk_rank #(
  parameter CHIP_BIT_WIDTH=8
) (
  input [3:0]     WR,
	input           rst, OE,
	inout [31:0]    DIO,
  output  [31:0]  DMA_config
);


wire    [31:0]    DATA_OUT;
assign DMA_config = DATA_OUT;

dff32         dma_register( .WE(WR), .CLR({4{rst}}), .D(DIO),
                            .PRE(1'b1), .Q(DATA_OUT), .QBAR());

tristate16L$  DIO_DRIVER_H( .enbar(OE), .in(DATA_OUT[31:16]), 
                            .out(DIO[31:16]));
tristate16L$  DIO_DRIVER_L( .enbar(OE), .in(DATA_OUT[15:0]), 
                            .out(DIO[15:0]));

endmodule