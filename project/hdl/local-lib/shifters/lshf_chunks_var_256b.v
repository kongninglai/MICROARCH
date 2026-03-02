module lshf_chunks_var_256b #(
  parameter WIDTH = 256
) (
  input  [255:0] in,
  input  [3:0]  shf_amt,
  output [255:0] out
);

wire [255:0] lshf_out [255:1];

wire  [3:0] shf_amt_buf1024;

bufferH1024$    bufferH1024$_shf_amt_buf1024[3:0](shf_amt_buf1024, shf_amt);

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

mux16 mux16_0[255:0] (
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
  .s0(shf_amt_buf1024[0]),
  .s1(shf_amt_buf1024[1]),
  .s2(shf_amt_buf1024[2]),
  .s3(shf_amt_buf1024[3]),
  .outb(out)
);

endmodule
