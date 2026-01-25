module  clog2_tb;

initial begin
  $vcdplusfile("clog2_tb.dump.vpd");
  $vcdpluson(0, clog2_tb); 
end

integer inp, clog2_exp, clog2_out;

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input integer clog2_out, clog2_exp;
  if (clog2_out !== clog2_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. clog2_exp = %h, clog2_out = %h\n", 
              $time, clog2_exp, clog2_out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  inp = 0; clog2_out = clog2_mod.clog2(inp); clog2_exp = 1; #1; check(clog2_out, clog2_exp);
  inp = 1; clog2_out = clog2_mod.clog2(inp); clog2_exp = 1; #1; check(clog2_out, clog2_exp);
  inp = 2; clog2_out = clog2_mod.clog2(inp); clog2_exp = 1; #1; check(clog2_out, clog2_exp);
  inp = 3; clog2_out = clog2_mod.clog2(inp); clog2_exp = 2; #1; check(clog2_out, clog2_exp);
  inp = 4; clog2_out = clog2_mod.clog2(inp); clog2_exp = 2; #1; check(clog2_out, clog2_exp);
  inp = 5; clog2_out = clog2_mod.clog2(inp); clog2_exp = 3; #1; check(clog2_out, clog2_exp);
  inp = 6; clog2_out = clog2_mod.clog2(inp); clog2_exp = 3; #1; check(clog2_out, clog2_exp);
  inp = 7; clog2_out = clog2_mod.clog2(inp); clog2_exp = 3; #1; check(clog2_out, clog2_exp);
  inp = 8; clog2_out = clog2_mod.clog2(inp); clog2_exp = 3; #1; check(clog2_out, clog2_exp);
  inp = 9; clog2_out = clog2_mod.clog2(inp); clog2_exp = 4; #1; check(clog2_out, clog2_exp);
  inp = 15; clog2_out = clog2_mod.clog2(inp); clog2_exp = 4; #1; check(clog2_out, clog2_exp);
  inp = 16; clog2_out = clog2_mod.clog2(inp); clog2_exp = 4; #1; check(clog2_out, clog2_exp);
  inp = 17; clog2_out = clog2_mod.clog2(inp); clog2_exp = 5; #1; check(clog2_out, clog2_exp);
  inp = 32767; clog2_out = clog2_mod.clog2(inp); clog2_exp = 15; #1; check(clog2_out, clog2_exp);
  inp = 32768; clog2_out = clog2_mod.clog2(inp); clog2_exp = 15; #1; check(clog2_out, clog2_exp);
  inp = 32769; clog2_out = clog2_mod.clog2(inp); clog2_exp = 16; #1; check(clog2_out, clog2_exp);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule