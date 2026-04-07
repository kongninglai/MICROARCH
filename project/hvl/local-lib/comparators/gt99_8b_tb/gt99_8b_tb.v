module  gt99_8b_tb;

initial begin
  // $vcdplusfile("gt99_8b_tb.dump.vpd");
  // $vcdpluson(0, gt99_8b_tb); 
end

localparam WIDTH = 8;

reg   [WIDTH-1:0] in;
wire              out, out_exp;

gt99_8b DUT(.in(in), .gt(out));

gt99_8b_behav REF(.in(in), .gt(out_exp));

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
  
  in = 0;
  repeat (1 << WIDTH) begin
    #40;
    check(out, out_exp);
    in  = in + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule