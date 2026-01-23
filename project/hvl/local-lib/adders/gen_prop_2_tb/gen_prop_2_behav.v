module gen_prop_2_behav(Gi_j, Pi_j, Pi_k, Pkm1_j, Gi_k, Gkm1_j);
	
	input	  Pi_k, Pkm1_j, Gi_k, Gkm1_j;
	output  Gi_j, Pi_j;

  assign  Gi_j = (Gi_k) | (Gkm1_j & Pi_k);
  assign  Pi_j = (Pi_k) & (Pkm1_j);

endmodule