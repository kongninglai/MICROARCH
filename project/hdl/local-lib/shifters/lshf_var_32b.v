module lshf_var_32b (
  input  [31:0] in,
  input  [4:0]  shf_amt,
  output [31:0] out
);

wire [31:0] lshf_out [31:1];

wire  [4:0] shf_amt_buf64;

bufferH16$    bufferH16$_shf_amt_buf64[4:0](shf_amt_buf64, shf_amt);

genvar i;
generate
  for (i = 1; i < 32; i = i + 1) begin : LSHF_INST
    lshf_const #(
      .WIDTH(32),
      .SHF_AMT(i)
    ) lshf_gen (
      .in(in),
      .out(lshf_out[i])
    );
  end
endgenerate

mux32_16b mux32_0 (
  .in0 (in[15:0]),
  .in1 (lshf_out[1][15:0]),
  .in2 (lshf_out[2][15:0]),
  .in3 (lshf_out[3][15:0]),
  .in4 (lshf_out[4][15:0]),
  .in5 (lshf_out[5][15:0]),
  .in6 (lshf_out[6][15:0]),
  .in7 (lshf_out[7][15:0]),
  .in8 (lshf_out[8][15:0]),
  .in9 (lshf_out[9][15:0]),
  .in10(lshf_out[10][15:0]),
  .in11(lshf_out[11][15:0]),
  .in12(lshf_out[12][15:0]),
  .in13(lshf_out[13][15:0]),
  .in14(lshf_out[14][15:0]),
  .in15(lshf_out[15][15:0]),
  .in16(lshf_out[16][15:0]),
  .in17(lshf_out[17][15:0]),
  .in18(lshf_out[18][15:0]),
  .in19(lshf_out[19][15:0]),
  .in20(lshf_out[20][15:0]),
  .in21(lshf_out[21][15:0]),
  .in22(lshf_out[22][15:0]),
  .in23(lshf_out[23][15:0]),
  .in24(lshf_out[24][15:0]),
  .in25(lshf_out[25][15:0]),
  .in26(lshf_out[26][15:0]),
  .in27(lshf_out[27][15:0]),
  .in28(lshf_out[28][15:0]),
  .in29(lshf_out[29][15:0]),
  .in30(lshf_out[30][15:0]),
  .in31(lshf_out[31][15:0]),
  .s0(shf_amt_buf64[0]),
  .s1(shf_amt_buf64[1]),
  .s2(shf_amt_buf64[2]),
  .s3(shf_amt_buf64[3]),
  .s4(shf_amt_buf64[4]),
  .outb(out[15:0])
);

mux32_16b mux32_1 (
  .in0 (in[31:16]),
  .in1 (lshf_out[1][31:16]),
  .in2 (lshf_out[2][31:16]),
  .in3 (lshf_out[3][31:16]),
  .in4 (lshf_out[4][31:16]),
  .in5 (lshf_out[5][31:16]),
  .in6 (lshf_out[6][31:16]),
  .in7 (lshf_out[7][31:16]),
  .in8 (lshf_out[8][31:16]),
  .in9 (lshf_out[9][31:16]),
  .in10(lshf_out[10][31:16]),
  .in11(lshf_out[11][31:16]),
  .in12(lshf_out[12][31:16]),
  .in13(lshf_out[13][31:16]),
  .in14(lshf_out[14][31:16]),
  .in15(lshf_out[15][31:16]),
  .in16(lshf_out[16][31:16]),
  .in17(lshf_out[17][31:16]),
  .in18(lshf_out[18][31:16]),
  .in19(lshf_out[19][31:16]),
  .in20(lshf_out[20][31:16]),
  .in21(lshf_out[21][31:16]),
  .in22(lshf_out[22][31:16]),
  .in23(lshf_out[23][31:16]),
  .in24(lshf_out[24][31:16]),
  .in25(lshf_out[25][31:16]),
  .in26(lshf_out[26][31:16]),
  .in27(lshf_out[27][31:16]),
  .in28(lshf_out[28][31:16]),
  .in29(lshf_out[29][31:16]),
  .in30(lshf_out[30][31:16]),
  .in31(lshf_out[31][31:16]),
  .s0(shf_amt_buf64[0]),
  .s1(shf_amt_buf64[1]),
  .s2(shf_amt_buf64[2]),
  .s3(shf_amt_buf64[3]),
  .s4(shf_amt_buf64[4]),
  .outb(out[31:16])
);

endmodule
