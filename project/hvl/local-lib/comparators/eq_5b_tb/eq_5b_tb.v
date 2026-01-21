module  eq_5b_tb;

initial begin
  $vcdplusfile("eq_5b_tb.dump.vpd");
  $vcdpluson(0, eq_5b_tb); 
end

localparam WIDTH = 5;

reg   [WIDTH-1:0] in0, in1;
wire              out, out_exp;

eq_5b DUT(.in0(in0), .in1(in1), .eq(out));

eq_5b_behav REF(.in0(in0), .in1(in1), .eq(out_exp));

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
  in0 = 5'h1E; in1 = 5'h1F; #40; check(out, out_exp);
  in0 = 5'h1F; in1 = 5'h1F; #40; check(out, out_exp);
  in0 = 5'd0; in1 = 5'h1F; #40; check(out, out_exp);
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