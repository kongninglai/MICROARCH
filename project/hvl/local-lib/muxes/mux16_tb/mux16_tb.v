module mux16_tb;

initial begin
  $vcdplusfile("mux16_tb.dump.vpd");
  $vcdpluson(0, mux16_tb);
end

localparam IN_WIDTH = 16 + 4;

reg [IN_WIDTH-1:0] in;
wire out, out_exp;

wire s0 = in[0];
wire s1 = in[1];
wire s2 = in[2];
wire s3 = in[3];

wire in0  = in[4];
wire in1  = in[5];
wire in2  = in[6];
wire in3  = in[7];
wire in4  = in[8];
wire in5  = in[9];
wire in6  = in[10];
wire in7  = in[11];
wire in8  = in[12];
wire in9  = in[13];
wire in10 = in[14];
wire in11 = in[15];
wire in12 = in[16];
wire in13 = in[17];
wire in14 = in[18];
wire in15 = in[19];

mux16 DUT(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .in8(in8),  .in9(in9),  .in10(in10), .in11(in11),
  .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3),
  .outb(out)
);

mux16_behav REF(
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
  in = 0;
  repeat (1 << IN_WIDTH) begin
    #5;
    check(out, out_exp);
    in = in + 1;
  end

  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule