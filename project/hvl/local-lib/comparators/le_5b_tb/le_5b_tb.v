module  le_5b_tb;

initial begin
  $vcdplusfile("le_5b_tb.dump.vpd");
  $vcdpluson(0, le_5b_tb); 
end

reg   [4:0] A, B;
wire   out, out_exp;

le_5b DUT(out, A, B);

le_5b_bh DUT_BH(out_exp, A, B);

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

  repeat (1 << 8) begin
    #40;
    check(out, out_exp);
    A  = $random;
    B  = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule