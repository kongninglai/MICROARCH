// Designed to shift a 256b wire in 16b chunks

module lshf_chunks_var_256b #(
  parameter WIDTH = 256
) (
  input  [255:0] in,
  input  [3:0]  shf_amt,
  output [255:0] out
);

wire [255:0] lshf_out [15:1];

wire  [3:0] shf_amt_buf64;

bufferH64$    bufferH64$_shf_amt_buf64[3:0](shf_amt_buf64, shf_amt);

genvar i;
generate
  for (i = 1; i < 16; i = i + 1) begin : LSHF_INST
    lshf_chunks #(
      .SHF_AMT(i)
    ) lshf_gen (
      .in(in),
      .out(lshf_out[i])
    );
  end
endgenerate

genvar j;

generate
  for (j = 0; j < 16; j = j + 1) begin : MUX16_16b_GEN
    mux16_16b mux16_16b_inst (
      .in0 (in[j*16 +: 16]),
      .in1 (lshf_out[1 ][j*16 +: 16]),
      .in2 (lshf_out[2 ][j*16 +: 16]),
      .in3 (lshf_out[3 ][j*16 +: 16]),
      .in4 (lshf_out[4 ][j*16 +: 16]),
      .in5 (lshf_out[5 ][j*16 +: 16]),
      .in6 (lshf_out[6 ][j*16 +: 16]),
      .in7 (lshf_out[7 ][j*16 +: 16]),
      .in8 (lshf_out[8 ][j*16 +: 16]),
      .in9 (lshf_out[9 ][j*16 +: 16]),
      .in10(lshf_out[10][j*16 +: 16]),
      .in11(lshf_out[11][j*16 +: 16]),
      .in12(lshf_out[12][j*16 +: 16]),
      .in13(lshf_out[13][j*16 +: 16]),
      .in14(lshf_out[14][j*16 +: 16]),
      .in15(lshf_out[15][j*16 +: 16]),
      .s0(shf_amt_buf64[0]),
      .s1(shf_amt_buf64[1]),
      .s2(shf_amt_buf64[2]),
      .s3(shf_amt_buf64[3]),
      .outb(out[j*16 +: 16])
    );
  end
endgenerate

endmodule
