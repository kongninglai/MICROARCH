module rshfa_var_32b (
  input  [31:0] in,
  input  [4:0]  shf_amt,
  output [31:0] out
);

wire [31:0] rshfa_out [31:1];

genvar i;
generate
  for (i = 1; i < 32; i = i + 1) begin : RSHFA_INST
    rshfa_const #(
      .WIDTH(32),
      .SHF_AMT(i)
    ) rshfa_gen (
      .in(in),
      .out(rshfa_out[i])
    );
  end
endgenerate

mux32 mux32_0[31:0] (
  .in0 (in),
  .in1 (rshfa_out[1]),
  .in2 (rshfa_out[2]),
  .in3 (rshfa_out[3]),
  .in4 (rshfa_out[4]),
  .in5 (rshfa_out[5]),
  .in6 (rshfa_out[6]),
  .in7 (rshfa_out[7]),
  .in8 (rshfa_out[8]),
  .in9 (rshfa_out[9]),
  .in10(rshfa_out[10]),
  .in11(rshfa_out[11]),
  .in12(rshfa_out[12]),
  .in13(rshfa_out[13]),
  .in14(rshfa_out[14]),
  .in15(rshfa_out[15]),
  .in16(rshfa_out[16]),
  .in17(rshfa_out[17]),
  .in18(rshfa_out[18]),
  .in19(rshfa_out[19]),
  .in20(rshfa_out[20]),
  .in21(rshfa_out[21]),
  .in22(rshfa_out[22]),
  .in23(rshfa_out[23]),
  .in24(rshfa_out[24]),
  .in25(rshfa_out[25]),
  .in26(rshfa_out[26]),
  .in27(rshfa_out[27]),
  .in28(rshfa_out[28]),
  .in29(rshfa_out[29]),
  .in30(rshfa_out[30]),
  .in31(rshfa_out[31]),
  .s0(shf_amt[0]),
  .s1(shf_amt[1]),
  .s2(shf_amt[2]),
  .s3(shf_amt[3]),
  .s4(shf_amt[4]),
  .outb(out)
);

endmodule
