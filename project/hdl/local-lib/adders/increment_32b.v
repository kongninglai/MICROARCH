module increment_32b (
  input  [31:0] a,
  output [31:0] s
);

wire  [31:0]  c;

wire  [31:0]  a_buf64;

bufferH64$    bufferH64$_a_buf64[31:0](a_buf64, a);

// Stage 0: carry-in for bit 0 is 1
assign c[0] = 1'b1;

// Stage 1: compute prefix AND tree
genvar i;
generate
  for (i = 1; i < 32; i = i + 1) begin : carry_generation
    big_and #(.WIDTH(i)) big_and_inst(c[i], a_buf64);
  end
endgenerate

// Sum bits
genvar i;
generate
  for (i = 0; i < 32; i = i + 1) begin
    xor2$ xor2$_sum(s[i], a_buf64[i], c[i]);
  end
endgenerate

endmodule
