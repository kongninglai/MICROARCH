module xor8LL_behav(
  output  out,
  input   in0, in1, in2, in3, in4, in5, in6, in7
);
	assign out = in0 ^ in1 ^ in2 ^ in3 ^ in4 ^ in5 ^ in6 ^ in7;
endmodule