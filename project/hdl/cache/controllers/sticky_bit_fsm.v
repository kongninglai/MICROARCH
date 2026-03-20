module sticky_bit_fsm (
  input rst, clk, IO_READ_AND_NOT_FLUSH, FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ, FILL_BUSY,
  output STICKY
);

wire Q0;
wire D0;

/* Inverters */
wire FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ_bar;
inv1$ inv_0(FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ_bar, FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ);
wire FILL_BUSY_bar;
inv1$ inv_1(FILL_BUSY_bar, FILL_BUSY);
wire Q0_bar;

/* Product Expressions */
wire nand_0_0_0_out;
nand2$ nand_0_0_0(nand_0_0_0_out,Q0_bar,IO_READ_AND_NOT_FLUSH);
wire nand_1_0_0_out;
nand2$ nand_1_0_0(nand_1_0_0_out,Q0,FILL_BUSY_bar);
wire nand_2_0_0_out;
nand2$ nand_2_0_0(nand_2_0_0_out,Q0,FLUSH_OR_NOT_FILL_BUSY_OR_NOT_IO_READ_bar);

/* Sum Expressions */
nand2$ nand_0_0_1(D0,nand_0_0_0_out,nand_2_0_0_out);
inv1$ nand_1_0_1(STICKY, nand_1_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, D0, Q0, Q0_bar, rst, 1'b1);

endmodule