module big_or_11 (
  input depSREG, depSR1, depSR2, depMMA, depMMB, depBS1, depBS2, depIDX, depA, depB, depC,
  output out
);

wire early_nor4;
wire early_inv_straggler;
wire mid_nor3;
wire early_mid_combo;
wire out_n;

nor4$ nor4$_g_early_nor (early_nor4, depSREG, depSR1, depSR2, depMMA);
inv1$ inv1$_g_early_inv (early_inv_straggler, depMMB);
nor3$ nor3$_g_mid_nor (mid_nor3, depBS1, depBS2, depIDX);
nand3$ nand3$_g_combo (early_mid_combo, early_nor4, early_inv_straggler, mid_nor3);
or4$ or4$_out(out, depA, depB, depC, early_mid_combo);

endmodule