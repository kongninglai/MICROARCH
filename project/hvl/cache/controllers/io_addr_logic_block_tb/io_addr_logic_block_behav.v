module io_addr_logic_block_behav (
  input     [2:0] KB_PFN, DMA_PFN, PFN,
  output reg[2:0] WHICH_IO
);

// [2] = MEM, [1] = DMA, [0] = KB

always @(*) begin
  WHICH_IO[0] = (KB_PFN  == PFN);
  WHICH_IO[1] = (DMA_PFN == PFN);
  WHICH_IO[2] = (PFN != KB_PFN) && (PFN != DMA_PFN);
end

endmodule