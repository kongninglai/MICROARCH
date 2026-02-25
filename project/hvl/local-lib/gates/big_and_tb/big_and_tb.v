module  big_and_tb;

initial begin
  $vcdplusfile("big_and_tb.dump.vpd");
  $vcdpluson(0, big_and_tb); 
end

localparam WIDTH = 32;
reg   [WIDTH-1:0]   in;
wire                out, out_exp;


big_and #(.WIDTH(WIDTH)) DUT(
  .out(out), .in(in)
);

big_and_behav #(.WIDTH(WIDTH)) REF(
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
  in = {WIDTH{1'b1}};
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