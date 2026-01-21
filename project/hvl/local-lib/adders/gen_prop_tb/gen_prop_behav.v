module gen_prop_behav(gen, prop, in0, in1);
	
	input		in0, in1;
	output	gen, prop;

  assign  gen   = in0 & in1;
  assign  prop  = in0 ^ in1;

endmodule