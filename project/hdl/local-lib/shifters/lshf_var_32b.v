module lshf_var_32b (
  input  [31:0] in,
  input  [4:0]  shf_amt,
  output [31:0] out
);

wire [31:0] lshf_out [31:1];

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

mux32 mux32_0[31:0] (
  .in0 (in),
  .in1 (lshf_out[1]),
  .in2 (lshf_out[2]),
  .in3 (lshf_out[3]),
  .in4 (lshf_out[4]),
  .in5 (lshf_out[5]),
  .in6 (lshf_out[6]),
  .in7 (lshf_out[7]),
  .in8 (lshf_out[8]),
  .in9 (lshf_out[9]),
  .in10(lshf_out[10]),
  .in11(lshf_out[11]),
  .in12(lshf_out[12]),
  .in13(lshf_out[13]),
  .in14(lshf_out[14]),
  .in15(lshf_out[15]),
  .in16(lshf_out[16]),
  .in17(lshf_out[17]),
  .in18(lshf_out[18]),
  .in19(lshf_out[19]),
  .in20(lshf_out[20]),
  .in21(lshf_out[21]),
  .in22(lshf_out[22]),
  .in23(lshf_out[23]),
  .in24(lshf_out[24]),
  .in25(lshf_out[25]),
  .in26(lshf_out[26]),
  .in27(lshf_out[27]),
  .in28(lshf_out[28]),
  .in29(lshf_out[29]),
  .in30(lshf_out[30]),
  .in31(lshf_out[31]),
  .s0(shf_amt[0]),
  .s1(shf_amt[1]),
  .s2(shf_amt[2]),
  .s3(shf_amt[3]),
  .s4(shf_amt[4]),
  .outb(out)
);

endmodule
