module gt9_8b (
  input   [3:0] in,
  output        gt
);

  /* Product Expressions */
  wire and_0_0_out;
  and2$ and_0_0(and_0_0_out,in[3],in[1]);
  wire and_1_0_out;
  and2$ and_1_0(and_1_0_out,in[3],in[2]);

  /* Sum Expressions */
  or2$ or_0_0(gt,and_0_0_out,and_1_0_out);
endmodule