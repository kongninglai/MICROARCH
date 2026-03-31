module io_addr_logic_block_tb;

initial begin
  // $vcdplusfile("io_addr_logic_block_tb.dump.vpd");
  // $vcdpluson(0, io_addr_logic_block_tb);
end

reg  [8:0] in_long;
wire [2:0] out, out_exp;

wire [2:0] KB_PFN  = in_long[2:0];
wire [2:0] DMA_PFN = in_long[5:3];
wire [2:0] PFN     = in_long[8:6];

io_addr_logic_block DUT(
  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),
  .PFN(PFN),
  .WHICH_IO(out)
);

io_addr_logic_block_behav REF(
  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),
  .PFN(PFN),
  .WHICH_IO(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [2:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. in = %b, out_exp = %b, out = %b\n",
              $time, in_long, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  in_long = 0;

  repeat (1 << 9) begin
    #5;
    check(out, out_exp);
    in_long = in_long + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule