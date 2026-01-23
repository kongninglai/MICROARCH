module  eq_3b_tb;

initial begin
  $vcdplusfile("eq_3b_tb.dump.vpd");
  $vcdpluson(0, eq_3b_tb); 
end

localparam WIDTH = 3;

reg   [WIDTH-1:0] in0, in1;
wire              out, out_exp;

eq_3b DUT(.in0(in0), .in1(in1), .eq(out));

eq_3b_behav REF(.in0(in0), .in1(in1), .eq(out_exp));

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
  
  in0 = 0; in1 = 1; #40; check(out, out_exp);
  in0 = 1; in1 = 1; #40; check(out, out_exp);
  in0 = 2; in1 = 1; #40; check(out, out_exp);

  in0 = 0; in0 = 1;
  repeat (1 << 8) begin
    #40;
    check(out, out_exp);
    in0  = $random;
    in1  = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule