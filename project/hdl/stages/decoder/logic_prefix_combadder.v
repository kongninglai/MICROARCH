`timescale 1ns/1ps
/*
This module computes the number of high bits and represents it with a numerical value. The 
input to the modules is the 4 signals one-hot representing each prefix that is in the currently
being decoded instruction. 

Critical Path: Through inverted signal until OUT0/1/2
Delay: 1.24 ns
0.24 + 0.15 + 0.4 + 0.25 + 0.2 
*/

module logic_prefix_combadder(
    input P0,P1,P2,P3,
	output OUT1,OUT0
);

/* Inverters */
wire P2_bar;
inv1$ inv_0(P2_bar, P2);
wire P1_bar;
inv1$ inv_1(P1_bar, P1);
wire P0_bar;
inv1$ inv_2(P0_bar, P0);

/* Product Expressions */
wire nand_0_0_0_out;
nand2$ nand_0_0_0(nand_0_0_0_out,P2,P0);
wire nand_2_0_0_out;
nand2$ nand_2_0_0(nand_2_0_0_out,P1_bar,P0);

/* Sum Expressions */
assign OUT2 = 1'b0;
nor2$ nand_1_0_0(OUT1,P1_bar,P0_bar);
nand2$ nand_2_0_1(OUT0,nand_0_0_0_out,nand_2_0_0_out);


endmodule

