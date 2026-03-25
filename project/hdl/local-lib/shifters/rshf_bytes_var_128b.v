// Designed to shift a 128b wire in 8b chunks

module rshf_bytes_var_128b #(
  parameter WIDTH = 128,
  parameter SHF_ZEROS = 1
) (
  input  [127:0] in,
  input  [3:0]   shf_amt,
  output [127:0] out
);

wire [127:0] rshf_out [15:1];

wire  [3:0] shf_amt_buf64;

bufferH64$    bufferH64$_shf_amt_buf64[3:0](shf_amt_buf64, shf_amt);

genvar i;
generate
  for (i = 1; i < 16; i = i + 1) begin : RSHF_INST
    rshf_chunks #(
      .SHF_AMT(i), .CHUNK_WIDTH(8), .WIDTH(WIDTH), .SHF_ZEROS(SHF_ZEROS)
    ) rshf_gen (
      .in(in),
      .out(rshf_out[i])
    );
  end
endgenerate

generate
  for (i = 0; i < 8; i = i + 1) begin : MUX16_16b_GEN
    mux16_16b mux16_16b_inst (
      .in0 (in[i*16 +: 16]),
      .in1 (rshf_out[1 ][i*16 +: 16]),
      .in2 (rshf_out[2 ][i*16 +: 16]),
      .in3 (rshf_out[3 ][i*16 +: 16]),
      .in4 (rshf_out[4 ][i*16 +: 16]),
      .in5 (rshf_out[5 ][i*16 +: 16]),
      .in6 (rshf_out[6 ][i*16 +: 16]),
      .in7 (rshf_out[7 ][i*16 +: 16]),
      .in8 (rshf_out[8 ][i*16 +: 16]),
      .in9 (rshf_out[9 ][i*16 +: 16]),
      .in10(rshf_out[10][i*16 +: 16]),
      .in11(rshf_out[11][i*16 +: 16]),
      .in12(rshf_out[12][i*16 +: 16]),
      .in13(rshf_out[13][i*16 +: 16]),
      .in14(rshf_out[14][i*16 +: 16]),
      .in15(rshf_out[15][i*16 +: 16]),
      .s0(shf_amt_buf64[0]),
      .s1(shf_amt_buf64[1]),
      .s2(shf_amt_buf64[2]),
      .s3(shf_amt_buf64[3]),
      .outb(out[i*16 +: 16])
    );
  end
endgenerate

endmodule
