module  rshfa_const_tb;

initial begin
  // $vcdplusfile("rshfa_const_tb.dump.vpd");
  // $vcdpluson(0, rshfa_const_tb); 
end

localparam WIDTH = 32;

reg   [WIDTH-1:0]   in;
wire  [WIDTH-1:0]   out, out_exp;

rshfa_const #(
  .WIDTH(32),
  .SHF_AMT(16)
) DUT (
  .in(in),
  .out(out)
);

rshfa_const_behav #(
  .WIDTH(32),
  .SHF_AMT(16)
) REF (
  .in(in),
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
  repeat (1 << 10) begin
    #5; 
    check(out, out_exp);
    in = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule