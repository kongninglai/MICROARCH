//-----------------------------------------------------

// GATED D LATCH

//-----------------------------------------------------
// Functionality:
// pass d when wen is 1
// hold d when wen is 0
//
module d_latch (d, q, qbar, wen);
   input d, wen;
   output q, qbar;
   
   wire   dbar, r, s;
   
   inv1$ inv1 (dbar, d);
   nand2$ nand1 (s, d, wen),
          nand2 (r, dbar, wen),
   
          nand3 (q, s, qbar),
          nand4 (qbar, r, q);
   
endmodule