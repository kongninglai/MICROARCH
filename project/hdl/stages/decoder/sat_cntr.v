/* AUTO GENERATED NAND-NAND LOGIC */
module sat_cntr(
	input wire CurState1,
	input wire CurState0,
	input wire Incr_or_Decr,
	output wire NextState1,
	output wire NextState0
);

	/* Inverters (Delay: 0.15) */
	wire CurState0_bar;
	inv1$ inv_0(CurState0_bar, CurState0);

	/* Level 1: Product Terms (NAND Gates) */
	wire nand_0_0_out;
	nand2$ nand_0_0(nand_0_0_out,CurState1,CurState0);
	wire nand_1_0_out;
	nand2$ nand_1_0(nand_1_0_out,CurState0,Incr_or_Decr);
	wire nand_2_0_out;
	nand2$ nand_2_0(nand_2_0_out,CurState1,CurState0_bar);
	wire nand_3_0_out;
	nand2$ nand_3_0(nand_3_0_out,CurState0_bar,Incr_or_Decr);
	wire nand_4_0_out;
	nand2$ nand_4_0(nand_4_0_out,CurState1,Incr_or_Decr);

	/* Level 2: Sum Terms (NAND Gates - SOP Equivalence) */
	nand3$ nand_0_0_0(NextState1,nand_0_0_out,nand_1_0_out,nand_4_0_out);
	nand3$ nand_1_0_0(NextState0,nand_2_0_out,nand_3_0_out,nand_4_0_out);

endmodule

