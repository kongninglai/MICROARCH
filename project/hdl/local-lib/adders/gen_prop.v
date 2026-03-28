/*
Delay: 0.35ns
*/
module gen_prop(gen, prop, in0, in1);
	
	input		in0, in1;
	output	gen, prop;
	
	and2$ and2_0(gen, in0, in1);
	xor2$ xor2_0(prop, in0, in1);
	
endmodule