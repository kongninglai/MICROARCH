module xor4LL_behav(
  input   in0, in1, in2, in3,
  output  out
);
	assign out = in0 ^ in1 ^ in2 ^ in3;
endmodule