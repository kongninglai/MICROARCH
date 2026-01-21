module eq_32b (
  input   [31:0]  in0, in1,
  output          eq
);
	
	wire		[31:0]	xnor_out;
	
	// xnor2$(out, in0, in1);
	xnor2$	xnor2$_0[31:0](xnor_out, in0, in1);
	
	/* Product Expressions */
	wire and_0_0_out;
	wire and_0_1_out;
	wire and_0_2_out;
	wire and_0_3_out;
	wire and_0_4_out;
	wire and_0_5_out;
	wire and_0_6_out;
	wire and_0_7_out;
	wire and_0_8_out;
	wire and_0_9_out;
	wire and_0_10_out;
	
	and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
	and4$ and_0_1(and_0_1_out,xnor_out[31],xnor_out[30],xnor_out[29],xnor_out[28]);
	and4$ and_0_2(and_0_2_out,xnor_out[27],xnor_out[26],xnor_out[25],xnor_out[24]);
	and4$ and_0_3(and_0_3_out,xnor_out[23],xnor_out[22],xnor_out[21],xnor_out[20]);
	and4$ and_0_4(and_0_4_out,xnor_out[19],xnor_out[18],xnor_out[17],and_0_5_out);
	and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,and_0_9_out);
	and4$ and_0_6(and_0_6_out,xnor_out[16],xnor_out[15],xnor_out[14],xnor_out[13]);
	and4$ and_0_7(and_0_7_out,xnor_out[12],xnor_out[11],xnor_out[10],xnor_out[9]);
	and4$ and_0_8(and_0_8_out,xnor_out[8],xnor_out[7],xnor_out[6],xnor_out[5]);
	and4$ and_0_9(and_0_9_out,xnor_out[4],xnor_out[3],xnor_out[2],and_0_10_out);
	and2$ and_0_10(and_0_10_out,xnor_out[1],xnor_out[0]);

	/* Sum Expressions */
  assign eq = and_0_0_out;

endmodule