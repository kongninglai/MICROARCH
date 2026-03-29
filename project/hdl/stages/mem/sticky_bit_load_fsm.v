/* AUTO GENERATED MOORE LOGIC */
module sticky_bit_load_fsm (
  input rst, clk, LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR, FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR,
  output DOING_LINE_1_LOAD
);

wire DOING_LINE_1_LOAD_prebuf;
bufferH16$  bufferH16$_DOING_LINE_1_LOAD(DOING_LINE_1_LOAD, DOING_LINE_1_LOAD_prebuf);

wire DOING_LINE_1_LOAD_NEXT;

/* Inverters */
wire FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR_bar;
inv1$ inv_0(FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR_bar, FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR);
wire DOING_LINE_1_LOAD_bar;

/* Product Expressions */
wire nand_0_0_0_out;
nand2$ nand_0_0_0(nand_0_0_0_out,DOING_LINE_1_LOAD,FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR_bar);
wire nand_1_0_0_out;
nand2$ nand_1_0_0(nand_1_0_0_out,DOING_LINE_1_LOAD_bar,LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR);

/* Sum Expressions */
nand2$ nand_0_0_1(DOING_LINE_1_LOAD_NEXT,nand_0_0_0_out,nand_1_0_0_out);

/* State Flip Flops */
dff$ dff_0(clk, DOING_LINE_1_LOAD_NEXT, DOING_LINE_1_LOAD_prebuf, DOING_LINE_1_LOAD_bar, rst, 1'b1);

endmodule