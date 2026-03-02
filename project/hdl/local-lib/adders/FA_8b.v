module FA_8b (
  input		[7:0]	in0, in1,
  input         cin,
	output	[7:0]	s, cout
);
	
	// Stage 0
	
	wire  [6:-1]	Gi_i;

	wire	[6:-1]   Pi_i;
			
	assign Gi_i[-1] = cin;
	assign Pi_i[-1] = 1'b0;
	
	// gen_prop(gen, prop, in0, in1);
	
	gen_prop	gen_prop_0[6:0](Gi_i[6:0], Pi_i[6:0], in0[6:0], in1[6:0]);
	
	// Stage 1
	
	wire	[3:0]	Gi_im1, Pi_im1;
	
	// gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j)
	
	genvar i;
	generate
		 for (i = 0; i < 4; i = i + 1) begin : STAGE1
			  gen_prop_2 gp1_0(Gi_im1[i], Pi_im1[i], Pi_i[2*i], Pi_i[2*i - 1], Gi_i[2*i], Gi_i[2*i - 1]);
		 end
	endgenerate
	
	// Stage 2

	wire	[1:0]		Gi_im3, Pi_im3, Gi_im3_buf16, Pi_im3_buf16;
	wire	[1:0]		Gi_im2, Pi_im2;
	
  bufferH16$  bufferH16$_Gi_im3_buf16[1:0](Gi_im3_buf16, Gi_im3);
  bufferH16$  bufferH16$_Pi_im3_buf16[1:0](Pi_im3_buf16, Pi_im3);
	
	genvar j;
	generate
		 for (j = 0; j < 2; j = j + 1) begin : STAGE2

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

	wire	[0:0]		Gi_im4, Pi_im4;
	wire	[0:0]		Gi_im5, Pi_im5;
	wire	[0:0]		Gi_im6, Pi_im6;
	wire	[0:0]		Gi_im7, Pi_im7;
	
	genvar k;
	generate
		 for (k = 0; k < 1; k = k + 1) begin : STAGE3

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
	
	// Sums

	xor3LL xor3LL_24(s[7], Gi_im7[0], in0[7], in1[7]);
	xor3LL xor3LL_25(s[6], Gi_im6[0], in0[6], in1[6]);
	xor3LL xor3LL_26(s[5], Gi_im5[0], in0[5], in1[5]);
	xor3LL xor3LL_27(s[4], Gi_im4[0], in0[4], in1[4]);
	
	xor3LL xor3LL_28(s[3], Gi_im3_buf16[0], in0[3], in1[3]);
	xor3LL xor3LL_29(s[2], Gi_im2[0], in0[2], in1[2]);
	xor3LL xor3LL_30(s[1], Gi_im1[0], in0[1], in1[1]);
	xor3LL xor3LL_31(s[0], Gi_i[-1], in0[0], in1[0]);
	
	// Carries
	
	assign cout[0] = Gi_im1[0];
	assign cout[1] = Gi_im2[0];
	assign cout[2] = Gi_im3_buf16[0];
	assign cout[3] = Gi_im4[0];
	assign cout[4] = Gi_im5[0];
	assign cout[5] = Gi_im6[0];
	assign cout[6] = Gi_im7[0];
	
	wire last_bit_xor_out, last_bit_and_out, last_bit_and_out_1;
	xor2$	last_bit_xor(last_bit_xor_out, in0[7], in1[7]);
	and2$ last_bit_and(last_bit_and_out, last_bit_xor_out, Gi_im7[0]);
	and2$ last_bit_and_1(last_bit_and_out_1, in0[7], in1[7]);
	or2$  last_bit_or(cout[7], last_bit_and_out, last_bit_and_out_1);
	
	
endmodule