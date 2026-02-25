module  big_increment_tb;

initial begin
  $vcdplusfile("big_increment_tb.dump.vpd");
  $vcdpluson(0, big_increment_tb); 
end

localparam WIDTH = 3;

reg   [WIDTH-1:0]   in;
wire  [WIDTH-1:0]   out, out_exp;

big_increment #(.WIDTH(WIDTH)) DUT(.s(out), .a(in));

big_increment_behav #(.WIDTH(WIDTH)) REF(.s(out_exp), .a(in));

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
  in = 0; #5; check(out, out_exp);
  in = {WIDTH{1'b1}};
  repeat (1 << 12) begin
    #5; 
    check(out, out_exp);
    in = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule