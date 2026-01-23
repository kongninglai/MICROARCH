module gt99_8b (
  input   [7:0] in,
  output        gt
);

  /* Product Expressions */
  wire and_0_0_out;
  and4$ and_0_0(and_0_0_out,in[7],in[4],in[3],in[1]);
  wire and_1_0_out;
  and4$ and_1_0(and_1_0_out,in[7],in[4],in[3],in[2]);
  wire and_2_0_out;
  and2$ and_2_0(and_2_0_out,in[7],in[5]);
  wire and_3_0_out;
  and2$ and_3_0(and_3_0_out,in[7],in[6]);

  /* Sum Expressions */
  or4$ or_0_0(gt,and_0_0_out,and_1_0_out,and_2_0_out,and_3_0_out);
		  
endmodule