module  mux8_32_tb;

initial begin
  $vcdplusfile("mux8_32_tb.dump.vpd");
  $vcdpluson(0, mux8_32_tb); 
end


reg [31:0] in0, in1, in2, in3, in4, in5, in6, in7;
reg s0, s1, s2;
wire [31:0] out;

wire [31:0] out_bh;

mux8_32  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2), .out(out)
);

mux8_32_behav  REF(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2), .out(out_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task apply;
    input [31:0] test_in0, test_in1, test_in2, test_in3, test_in4, test_in5, test_in6, test_in7;
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
        s2 = test_s2;
        s0 = test_s0;
        s1 = test_s1;
    end
endtask

task check;
  input [31:0] Y, Y_bh;
  if (Y !== Y_bh) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. Y_bh = %h, Y = %h\n", 
              $time, Y_bh, Y);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // All possible tests with truth table
  repeat (1 << 8) begin
    apply({$random,$random}, {$random,$random}, {$random,$random}, {$random,$random}, {$random,$random}, {$random,$random}, {$random,$random}, {$random,$random}, $random, $random, $random);
    #1.5; 
    check(out, out_bh);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule