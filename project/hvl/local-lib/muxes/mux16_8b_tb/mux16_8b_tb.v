module mux16_8b_tb;

initial begin
  // $vcdplusfile("mux16_8b_tb.dump.vpd");
  // $vcdpluson(0, mux16_8b_tb);
end

localparam WIDTH = 8;

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

mux16_8b DUT(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3),
  .outb(out)
);

mux16_8b_behav REF(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3),
  .outb(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out_val, out_exp_val;
  if (out_val !== out_exp_val) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h", $time, out_exp_val, out_val);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  repeat (1 << 15) begin
    in = 0;
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
    repeat (1 << 4) begin
      #5;
      check(out, out_exp);
      in = in + 4'd1;
    end
  end

  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule