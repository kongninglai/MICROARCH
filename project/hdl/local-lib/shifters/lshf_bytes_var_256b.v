// Designed to shift a 256b wire in 8b chunks

module lshf_bytes_var_256b #(
  parameter WIDTH = 256,
  parameter SHF_ZEROS = 1
) (
  input  [255:0] in,
  input  [4:0]   shf_amt,
  output [255:0] out
);

wire [255:0] lshf_out [31:1];

wire  [4:0] shf_amt_buf64;

bufferH64$    bufferH64$_shf_amt_buf64[4:0](shf_amt_buf64, shf_amt);

genvar i; //
generate
  for (i = 1; i < 32; i = i + 1) begin : LSHF_INST
    lshf_chunks #(
      .SHF_AMT(i), .CHUNK_WIDTH(8), .WIDTH(WIDTH), .SHF_ZEROS(SHF_ZEROS)
    ) lshf_gen (
      .in(in),
      .out(lshf_out[i])
    );
  end
endgenerate

generate
  for (i = 0; i < 16; i = i + 1) begin : MUX16_16b_GEN
    mux32_16b mux32_16b_inst (
      .in0 (in[i*16 +: 16]),
      .in1 (lshf_out[1 ][i*16 +: 16]),
      .in2 (lshf_out[2 ][i*16 +: 16]),
      .in3 (lshf_out[3 ][i*16 +: 16]),
      .in4 (lshf_out[4 ][i*16 +: 16]),
      .in5 (lshf_out[5 ][i*16 +: 16]),
      .in6 (lshf_out[6 ][i*16 +: 16]),
      .in7 (lshf_out[7 ][i*16 +: 16]),
      .in8 (lshf_out[8 ][i*16 +: 16]),
      .in9 (lshf_out[9 ][i*16 +: 16]),
      .in10(lshf_out[10][i*16 +: 16]),
      .in11(lshf_out[11][i*16 +: 16]),
      .in12(lshf_out[12][i*16 +: 16]),
      .in13(lshf_out[13][i*16 +: 16]),
      .in14(lshf_out[14][i*16 +: 16]),
      .in15(lshf_out[15][i*16 +: 16]),
      .in16(lshf_out[16][i*16 +: 16]),
      .in17(lshf_out[17][i*16 +: 16]),
      .in18(lshf_out[18][i*16 +: 16]),
      .in19(lshf_out[19][i*16 +: 16]),
      .in20(lshf_out[20][i*16 +: 16]),
      .in21(lshf_out[21][i*16 +: 16]),
      .in22(lshf_out[22][i*16 +: 16]),
      .in23(lshf_out[23][i*16 +: 16]),
      .in24(lshf_out[24][i*16 +: 16]),
      .in25(lshf_out[25][i*16 +: 16]),
      .in26(lshf_out[26][i*16 +: 16]),
      .in27(lshf_out[27][i*16 +: 16]),
      .in28(lshf_out[28][i*16 +: 16]),
      .in29(lshf_out[29][i*16 +: 16]),
      .in30(lshf_out[30][i*16 +: 16]),
      .in31(lshf_out[31][i*16 +: 16]),
      .s0(shf_amt_buf64[0]),
      .s1(shf_amt_buf64[1]),
      .s2(shf_amt_buf64[2]),
      .s3(shf_amt_buf64[3]),
      .s4(shf_amt_buf64[4]),
      .outb(out[i*16 +: 16])
    );
  end
endgenerate

endmodule
