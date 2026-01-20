module TOP;

   reg d, we;
   wire q, qb;
   
   initial
      begin
	 
	 d = 0;
	 we = 0;
	 
	 #1
	    we = 1;
	 #1
	    we = 0;
	 
	 #1
	    d = 1;
	 #1
	    we = 1;
	 
	 #1
	    d = 0;
	 #1
	    d = 1;
	 #1
	    d = 0;
	 #0.8
	    we = 0;
	 
      end
   
   // Run simulation for 15 ns.  
   initial #15 $finish;
   
   // Dump all waveforms to d_latch.dump.vpd
   initial
      begin
	 //$dumpfile ("d_latch.dump");
	 //$dumpvars (0, TOP);
	 $vcdplusfile("d_latch.dump.vpd");
	 $vcdpluson(0, TOP); 
      end // initial begin
   
   always @(posedge d)
      $strobe ("at time %0d, wen = %b", $time, we);
   
   d_latch latch1 (d, q, qb, we);
   
endmodule