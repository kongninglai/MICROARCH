module mux32_16b_tb;

initial begin
  // $vcdplusfile("mux32_16b_tb.dump.vpd");
  // $vcdpluson(0, mux32_16b_tb);
end

localparam WIDTH = 16;

reg [4:0]       in;
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
                in15,
                in16,
                in17,
                in18,
                in19,
                in20,
                in21,
                in22,
                in23,
                in24,
                in25,
                in26,
                in27,
                in28,
                in29,
                in30,
                in31;

wire [WIDTH-1:0] out, out_exp;

wire s0 = in[0];
wire s1 = in[1];
wire s2 = in[2];
wire s3 = in[3];
wire s4 = in[4];

mux32_16b DUT(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19),
  .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27),
  .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4),
  .outb(out)
);

mux32_16b_behav REF(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19),
  .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27),
  .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4),
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
    in16  <= $random;
    in17  <= $random;
    in18  <= $random;
    in19  <= $random;
    in20  <= $random;
    in21  <= $random;
    in22  <= $random;
    in23  <= $random;
    in24  <= $random;
    in25  <= $random;
    in26  <= $random;
    in27  <= $random;
    in28  <= $random;
    in29  <= $random;
    in30  <= $random;
    in31  <= $random;

    repeat (1 << 5) begin
      #5;
      check(out, out_exp);
      in = in + 5'd1;
    end
  end

  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;

end

endmodule