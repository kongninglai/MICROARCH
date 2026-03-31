module  xor8LL_tb;

initial begin
  // $vcdplusfile("xor8LL_tb.dump.vpd");
  // $vcdpluson(0, xor8LL_tb); 
end

reg   [7:0] in;
wire        out, out_exp;

wire in0 = in[0];
wire in1 = in[1];
wire in2 = in[2];
wire in3 = in[3];
wire in4 = in[4];
wire in5 = in[5];
wire in6 = in[6];
wire in7 = in[7];

xor8LL  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .out(out)
);

xor8LL_behav  REF(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .out(out_exp)
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
  in = 8'd0;
  repeat (16) begin
    #1; 
    check(out, out_exp);
    in = in + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule