module  increment_32b_tb;

initial begin
  $vcdplusfile("increment_32b_tb.dump.vpd");
  $vcdpluson(0, increment_32b_tb); 
end

localparam WIDTH = 32;

reg   [WIDTH-1:0]   in;
wire  [WIDTH-1:0]   out, out_exp;

increment_32b DUT(.s(out), .a(in));

increment_32b_behav REF(.s(out_exp), .a(in));

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
  in = {32{1'b1}};
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