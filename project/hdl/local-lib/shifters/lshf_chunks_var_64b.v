// Designed to shift a 64b wire in 16b chunks

module lshf_chunks_var_64b #(
  parameter WIDTH = 64,
  parameter SHF_ZEROS = 0
) (
  input  [WIDTH-1:0]  in,
  input  [1:0]        shf_amt,
  output [WIDTH-1:0]  out
);

wire [WIDTH-1:0] lshf_out [3:1];

genvar i;
generate
  for (i = 1; i < 4; i = i + 1) begin : LSHF_INST
    lshf_chunks #(
      .SHF_AMT(i), .CHUNK_WIDTH(16), .WIDTH(WIDTH), .SHF_ZEROS(SHF_ZEROS)
    ) lshf_gen (
      .in(in),
      .out(lshf_out[i])
    );
  end
endgenerate

generate
  for (i = 0; i < 4; i = i + 1) begin : mux4_16b_gen

    mux4_16$ mux4_16b_inst (
      .IN0 (in      [16*i +: 16]),
      .IN1 (lshf_out[1][16*i +: 16]),
      .IN2 (lshf_out[2][16*i +: 16]),
      .IN3 (lshf_out[3][16*i +: 16]),
      .S0  (shf_amt[0]),
      .S1  (shf_amt[1]),
      .Y   (out     [16*i +: 16])
    );
  end
endgenerate

endmodule
