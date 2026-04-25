module big_or_11_behav (
  input depSREG, depSR1, depSR2, depMMA, depMMB, depBS1, depBS2, depIDX, depA, depB, depC,
  output out
);

assign out =
    depSREG |
    depSR1  |
    depSR2  |
    depMMA  |
    depMMB  |
    depBS1  |
    depBS2  |
    depIDX  |
    depA    |
    depB    |
    depC;

endmodule
