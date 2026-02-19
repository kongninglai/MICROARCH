module big_eq_behav #(
  parameter WIDTH=32
) (
  input     [31:0]    in0, in1,
  output              eq
);

assign eq = (in0[WIDTH-1:0] == in1[WIDTH-1:0]);

endmodule