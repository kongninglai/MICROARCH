module big_increment #(
  parameter WIDTH = 32
) (
  input  [WIDTH-1:0] a,
  output [WIDTH-1:0] s
);

wire  [WIDTH-1:0]  c;

wire  [WIDTH-1:0]  a_buf64;

bufferH64$    bufferH64$_a_buf64[WIDTH-1:0](a_buf64, a);

// Stage 0: carry-in for bit 0 is 1
assign c[0] = 1'b1;

// Stage 1: compute prefix AND tree
genvar i;
generate
  for (i = 1; i < WIDTH; i = i + 1) begin : carry_generation
    if (WIDTH < 8) begin
      big_and #(.WIDTH(i)) big_and_inst(c[i], a[i-1:0]);
    end else begin
      big_and #(.WIDTH(i)) big_and_inst(c[i], a_buf64[i-1:0]);
    end
  end
endgenerate

// Sum bits
genvar j;
generate
  for (j = 0; j < WIDTH; j = j + 1) begin
    if (WIDTH < 8) begin
      xor2$ xor2$_sum(s[j], a[j], c[j]);
    end else begin
      xor2$ xor2$_sum(s[j], a_buf64[j], c[j]);
    end
  end
endgenerate

endmodule
