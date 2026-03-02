module big_increment_behav #(
  parameter WIDTH = 32
) (
  input  [WIDTH-1:0] a,
  output [WIDTH-1:0] s
);

assign s = a + 1;


endmodule