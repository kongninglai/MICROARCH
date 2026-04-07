module  ex_not_tb;

initial begin
  // $vcdplusfile("ex_not_tb.dump.vpd");
  // $vcdpluson(0, ex_not_tb); 
end

localparam WIDTH = 32;
reg   [WIDTH-1:0]   in;
wire  [WIDTH-1:0]   out, out_exp;


ex_not DUT(
  .not_out(out), .not_in(in)
);

ex_not_bh REF(
  .not_out(out_exp), .not_in(in)
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
  // All possible tests with truth table
  in = 0;
  repeat (1 << 12) begin
    #1; 
    check(out, out_exp);
    in = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule