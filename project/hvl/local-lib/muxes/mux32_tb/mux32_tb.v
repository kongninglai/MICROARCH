module  mux32_tb;

initial begin
  $vcdplusfile("mux32_tb.dump.vpd");
  $vcdpluson(0, mux32_tb); 
end

localparam IN_WIDTH = 32 + 5;

reg   [IN_WIDTH-1:0]  in;
wire                  out, out_exp;

wire  s0 = in[0];
wire  s1 = in[1];
wire  s2 = in[2];
wire  s3 = in[3];
wire  s4 = in[4];

wire in0  = in[5];
wire in1  = in[6];
wire in2  = in[7];
wire in3  = in[8];
wire in4  = in[9];
wire in5  = in[10];
wire in6  = in[11];
wire in7  = in[12];
wire in8  = in[13];
wire in9  = in[14];
wire in10 = in[15];
wire in11 = in[16];
wire in12 = in[17];
wire in13 = in[18];
wire in14 = in[19];
wire in15 = in[20];
wire in16 = in[21];
wire in17 = in[22];
wire in18 = in[23];
wire in19 = in[24];
wire in20 = in[25];
wire in21 = in[26];
wire in22 = in[27];
wire in23 = in[28];
wire in24 = in[29];
wire in25 = in[30];
wire in26 = in[31];
wire in27 = in[32];
wire in28 = in[33];
wire in29 = in[34];
wire in30 = in[35];
wire in31 = in[36];

mux32  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .in8(in8), .in9(in9), .in10(in10), .in11(in11), .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19), .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27), .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4),
  .outb(out)
);

mux32_behav  REF(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .in8(in8), .in9(in9), .in10(in10), .in11(in11), .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19), .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27), .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4),
  .outb(out_exp)
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
  in = 0;
  repeat (1 << 8) begin
    #4; 
    check(out, out_exp);
    in[36:32] = $random;
    in[31:0] = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule