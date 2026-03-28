/* AUTO GENERATED COMBINATIONAL LOGIC */
module comb_logic_gen(P2,P1,P0,OUT1,OUT0);

	/* I/Os */
	input P2,P1,P0;
	output OUT1,OUT0;

	/* Inverters */
	wire P1_bar;
	inv1$ inv_0(P1_bar, P1);

	/* Product Expressions */
	wire and_0_0_out;
	and2$ and_0_0(and_0_0_out,P1_bar,P0);
	wire and_1_0_out;
	buffer$ buffer_and_1_0(and_1_0_out,P1);
	wire and_2_0_out;
	buffer$ buffer_and_2_0(and_2_0_out,P2);

	/* Sum Expressions */
	or2$ or_0_0(OUT1,and_1_0_out,and_2_0_out);
	or2$ or_1_0(OUT0,and_0_0_out,and_2_0_out);

endmodule
