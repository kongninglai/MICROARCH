module xor3LL_behav(
  input   in0, in1, in2,
  output  out
);
	assign out = in0 ^ in1 ^ in2;
endmodule