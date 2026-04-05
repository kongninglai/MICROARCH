<<<<<<< HEAD
module  mux16_32_tb;

initial begin
  $vcdplusfile("mux16_32_tb.dump.vpd");
  $vcdpluson(0, mux16_32_tb); 
end


reg [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15;
reg s0, s1, s2, s3;
wire [31:0] out;

wire [31:0] out_bh;

mux16_32  DUT(
  .IN0(in0), .IN1(in1), .IN2(in2), .IN3(in3), .IN4(in4), .IN5(in5), .IN6(in6), .IN7(in7),
  .IN8(in8), .IN9(in9), .IN10(in10), .IN11(in11), .IN12(in12), .IN13(in13), .IN14(in14), .IN15(in15),
  .S0(s0), .S1(s1), .S2(s2), .S3(s3),
  .Y(out)
);

mux16_32_behav  REF(
  .IN0(in0), .IN1(in1), .IN2(in2), .IN3(in3), .IN4(in4), .IN5(in5), .IN6(in6), .IN7(in7),
  .IN8(in8), .IN9(in9), .IN10(in10), .IN11(in11), .IN12(in12), .IN13(in13), .IN14(in14), .IN15(in15),
  .S0(s0), .S1(s1), .S2(s2), .S3(s3),
  .Y(out_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task apply;
    input [31:0] test_in0, test_in1;
    input test_s0;
    begin 
        in0 = test_in0;
        in1 = test_in1;
        s0 = test_s0;
    end
endtask

task check;
  input out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
=======
module mux16_32_tb;

initial begin
  $vcdplusfile("mux16_32_tb.dump.vpd");
  $vcdpluson(0, mux16_32_tb);
end

localparam WIDTH = 32;

reg [3:0]       in;
reg [WIDTH-1:0] in0 ,
                in1 ,
                in2 ,
                in3 ,
                in4 ,
                in5 ,
                in6 ,
                in7 ,
                in8 ,
                in9 ,
                in10,
                in11,
                in12,
                in13,
                in14,
                in15;
wire [WIDTH-1:0] out, out_exp;

wire s0 = in[0];
wire s1 = in[1];
wire s2 = in[2];
wire s3 = in[3];

mux16_32 DUT(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3),
  .out(out)
);

mux16_32_bh REF(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out_val, out_exp_val;
  if (out_val !== out_exp_val) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h", $time, out_exp_val, out_val);
>>>>>>> origin/main
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
<<<<<<< HEAD
  // All possible tests with truth table
  repeat (1 << 8) begin
    apply({$random,$random}, {$random,$random}, $random);
    #1.5; 
    check(out, out_bh);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

=======
  repeat (1 << 10) begin
    in = $random;
    in0   <= $random;
    in1   <= $random;
    in2   <= $random;
    in3   <= $random;
    in4   <= $random;
    in5   <= $random;
    in6   <= $random;
    in7   <= $random;
    in8   <= $random;
    in9   <= $random;
    in10  <= $random;
    in11  <= $random;
    in12  <= $random;
    in13  <= $random;
    in14  <= $random;
    in15  <= $random;
    #5;
    check(out, out_exp);
  end

  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
>>>>>>> origin/main
end

endmodule