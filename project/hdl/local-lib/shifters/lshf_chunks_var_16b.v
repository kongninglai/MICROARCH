// Designed to shift a 16b wire in 4b chunks

module lshf_chunks_var_16b #(
  parameter WIDTH = 16,
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
      .SHF_AMT(i), .CHUNK_WIDTH(4), .WIDTH(WIDTH), .SHF_ZEROS(SHF_ZEROS)
    ) lshf_gen (
      .in(in),
      .out(lshf_out[i])
    );
  end
endgenerate

mux4_16$ mux4_16b_inst (
  .IN0 (in),
  .IN1 (lshf_out[1 ]),
  .IN2 (lshf_out[2 ]),
  .IN3 (lshf_out[3 ]),
  .S0(shf_amt[0]),
  .S1(shf_amt[1]),
  .Y(out)
);

endmodule
