module  rshf_bytes_var_128b_tb;//

initial begin
  // $vcdplusfile("rshf_bytes_var_128b_tb.dump.vpd");
  // $vcdpluson(0, rshf_bytes_var_128b_tb); 
end

localparam WIDTH = 128;

reg   [WIDTH-1:0]   in;
reg         [3:0]   shf_amt;
wire  [WIDTH-1:0]   out, out_exp;

rshf_bytes_var_128b DUT (
  .in(in), .shf_amt(shf_amt),
  .out(out)
);

rshf_bytes_var_128b_behav REF (
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
    in = {$random, $random, $random, $random};
    shf_amt = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule