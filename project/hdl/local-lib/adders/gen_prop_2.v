/*
Delay: 0.35ns through Pij, 0.6ns through Gi_j
*/
module gen_prop_2(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j);
	
	input		Pi_k, Pkm1_j, Gi_k, Gkm1_j;
	output	Gi_j, Pi_j;
	
	// wire		u_prop_l_gen;
	
	and2$ and2$_0(Pi_j, Pi_k, Pkm1_j);
	 
	// and2$	and2$_1(u_prop_l_gen, Pi_k, Gkm1_j);
	//  or2$  or2$_0(Gi_j, Gi_k, u_prop_l_gen);	

  wire    w0, w1;
  nand2$  nand2$_0(w0, Pi_k, Gkm1_j);
  nand2$  nand2$_1(w1, Gi_k, Gi_k);
  nand2$  nand2$_2(Gi_j, w0, w1);
	
endmodule