module  lshf_var_32b_tb;

// Dump all waveforms to d_latch.dump.vpd
initial begin
  $vcdplusfile("lshf_var_32b_tb.dump.vpd");
  $vcdpluson(0, lshf_var_32b_tb); 
end

localparam WIDTH = 32;
localparam SHF_WIDTH = 5;

reg   [WIDTH+SHF_WIDTH-1:0]   in_long;
wire  [WIDTH-1:0]             out, out_exp;

wire  [WIDTH-1:0]     in;
wire  [SHF_WIDTH-1:0] shf_amt;

assign in       = in_long[31:0];
assign shf_amt  = in_long[WIDTH+SHF_WIDTH-1:32];

lshf_var_32b DUT (
  .in(in),
  .shf_amt(shf_amt),
  .out(out)
);

lshf_var_32b_behav REF (
  .in(in),
  .shf_amt(shf_amt),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // All possible tests with truth table
  in_long = 0;
  repeat (1 << 20) begin
    // PS2 version fails at 2.4, cascaded library muxes succeed
    // library 442 fails at 1.4
    #5; 
    check(out, out_exp);
    in_long[WIDTH+SHF_WIDTH-1:32] = $random;
    in_long[31:0] = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule