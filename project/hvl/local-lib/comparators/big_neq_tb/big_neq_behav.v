module big_neq_behav #(
  parameter WIDTH=32
) (
  input     [WIDTH-1:0]   in0, in1,
  output                  neq
);

assign neq = (in0 != in1);

endmodule