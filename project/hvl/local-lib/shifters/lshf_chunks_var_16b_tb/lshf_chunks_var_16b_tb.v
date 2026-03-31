module  lshf_chunks_var_16b_tb;

initial begin
  // $vcdplusfile("lshf_chunks_var_16b_tb.dump.vpd");
  // $vcdpluson(0, lshf_chunks_var_16b_tb); 
end

localparam WIDTH = 16;

reg   [WIDTH-1:0]   in;
reg         [1:0]   shf_amt;
wire  [WIDTH-1:0]   out, out_exp;

lshf_chunks_var_16b DUT (
  .in(in), .shf_amt(shf_amt),
  .out(out)
);

lshf_chunks_var_16b_behav REF (
  .in(in), .shf_amt(shf_amt),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  in = 0;
  shf_amt = 0;
  repeat (1 << 12) begin
    #5; 
    check(out, out_exp);
    in = $random;
    shf_amt = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule