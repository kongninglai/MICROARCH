module cmp_gen_20b (
  input		[19:0]	in0, in1,
	output	 [0:0]	lt, gt, eq
);	

wire AGB2, AGB1, AGB0;
wire BGA2, BGA1, BGA0;

wire EQ2, EQ1;

wire t5a, t4a;
wire t5b, t4b;

wire nAGB2, nBGA2;

/* magnitude comparators */

mag_comp4$ mag_comp4$_2(.A(in0[19:16]), .B(in1[19:16]), .AGB(AGB2), .BGA(BGA2));
mag_comp8$ mag_comp8$_1(.A(in0[15:8]),  .B(in1[15:8]),  .AGB(AGB1), .BGA(BGA1));
mag_comp8$ mag_comp8$_0(.A(in0[7:0]),   .B(in1[7:0]),   .AGB(AGB0), .BGA(BGA0));

/* INTERMEDIATE EQUALITY */

big_eq	#(.WIDTH(4)) big_eq_2(.in0(in0[19:16]), .in1(in1[19:16]), .eq(EQ2));
big_eq	#(.WIDTH(8)) big_eq_1(.in0(in0[15:8]),  .in1(in1[15:8]),  .eq(EQ1));

/* active-low decision terms, reversed polarity into final NAND3s */

nand2$	nand2$_t5a(t5a, EQ2, AGB1);
nand3$	nand3$_t4a(t4a, EQ2, EQ1, AGB0);

nand2$	nand2$_t5b(t5b, EQ2, BGA1);
nand3$	nand3$_t4b(t4b, EQ2, EQ1, BGA0);

/* invert MSB results to preseve polarity into the final NAND3s */

inv1$	inv1$_nAGB2(nAGB2, AGB2);
inv1$	inv1$_nBGA2(nBGA2, BGA2);

/* final magnitude results */

nand3$	nand3$_gt(gt, nAGB2, t5a, t4a);
nand3$	nand3$_lt(lt, nBGA2, t5b, t4b);

/* OVERALL EQUALITY */

big_eq	#(.WIDTH(20)) big_eq_0(.in0(in0), .in1(in1), .eq(eq));

endmodule