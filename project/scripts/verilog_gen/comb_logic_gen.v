/* AUTO GENERATED NAND-NAND LOGIC */
module comb_logic_gen(P0,P1,P2,P3,OUT2,OUT1,OUT0);

	/* I/Os */
	input P0,P1,P2,P3;
	output OUT2,OUT1,OUT0;

	/* Inverters (Delay: 0.15) */
	wire P0_bar;
	inv1$ inv_0(P0_bar, P0);
	wire P1_bar;
	inv1$ inv_1(P1_bar, P1);
	wire P2_bar;
	inv1$ inv_2(P2_bar, P2);
	wire P3_bar;
	inv1$ inv_3(P3_bar, P3);

	/* Level 1: Product Terms (NAND Gates) */
	wire nand_0_0_out;
	nand4$ nand_0_0(nand_0_0_out,P0_bar,P1_bar,P2_bar,P3);
	wire nand_1_0_out;
	nand4$ nand_1_0(nand_1_0_out,P0_bar,P1_bar,P2,P3_bar);
	wire nand_2_0_out;
	nand4$ nand_2_0(nand_2_0_out,P0,P1,P2,P3);
	wire nand_3_0_out;
	nand4$ nand_3_0(nand_3_0_out,P0_bar,P1,P2_bar,P3_bar);
	wire nand_4_0_out;
	nand4$ nand_4_0(nand_4_0_out,P0,P1_bar,P2_bar,P3_bar);
	wire nand_5_0_out;
	nand4$ nand_5_0(nand_5_0_out,P0,P1_bar,P2,P3);
	wire nand_6_0_out;
	nand4$ nand_6_0(nand_6_0_out,P0,P1,P2_bar,P3);
	wire nand_7_0_out;
	nand4$ nand_7_0(nand_7_0_out,P0,P1,P2,P3_bar);
	wire nand_8_0_out;
	nand3$ nand_8_0(nand_8_0_out,P1_bar,P2,P3);
	wire nand_9_0_out;
	nand4$ nand_9_0(nand_9_0_out,P0_bar,P1,P2,P3);
	wire nand_10_0_out;
	nand3$ nand_10_0(nand_10_0_out,P1,P2_bar,P3);
	wire nand_11_0_out;
	nand3$ nand_11_0(nand_11_0_out,P0,P2_bar,P3);
	wire nand_12_0_out;
	nand3$ nand_12_0(nand_12_0_out,P1,P2,P3_bar);
	wire nand_13_0_out;
	nand3$ nand_13_0(nand_13_0_out,P0,P2,P3_bar);
	wire nand_14_0_out;
	nand3$ nand_14_0(nand_14_0_out,P0,P1,P3_bar);

	/* Level 2: Sum Terms (NAND Gates - SOP Equivalence) */
	buffer$ buffer_nand_0_0(OUT2,nand_2_0_out);
	wire nand_1_1_out;
	nand4$ nand_1_0(OUT1,nand_1_1_out,nand_8_0_out,nand_9_0_out,nand_10_0_out);
	nand4$ nand_1_1(nand_1_1_out,OUT1,nand_12_0_out,nand_13_0_out,nand_14_0_out);
	wire nand_2_1_out;
	wire nand_2_2_out;
	nand4$ nand_2_0(OUT0,nand_2_1_out,nand_2_2_out,nand_0_0_out,nand_1_0_out);
	nand4$ nand_2_1(nand_2_1_out,OUT0,nand_4_0_out,nand_5_0_out,nand_6_0_out);
	nand2$ nand_2_2(nand_2_2_out,OUT0,nand_9_0_out);

endmodule
