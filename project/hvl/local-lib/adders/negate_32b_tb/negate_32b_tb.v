module  negate_32b_tb;

initial begin
  $vcdplusfile("negate_32b_tb.dump.vpd");
  $vcdpluson(0, negate_32b_tb); 
end

localparam WIDTH = 32;

reg   [WIDTH-1:0] in;
wire  [WIDTH-1:0] out, out_exp;

negate_32b DUT(.in(in), .out(out));

negate_32b_behav REF(.in(in), .out(out_exp));

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
  
  in = 0; #40; check(out, out_exp);
  in = -32'd1; #40; check(out, out_exp);
  in = 0;
  repeat (1 << 8) begin
    #40;
    check(out, out_exp);
    in  = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule