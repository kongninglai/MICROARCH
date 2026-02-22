module PA_16b ( 
  input		[15:0]	  in0, in1,
	output	[15:0]	  s
);
	
	// Stage 0
	
	wire  [14:-1]	Gi_i;

	wire	[14:-1]  Pi_i;
			
	assign Gi_i[-1] = 1'b0;
	assign Pi_i[-1] = 1'b0;
	
	// gen_prop(gen, prop, in0, in1);
	
	gen_prop	gen_prop_0[14:0](Gi_i[14:0], Pi_i[14:0], in0[14:0], in1[14:0]);
	
	// Stage 1
	
	wire	[7:0]	Gi_im1, Pi_im1;
	
	// gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j)
	
  assign Pi_im1[0] = 1'b1;
  assign Gi_im1[0] = Gi_i[0];

	genvar i;
	generate
		 for (i = 1; i < 8; i = i + 1) begin : STAGE1
			  gen_prop_2 gp1_0(Gi_im1[i], Pi_im1[i], Pi_i[2*i], Pi_i[2*i - 1], Gi_i[2*i], Gi_i[2*i - 1]);
		 end
	endgenerate
	
	// Stage 2

	wire	[3:0]		Gi_im3, Pi_im3, Gi_im3_buf16, Pi_im3_buf16;
	wire	[3:0]		Gi_im2, Pi_im2;
	
  bufferH16$  bufferH16$_Gi_im3_buf16[3:0](Gi_im3_buf16, Gi_im3);
  bufferH16$  bufferH16$_Pi_im3_buf16[3:0](Pi_im3_buf16, Pi_im3);
	
	genvar j;
	generate
		 for (j = 0; j < 4; j = j + 1) begin : STAGE2

			  // ---- i : i-2  (Gi_im2 / Pi_im2)
			  
			  // j = 0 should be 1:-1

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

	wire	[1:0]		Gi_im4, Pi_im4;
	wire	[1:0]		Gi_im5, Pi_im5;
	wire	[1:0]		Gi_im6, Pi_im6;
	wire	[1:0]		Gi_im7, Pi_im7, Gi_im7_buf16, Pi_im7_buf16;
	
  bufferH16$  bufferH16$_Gi_im7_buf16[1:0](Gi_im7_buf16, Gi_im7);
  bufferH16$  bufferH16$_Pi_im7_buf16[1:0](Pi_im7_buf16, Pi_im7);
	
	genvar k;
	generate
		 for (k = 0; k < 2; k = k + 1) begin : STAGE3

			  // ---- i : i-4
			  
			  // k = 0 should be 3:-1

			  gen_prop_2 gp3_im4 (
					Gi_im4[k],
					Pi_im4[k],
					Pi_i[8*k + 3],
					Pi_im3_buf16[2*k],
					Gi_i[8*k + 3],
					Gi_im3_buf16[2*k]
			  );

			  // ---- i : i-5
			  
			  // k = 0 should be 4:-1

			  gen_prop_2 gp3_im5 (
					Gi_im5[k],
					Pi_im5[k],
					Pi_im1[4*k + 2],
					Pi_im3_buf16[2*k],
					Gi_im1[4*k + 2],
					Gi_im3_buf16[2*k]
			  );

			  // ---- i : i-6
			  
			  // k = 0 should be 5:-1

			  gen_prop_2 gp3_im6 (
					Gi_im6[k],
					Pi_im6[k],
					Pi_im2[2*k + 1],
					Pi_im3_buf16[2*k],
					Gi_im2[2*k + 1],
					Gi_im3_buf16[2*k]
			  );

			  // ---- i : i-7
			  
			  // k = 0 should be 6:-1

			  gen_prop_2 gp3_im7 (
					Gi_im7[k],
					Pi_im7[k],
					Pi_im3_buf16[2*k + 1],
					Pi_im3_buf16[2*k],
					Gi_im3_buf16[2*k + 1],
					Gi_im3_buf16[2*k]
			  );

		 end
	endgenerate
	
	// Stage 4

	wire	[0:0]		Gi_im8, Pi_im8;
	wire	[0:0]		Gi_im9, Pi_im9;
	wire	[0:0]		Gi_im10, Pi_im10;
	wire	[0:0]		Gi_im11, Pi_im11;
	wire	[0:0]		Gi_im12, Pi_im12;
	wire	[0:0]		Gi_im13, Pi_im13;
	wire	[0:0]		Gi_im14, Pi_im14;
	wire	[0:0]		Gi_im15, Pi_im15;
	
	genvar l;
	generate
		 for (l = 0; l < 1; l = l + 1) begin : STAGE4

			  // ---- i : i-8
			  
			  // l = 0 should be 7:-1

			  gen_prop_2 gp4_im8 (
					Gi_im8[l],
					Pi_im8[l],
					Pi_i[16*l + 7],
					Pi_im7_buf16[2*l],
					Gi_i[16*l + 7],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-9
			  
			  // l = 0 should be 8:-1

			  gen_prop_2 gp4_im9 (
					Gi_im9[l],
					Pi_im9[l],
					Pi_im1[8*l + 4],
					Pi_im7_buf16[2*l],
					Gi_im1[8*l + 4],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-10
			  
			  // l = 0 should be 9:-1

			  gen_prop_2 gp4_im10 (
					Gi_im10[l],
					Pi_im10[l],
					Pi_im2[4*l + 2],
					Pi_im7_buf16[2*l],
					Gi_im2[4*l + 2],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-11
			  
			  // l = 0 should be 10:-1

			  gen_prop_2 gp4_im11 (
					Gi_im11[l],
					Pi_im11[l],
					Pi_im3_buf16[4*l + 2],
					Pi_im7_buf16[2*l],
					Gi_im3_buf16[4*l + 2],
					Gi_im7_buf16[2*l]
			  );
			  
			  // ---- i : i-12
			  
			  // l = 0 should be 11:-1

			  gen_prop_2 gp4_im12 (
					Gi_im12[l],
					Pi_im12[l],
					Pi_im4[2*l + 1],
					Pi_im7_buf16[2*l],
					Gi_im4[2*l + 1],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-13
			  
			  // l = 0 should be 12:-1

			  gen_prop_2 gp4_im13 (
					Gi_im13[l],
					Pi_im13[l],
					Pi_im5[2*l + 1],
					Pi_im7_buf16[2*l],
					Gi_im5[2*l + 1],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-14
			  
			  // l = 0 should be 13:-1

			  gen_prop_2 gp4_im14 (
					Gi_im14[l],
					Pi_im14[l],
					Pi_im6[2*l + 1],
					Pi_im7_buf16[2*l],
					Gi_im6[2*l + 1],
					Gi_im7_buf16[2*l]
			  );

			  // ---- i : i-15
			  
			  // l = 0 should be 14:-1

			  gen_prop_2 gp4_im15 (
					Gi_im15[l],
					Pi_im15[l],
					Pi_im7_buf16[2*l + 1],
					Pi_im7_buf16[2*l],
					Gi_im7_buf16[2*l + 1],
					Gi_im7_buf16[2*l]
			  );

		 end
	endgenerate
	
	// Sums
	xor3LL xor3LL_16(s[15], Gi_im15[0], in0[15], in1[15]);
	xor3LL xor3LL_17(s[14], Gi_im14[0], in0[14], in1[14]);
	xor3LL xor3LL_18(s[13], Gi_im13[0], in0[13], in1[13]);
	xor3LL xor3LL_19(s[12], Gi_im12[0], in0[12], in1[12]);
	xor3LL xor3LL_20(s[11], Gi_im11[0], in0[11], in1[11]);
	xor3LL xor3LL_21(s[10], Gi_im10[0], in0[10], in1[10]);
	xor3LL xor3LL_22(s[9], Gi_im9[0], in0[9], in1[9]);
	xor3LL xor3LL_23(s[8], Gi_im8[0], in0[8], in1[8]);

	xor3LL xor3LL_24(s[7], Gi_im7_buf16[0], in0[7], in1[7]);
	xor3LL xor3LL_25(s[6], Gi_im6[0], in0[6], in1[6]);
	xor3LL xor3LL_26(s[5], Gi_im5[0], in0[5], in1[5]);
	xor3LL xor3LL_27(s[4], Gi_im4[0], in0[4], in1[4]);
	
	xor3LL xor3LL_28(s[3], Gi_im3_buf16[0], in0[3], in1[3]);
	xor3LL xor3LL_29(s[2], Gi_im2[0], in0[2], in1[2]);
	xor3LL xor3LL_30(s[1], Gi_im1[0], in0[1], in1[1]);
	xor3LL xor3LL_31(s[0], Gi_i[-1], in0[0], in1[0]);
	
endmodule