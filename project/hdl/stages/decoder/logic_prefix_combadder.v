`timescale 1ns/1ps
/*
This module computes the number of high bits and represents it with a numerical value. The 
input to the modules is the 4 signals one-hot representing each prefix that is in the currently
being decoded instruction. 

Critical Path: Through inverted signal until OUT0/1/2
Delay: 1 ns
0.15 + 0.4 + 0.25 + 0.2 
*/

module logic_prefix_combadder(
    input P0,P1,P2,P3,
	output OUT2,OUT1,OUT0
);

	//Layer 1: 0.15ns
	wire P0_bar;
	inv1$ inv_0(P0_bar, P0);
	wire P1_bar;
	inv1$ inv_1(P1_bar, P1);
	wire P2_bar;
	inv1$ inv_2(P2_bar, P2);
	wire P3_bar;
	inv1$ inv_3(P3_bar, P3);

	// Layer 2: 0.4ns 
	wire and_0_0_out;
	and4$ and_0_0(and_0_0_out, P0_bar, P1_bar, P2_bar, P3_bar);
	wire and_1_0_out;
	and4$ and_1_0(and_1_0_out,P0_bar, P1_bar, P2_bar, P3);
	wire and_2_0_out;
	and4$ and_2_0(and_2_0_out, P0_bar, P1_bar, P2, P3_bar);
	wire and_3_0_out;
	and4$ and_3_0(and_3_0_out, P0_bar, P1_bar, P2, P3);
	wire and_4_0_out;
	and4$ and_4_0(and_4_0_out, P0_bar, P1, P2_bar, P3_bar);
	wire and_5_0_out;
	and4$ and_5_0(and_5_0_out, P0_bar, P1, P2_bar, P3);
	wire and_6_0_out;
	and4$ and_6_0(and_6_0_out, P0_bar, P1, P2, P3_bar);
	wire and_7_0_out;
	and4$ and_7_0(and_7_0_out, P0_bar, P1, P2, P3);
	wire and_8_0_out;
	and4$ and_8_0(and_8_0_out, P0, P1_bar, P2_bar, P3_bar);
	wire and_9_0_out;
	and4$ and_9_0(and_9_0_out, P0, P1_bar, P2_bar, P3);
	wire and_10_0_out;
	and4$ and_10_0(and_10_0_out, P0, P1_bar, P2, P3_bar);
	wire and_11_0_out;
	and4$ and_11_0(and_11_0_out, P0, P1_bar, P2, P3);
	wire and_12_0_out;
	and4$ and_12_0(and_12_0_out, P0, P1, P2_bar, P3_bar);
	wire and_13_0_out;
	and4$ and_13_0(and_13_0_out, P0, P1, P2_bar, P3);
	wire and_14_0_out;
	and4$ and_14_0(and_14_0_out, P0, P1, P2, P3_bar);
	wire and_15_0_out;
	and4$ and_15_0(and_15_0_out, P0, P1, P2, P3);


	// Layer 3: 0.25ns
	wire nor_btwn_odd_w0, nor_btwn_odd_w1, nor_btwn_odd_w2, nor_btwn_odd_w3;
	nor3$ nor_between_odd0(nor_btwn_odd_w0, and_3_0_out, and_5_0_out, and_6_0_out);
	nor3$ nor_between_odd1(nor_btwn_odd_w1, and_7_0_out, and_9_0_out, and_10_0_out);
	nor3$ nor_between_odd2(nor_btwn_odd_w2, and_11_0_out, and_12_0_out, and_13_0_out);
	inv1$ not_between_odd3(nor_btwn_odd_w3, and_14_0_out);

	wire nor_btwn_even_w0, nor_btwn_even_w1, nor_btwn_even_w2;
	nor3$ nor_between_even0(nor_btwn_even_w0, and_1_0_out, and_2_0_out, and_4_0_out);
	nor3$ nor_between_even1(nor_btwn_even_w1, and_7_0_out, and_8_0_out, and_11_0_out);
	nor2$ nor_between_even2(nor_btwn_even_w2, and_13_0_out, and_14_0_out);
	
	//Level 3: 0.2ns
	assign OUT2 = and_15_0_out;
	nand4$ nand_final_odd(OUT1, nor_btwn_odd_w0, nor_btwn_odd_w1, nor_btwn_odd_w2, nor_btwn_odd_w3);
	nand3$ nand_final_even(OUT0, nor_btwn_even_w0, nor_btwn_even_w1, nor_btwn_even_w2);


endmodule

