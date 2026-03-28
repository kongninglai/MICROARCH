module big_increment_cout_behav #(
  parameter WIDTH = 4
) (
  input  [WIDTH-1:0] a,
  output [WIDTH-1:0] s,
  output             cout
);

  assign {cout, s} = a + 1'b1; //overflow into cout

endmodule