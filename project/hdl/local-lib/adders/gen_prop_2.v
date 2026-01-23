module gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j);
	
	input		Pi_k, Pkm1_j, Gi_k, Gkm1_j;
	output	Gi_j, Pi_j;
	
	wire		u_prop_l_gen;
	
	and2$ and2$_0(Pi_j, Pi_k, Pkm1_j);
	 
	and2$	and2$_1(u_prop_l_gen, Pi_k, Gkm1_j);
	 or2$  or2$_0(Gi_j, Gi_k, u_prop_l_gen);	
	
endmodule