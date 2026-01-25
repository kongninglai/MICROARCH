module  fact_tb;

initial begin
  $vcdplusfile("fact_tb.dump.vpd");
  $vcdpluson(0, fact_tb); 
end

integer inp, fact_exp, fact_out;

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input integer fact_out, fact_exp;
  if (fact_out !== fact_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. fact_exp = %h, fact_out = %h\n", 
              $time, fact_exp, fact_out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  inp = -1; fact_out = fact_mod.fact(inp); fact_exp = 0; #1; check(fact_out, fact_exp);
  inp = 0; fact_out = fact_mod.fact(inp); fact_exp = 1; #1; check(fact_out, fact_exp);
  inp = 1; fact_out = fact_mod.fact(inp); fact_exp = 1; #1; check(fact_out, fact_exp);
  inp = 2; fact_out = fact_mod.fact(inp); fact_exp = 2; #1; check(fact_out, fact_exp);
  inp = 3; fact_out = fact_mod.fact(inp); fact_exp = 6; #1; check(fact_out, fact_exp);
  inp = 4; fact_out = fact_mod.fact(inp); fact_exp = 24; #1; check(fact_out, fact_exp);
  inp = 5; fact_out = fact_mod.fact(inp); fact_exp = 120; #1; check(fact_out, fact_exp);
  inp = 6; fact_out = fact_mod.fact(inp); fact_exp = 720; #1; check(fact_out, fact_exp);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule