module cmp_gt_32b (
  input		[31:0]	in0, in1,
	output	 [0:0]	gt
);	

wire AGB3, AGB2, AGB1, AGB0;

wire EQ3, EQ2, EQ1;

wire t6a, t5a, t4a;

wire nAGB3;

/* 8b magnitude comparators */

mag_comp8$ mag_comp8$_3(.A(in0[31:24]), .B(in1[31:24]), .AGB(AGB3), .BGA());
mag_comp8$ mag_comp8$_2(.A(in0[23:16]), .B(in1[23:16]), .AGB(AGB2), .BGA());
mag_comp8$ mag_comp8$_1(.A(in0[15:8]),  .B(in1[15:8]),  .AGB(AGB1), .BGA());
mag_comp8$ mag_comp8$_0(.A(in0[7:0]),   .B(in1[7:0]),   .AGB(AGB0), .BGA());

/* INTERMEDIATE EQUALITY */

big_eq	#(.WIDTH(8)) big_eq_3(.in0(in0[31:24]), .in1(in1[31:24]), .eq(EQ3));
big_eq	#(.WIDTH(8)) big_eq_2(.in0(in0[23:16]), .in1(in1[23:16]), .eq(EQ2));
big_eq	#(.WIDTH(8)) big_eq_1(.in0(in0[15:8]),  .in1(in1[15:8]),  .eq(EQ1));

/* active-low decision terms, reversed polarity into final NAND4s */

nand2$	nand2$_t6a(t6a, EQ3, AGB2);
nand3$	nand3$_t5a(t5a, EQ3, EQ2, AGB1);
nand4$	nand4$_t4a(t4a, EQ3, EQ2, EQ1, AGB0);

/* invert MSB results to preseve polarity into the final NAND4s */

inv1$	inv1$_nAGB3(nAGB3, AGB3);

/* final magnitude results */

nand4$	nand4$_gt(gt, nAGB3, t6a, t5a, t4a);

endmodule