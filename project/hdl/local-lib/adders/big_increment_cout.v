module big_increment_cout #(
  parameter WIDTH = 4 // Defaulted to 4
) (
  input  [WIDTH-1:0] a,
  output [WIDTH-1:0] s,
  output             cout 
);

    wire  [WIDTH-1:0]  c;
    wire  [WIDTH-1:0]  a_buf64;

    bufferH64$    bufferH64$_a_buf64[WIDTH-1:0](a_buf64, a);

    assign c[0] = 1'b1; //carry in = 1

    //and tree for carries/bit
    genvar i;
    generate
    for (i = 1; i < WIDTH; i = i + 1) begin : carry_generation
        big_and #(.WIDTH(i)) big_and_inst(c[i], a_buf64[i-1:0]);
    end
    endgenerate

    //generate carry out (only if all input bits = 1)
    big_and #(.WIDTH(WIDTH)) big_and_cout(cout, a_buf64[WIDTH-1:0]);

    // sum bits
    genvar j;
    generate
    for (j = 0; j < WIDTH; j = j + 1) begin : sum_generation
        xor2$ xor2$_sum(s[j], a[j], c[j]);
    end
    endgenerate

endmodule