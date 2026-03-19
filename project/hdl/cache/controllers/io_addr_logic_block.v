module io_addr_logic_block (
  input     [2:0]                               KB_PFN, DMA_PFN, PFN,
  output    [2:0]                               WHICH_IO
);

// [2] = MEM, [1] = DMA, [0] = KB

big_eq #(
  .WIDTH(3)
) big_eq_IS_KB (
  .in0(KB_PFN), .in1(PFN),
  .eq(WHICH_IO[0])
);

big_eq #(
  .WIDTH(3)
) big_eq_IS_DMA (
  .in0(DMA_PFN), .in1(PFN),
  .eq(WHICH_IO[1])
);

wire    ISNT_KB, ISNT_DMA;

big_neq #(
  .WIDTH(3)
) big_neq_ISNT_KB (
  .in0(KB_PFN), .in1(PFN),
  .neq(ISNT_KB)
);

big_neq #(
  .WIDTH(3)
) big_neq_ISNT_DMA (
  .in0(DMA_PFN), .in1(PFN),
  .neq(ISNT_DMA)
);

and2$   and2$_IS_MEM(WHICH_IO[2], ISNT_KB, ISNT_DMA);

endmodule