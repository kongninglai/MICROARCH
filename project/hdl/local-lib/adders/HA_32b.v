module HA_32b (
  input		[31:0]	  in0, in1,
	output	[31:0]	  s, cout
);
	
	// Stage 0
	
	wire  [30:-1]	Gi_i;

	wire	[30:-1]  Pi_i;
			
	assign Gi_i[-1] = 1'b0;
	assign Pi_i[-1] = 1'b0;
	
	// gen_prop(gen, prop, in0, in1);
	
	gen_prop	gen_prop_0[30:0](Gi_i[30:0], Pi_i[30:0], in0[30:0], in1[30:0]);
	
	// Stage 1
	
	wire	[15:0]	Gi_im1, Pi_im1;
	
	// gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j)
	
	genvar i;
	generate
		 for (i = 0; i < 16; i = i + 1) begin : STAGE1
			  gen_prop_2 gp1_0(Gi_im1[i], Pi_im1[i], Pi_i[2*i], Pi_i[2*i - 1], Gi_i[2*i], Gi_i[2*i - 1]);
		 end
	endgenerate
	
	// Stage 2

	wire	[7:0]		Gi_im3, Pi_im3;
	wire	[7:0]		Gi_im2, Pi_im2;
	
	genvar j;
	generate
		 for (j = 0; j < 8; j = j + 1) begin : STAGE2

			  // ---- i : i-2  (Gi_im2 / Pi_im2)
			  
			  // j = 0 should be 1:-1
			  // j = 7 should be 29:27

			  gen_prop_2 gp2_im2 (
					Gi_im2[j],
					Pi_im2[j],
					Pi_i[4*j + 1],
					Pi_im1[2*j],
					Gi_i[4*j + 1],
					Gi_im1[2*j]
			  );

			  // ---- i : i-3  (Gi_im3 / Pi_im3)
			  
			  // j = 0 should be 2:-1
			  // j = 7 should be 30:27

			  gen_prop_2 gp2_im3 (
					Gi_im3[j],
					Pi_im3[j],
					Pi_im1[2*j + 1],
					Pi_im1[2*j],
					Gi_im1[2*j + 1],
					Gi_im1[2*j]
			  );

		 end
	endgenerate
	
	// Stage 3

	wire	[3:0]		Gi_im4, Pi_im4;
	wire	[3:0]		Gi_im5, Pi_im5;
	wire	[3:0]		Gi_im6, Pi_im6;
	wire	[3:0]		Gi_im7, Pi_im7;
	
	genvar k;
	generate
		 for (k = 0; k < 4; k = k + 1) begin : STAGE3

			  // ---- i : i-4
			  
			  // k = 0 should be 3:-1
			  // k = 3 should be 27:23

			  gen_prop_2 gp3_im4 (
					Gi_im4[k],
					Pi_im4[k],
					Pi_i[8*k + 3],
					Pi_im3[2*k],
					Gi_i[8*k + 3],
					Gi_im3[2*k]
			  );

			  // ---- i : i-5
			  
			  // k = 0 should be 4:-1
			  // k = 3 should be 28:23

			  gen_prop_2 gp3_im5 (
					Gi_im5[k],
					Pi_im5[k],
					Pi_im1[4*k + 2],
					Pi_im3[2*k],
					Gi_im1[4*k + 2],
					Gi_im3[2*k]
			  );

			  // ---- i : i-6
			  
			  // k = 0 should be 5:-1
			  // k = 3 should be 29:23

			  gen_prop_2 gp3_im6 (
					Gi_im6[k],
					Pi_im6[k],
					Pi_im2[2*k + 1],
					Pi_im3[2*k],
					Gi_im2[2*k + 1],
					Gi_im3[2*k]
			  );

			  // ---- i : i-7
			  
			  // k = 0 should be 6:-1
			  // k = 3 should be 30:23

			  gen_prop_2 gp3_im7 (
					Gi_im7[k],
					Pi_im7[k],
					Pi_im3[2*k + 1],
					Pi_im3[2*k],
					Gi_im3[2*k + 1],
					Gi_im3[2*k]
			  );

		 end
	endgenerate
	
	// Stage 4

	wire	[1:0]		Gi_im8, Pi_im8;
	wire	[1:0]		Gi_im9, Pi_im9;
	wire	[1:0]		Gi_im10, Pi_im10;
	wire	[1:0]		Gi_im11, Pi_im11;
	wire	[1:0]		Gi_im12, Pi_im12;
	wire	[1:0]		Gi_im13, Pi_im13;
	wire	[1:0]		Gi_im14, Pi_im14;
	wire	[1:0]		Gi_im15, Pi_im15;
	
	genvar l;
	generate
		 for (l = 0; l < 2; l = l + 1) begin : STAGE4

			  // ---- i : i-8
			  
			  // l = 0 should be 7:-1
			  // l = 1 should be 23:15

			  gen_prop_2 gp4_im8 (
					Gi_im8[l],
					Pi_im8[l],
					Pi_i[16*l + 7],
					Pi_im7[2*l],
					Gi_i[16*l + 7],
					Gi_im7[2*l]
			  );

			  // ---- i : i-9
			  
			  // l = 0 should be 8:-1
			  // l = 1 should be 24:15

			  gen_prop_2 gp4_im9 (
					Gi_im9[l],
					Pi_im9[l],
					Pi_im1[8*l + 4],
					Pi_im7[2*l],
					Gi_im1[8*l + 4],
					Gi_im7[2*l]
			  );

			  // ---- i : i-10
			  
			  // l = 0 should be 9:-1
			  // l = 1 should be 25:15

			  gen_prop_2 gp4_im10 (
					Gi_im10[l],
					Pi_im10[l],
					Pi_im2[4*l + 2],
					Pi_im7[2*l],
					Gi_im2[4*l + 2],
					Gi_im7[2*l]
			  );

			  // ---- i : i-11
			  
			  // l = 0 should be 10:-1
			  // l = 1 should be 26:15

			  gen_prop_2 gp4_im11 (
					Gi_im11[l],
					Pi_im11[l],
					Pi_im3[4*l + 2],
					Pi_im7[2*l],
					Gi_im3[4*l + 2],
					Gi_im7[2*l]
			  );
			  
			  // ---- i : i-12
			  
			  // l = 0 should be 11:-1
			  // l = 1 should be 27:15

			  gen_prop_2 gp4_im12 (
					Gi_im12[l],
					Pi_im12[l],
					Pi_im4[2*l + 1],
					Pi_im7[2*l],
					Gi_im4[2*l + 1],
					Gi_im7[2*l]
			  );

			  // ---- i : i-13
			  
			  // l = 0 should be 12:-1
			  // l = 1 should be 28:15

			  gen_prop_2 gp4_im13 (
					Gi_im13[l],
					Pi_im13[l],
					Pi_im5[2*l + 1],
					Pi_im7[2*l],
					Gi_im5[2*l + 1],
					Gi_im7[2*l]
			  );

			  // ---- i : i-14
			  
			  // l = 0 should be 13:-1
			  // l = 1 should be 29:15

			  gen_prop_2 gp4_im14 (
					Gi_im14[l],
					Pi_im14[l],
					Pi_im6[2*l + 1],
					Pi_im7[2*l],
					Gi_im6[2*l + 1],
					Gi_im7[2*l]
			  );

			  // ---- i : i-15
			  
			  // l = 0 should be 14:-1
			  // l = 1 should be 30:15

			  gen_prop_2 gp4_im15 (
					Gi_im15[l],
					Pi_im15[l],
					Pi_im7[2*l + 1],
					Pi_im7[2*l],
					Gi_im7[2*l + 1],
					Gi_im7[2*l]
			  );

		 end
	endgenerate
	
	// Stage 5

	wire	G15_m1, G16_m1, G17_m1, G18_m1, G19_m1, G20_m1, G21_m1, G22_m1,
			G23_m1, G24_m1, G25_m1, G26_m1, G27_m1, G28_m1, G29_m1, G30_m1;
	wire	P15_m1, P16_m1, P17_m1, P18_m1, P19_m1, P20_m1, P21_m1, P22_m1,
			P23_m1, P24_m1, P25_m1, P26_m1, P27_m1, P28_m1, P29_m1, P30_m1;
			
	gen_prop_2 gp4_im16(G15_m1, P15_m1, Pi_i[15],   Pi_im15[0], Gi_i[15]  , Gi_im15[0]);
	gen_prop_2 gp4_im17(G16_m1, P16_m1, Pi_im1[8],  Pi_im15[0], Gi_im1[8] , Gi_im15[0]);
	gen_prop_2 gp4_im18(G17_m1, P17_m1, Pi_im2[4],  Pi_im15[0], Gi_im2[4] , Gi_im15[0]);
	gen_prop_2 gp4_im19(G18_m1, P18_m1, Pi_im3[4],  Pi_im15[0], Gi_im3[4] , Gi_im15[0]);
	gen_prop_2 gp4_im20(G19_m1, P19_m1, Pi_im4[2],  Pi_im15[0], Gi_im4[2] , Gi_im15[0]);
	gen_prop_2 gp4_im21(G20_m1, P20_m1, Pi_im5[2],  Pi_im15[0], Gi_im5[2] , Gi_im15[0]);
	gen_prop_2 gp4_im22(G21_m1, P21_m1, Pi_im6[2],  Pi_im15[0], Gi_im6[2] , Gi_im15[0]);
	gen_prop_2 gp4_im23(G22_m1, P22_m1, Pi_im7[2],  Pi_im15[0], Gi_im7[2] , Gi_im15[0]);
	gen_prop_2 gp4_im24(G23_m1, P23_m1, Pi_im8[1],  Pi_im15[0], Gi_im8[1] , Gi_im15[0]);
	gen_prop_2 gp4_im25(G24_m1, P24_m1, Pi_im9[1],  Pi_im15[0], Gi_im9[1] , Gi_im15[0]);
	gen_prop_2 gp4_im26(G25_m1, P25_m1, Pi_im10[1], Pi_im15[0], Gi_im10[1], Gi_im15[0]);
	gen_prop_2 gp4_im27(G26_m1, P26_m1, Pi_im11[1], Pi_im15[0], Gi_im11[1], Gi_im15[0]);
	gen_prop_2 gp4_im28(G27_m1, P27_m1, Pi_im12[1], Pi_im15[0], Gi_im12[1], Gi_im15[0]);
	gen_prop_2 gp4_im29(G28_m1, P28_m1, Pi_im13[1], Pi_im15[0], Gi_im13[1], Gi_im15[0]);
	gen_prop_2 gp4_im30(G29_m1, P29_m1, Pi_im14[1], Pi_im15[0], Gi_im14[1], Gi_im15[0]);
	gen_prop_2 gp4_im31(G30_m1, P30_m1, Pi_im15[1], Pi_im15[0], Gi_im15[1], Gi_im15[0]);
	
	// Sums
	
	xor3LL xor3LL_0(s[31], G30_m1, in0[31], in1[31]);
	xor3LL xor3LL_1(s[30], G29_m1, in0[30], in1[30]);
	xor3LL xor3LL_2(s[29], G28_m1, in0[29], in1[29]);
	xor3LL xor3LL_3(s[28], G27_m1, in0[28], in1[28]);
	xor3LL xor3LL_4(s[27], G26_m1, in0[27], in1[27]);
	xor3LL xor3LL_5(s[26], G25_m1, in0[26], in1[26]);
	xor3LL xor3LL_6(s[25], G24_m1, in0[25], in1[25]);
	xor3LL xor3LL_7(s[24], G23_m1, in0[24], in1[24]);
	xor3LL xor3LL_8(s[23], G22_m1, in0[23], in1[23]);
	xor3LL xor3LL_9(s[22], G21_m1, in0[22], in1[22]);
	xor3LL xor3LL_10(s[21], G20_m1, in0[21], in1[21]);
	xor3LL xor3LL_11(s[20], G19_m1, in0[20], in1[20]);
	xor3LL xor3LL_12(s[19], G18_m1, in0[19], in1[19]);
	xor3LL xor3LL_13(s[18], G17_m1, in0[18], in1[18]);
	xor3LL xor3LL_14(s[17], G16_m1, in0[17], in1[17]);
	xor3LL xor3LL_15(s[16], G15_m1, in0[16], in1[16]);
	xor3LL xor3LL_16(s[15], Gi_im15[0], in0[15], in1[15]);
	xor3LL xor3LL_17(s[14], Gi_im14[0], in0[14], in1[14]);
	xor3LL xor3LL_18(s[13], Gi_im13[0], in0[13], in1[13]);
	xor3LL xor3LL_19(s[12], Gi_im12[0], in0[12], in1[12]);
	xor3LL xor3LL_20(s[11], Gi_im11[0], in0[11], in1[11]);
	xor3LL xor3LL_21(s[10], Gi_im10[0], in0[10], in1[10]);
	xor3LL xor3LL_22(s[9], Gi_im9[0], in0[9], in1[9]);
	xor3LL xor3LL_23(s[8], Gi_im8[0], in0[8], in1[8]);

	xor3LL xor3LL_24(s[7], Gi_im7[0], in0[7], in1[7]);
	xor3LL xor3LL_25(s[6], Gi_im6[0], in0[6], in1[6]);
	xor3LL xor3LL_26(s[5], Gi_im5[0], in0[5], in1[5]);
	xor3LL xor3LL_27(s[4], Gi_im4[0], in0[4], in1[4]);
	
	xor3LL xor3LL_28(s[3], Gi_im3[0], in0[3], in1[3]);
	xor3LL xor3LL_29(s[2], Gi_im2[0], in0[2], in1[2]);
	xor3LL xor3LL_30(s[1], Gi_im1[0], in0[1], in1[1]);
	xor3LL xor3LL_31(s[0], Gi_i[-1], in0[0], in1[0]);
	
	assign cout[0]  =  Gi_im1[0];
	assign cout[1]  =  Gi_im2[0];
	assign cout[2]  =  Gi_im3[0];
	assign cout[3]  =  Gi_im4[0];
	assign cout[4]  =  Gi_im5[0];
	assign cout[5]  =  Gi_im6[0];
	assign cout[6]  =  Gi_im7[0];
	assign cout[7]  =  Gi_im8[0];

	assign cout[8]  =   Gi_im9[0];
	assign cout[9]  =   Gi_im10[0];
	assign cout[10] =   Gi_im11[0];
	assign cout[11] =   Gi_im12[0];
	assign cout[12] =   Gi_im13[0];
	assign cout[13] =   Gi_im14[0];
	assign cout[14] =   Gi_im15[0];

	assign cout[15] = G15_m1;
	assign cout[16] = G16_m1;
	assign cout[17] = G17_m1;
	assign cout[18] = G18_m1;
	assign cout[19] = G19_m1;
	assign cout[20] = G20_m1;
	assign cout[21] = G21_m1;
	assign cout[22] = G22_m1;
	assign cout[23] = G23_m1;

	assign cout[24] = G24_m1;
	assign cout[25] = G25_m1;
	assign cout[26] = G26_m1;
	assign cout[27] = G27_m1;
	assign cout[28] = G28_m1;
	assign cout[29] = G29_m1;
	assign cout[30] = G30_m1;

	wire last_bit_xor_out, last_bit_and_out, last_bit_and_out_1;
	xor2$	last_bit_xor(last_bit_xor_out, in0[31], in1[31]);
	and2$ last_bit_and(last_bit_and_out, last_bit_xor_out, G30_m1);
	and2$ last_bit_and_1(last_bit_and_out_1, in0[31], in1[31]);
	or2$  last_bit_or(cout[31], last_bit_and_out, last_bit_and_out_1);
	
endmodule