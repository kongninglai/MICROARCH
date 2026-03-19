module  mux8_32_tb;

initial begin
  $vcdplusfile("mux8_32_tb.dump.vpd");
  $vcdpluson(0, mux8_32_tb); 
end


reg [63:0] in0, in1, in2, in3, in4, in5, in6, in7;
reg s0, s1, s2;
wire [63:0] out;

wire [63:0] out_bh;

mux8_64  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2), .out(out)
);

mux8_64_behav  DUT_BH(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2), .out(out_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task apply;
    input [63:0] test_in0, test_in1, test_in2, test_in3, test_in4, test_in5, test_in6, test_in7;
    input test_s0, test_s1, test_s2;
    begin 
        in0 = test_in0;
        in1 = test_in1;
        in2 = test_in2;
        in3 = test_in3;
        in4 = test_in4;
        in5 = test_in5;
        in6 = test_in6;
        in7 = test_in7;
        s0 = test_s0;
        s1 = test_s1;
        s2 = test_s2;
    end
endtask

task check;
  input [63:0] out, out_exp;
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
  repeat (1 << 8) begin
    apply($random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random);
    #1.5; 
    check(out, out_bh);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule