module HA_4b (
  input		[3:0]	in0, in1,
	output	[3:0]	s,
  output        cout
);
	
	// Stage 0
	
	wire  [3:-1]	Gi_i;

	wire	[3:-1]   Pi_i;
			
	assign Gi_i[-1] = 1'b0;
	assign Pi_i[-1] = 1'b0;
	
	// gen_prop(gen, prop, in0, in1);
	
	gen_prop	gen_prop_0[3:0](Gi_i[3:0], Pi_i[3:0], in0[3:0], in1[3:0]);
	
	// Stage 1
	
	wire	[1:0]	Gi_im1, Pi_im1;
	
	// gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j)

  assign Pi_im1[0] = 1'b0;
  assign Gi_im1[0] = Gi_i[0];
	
	genvar i;
	generate
		 for (i = 1; i < 2; i = i + 1) begin : STAGE1
			  gen_prop_2 gp1_0(Gi_im1[i], Pi_im1[i], Pi_i[2*i], Pi_i[2*i - 1], Gi_i[2*i], Gi_i[2*i - 1]);
		 end
	endgenerate
	
	// Stage 2

	wire	[0:0]		Gi_im3, Pi_im3, Gi_im3_buf16, Pi_im3_buf16;
	wire	[0:0]		Gi_im2, Pi_im2;
	
	genvar j;
	generate
		 for (j = 0; j < 1; j = j + 1) begin : STAGE2

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
		 end
	endgenerate
	
	// Sums

  // Optimize s[3] for instruction length
	wire s3_t0, s3_t1, s3_t2, s3_c3, Gi_i_bar;
  inv1$   inv1$_Gi_i_bar(Gi_i_bar, Gi_i[2]);
	nand2$  nand2$_s3_t0(s3_t0, Pi_i[2], Gi_i[1]);
	nand3$  nand3$_s3_t1(s3_t1, Pi_i[2], Pi_i[1], Gi_i[0]);
	nand3$  nand3$_s3_c3 (s3_c3, Gi_i_bar, s3_t0, s3_t1);
	xor3LL xor3LL_28(s[3], s3_c3, in0[3], in1[3]);

	xor3LL xor3LL_29(s[2], Gi_im2[0], in0[2], in1[2]);
	xor3LL xor3LL_30(s[1], Gi_im1[0], in0[1], in1[1]);
	xor3LL xor3LL_31(s[0], Gi_i[-1], in0[0], in1[0]);	

  wire c3_t0, c3_t1, c3_t2;
  wire s3_t0_bar, s3_t1_bar;
  inv1$  inv1$_s3_t0_bar(s3_t0_bar, s3_t0);
  inv1$  inv1$_s3_t1_bar(s3_t1_bar, s3_t1);
  nand2$ nand2$_c3_t0(c3_t0, Pi_i[3], Gi_i[2]);
  nand2$ nand3$_c3_t1(c3_t1, Pi_i[3], s3_t0_bar);
  nand2$ nand3$_c3_t2(c3_t2, Pi_i[3], s3_t1_bar);

  wire Gi_i_3_bar;
  inv1$   inv1$_Gi_i_3_bar(Gi_i_3_bar, Gi_i[3]);  
  nand4$  nand4$_cout (cout, Gi_i_3_bar, c3_t0, c3_t1, c3_t2);
	
endmodule