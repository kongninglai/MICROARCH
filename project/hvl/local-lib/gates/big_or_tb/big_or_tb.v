module  big_or_tb;

initial begin
  // $vcdplusfile("big_or_tb.dump.vpd");
  // $vcdpluson(0, big_or_tb); 
end

localparam WIDTH = 11;
reg   [WIDTH-1:0]   in;
wire                out, out_exp;


big_or #(.WIDTH(WIDTH)) DUT(
  .out(out), .in(in)
);

big_or_behav #(.WIDTH(WIDTH)) REF(
  .out(out_exp), .in(in)
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
  in = 0;
  repeat (1 << 12) begin
    #10; 
    check(out, out_exp);
    in = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule