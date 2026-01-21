module  mux64_tb;

initial begin
  $vcdplusfile("mux64_tb.dump.vpd");
  $vcdpluson(0, mux64_tb); 
end

localparam IN_WIDTH = 64 + 6;

reg   [IN_WIDTH-1:0]  in;
wire                  out, out_exp;

wire  s0 = in[0];
wire  s1 = in[1];
wire  s2 = in[2];
wire  s3 = in[3];
wire  s4 = in[4];
wire  s5 = in[5];

wire in0  = in[6];
wire in1  = in[7];
wire in2  = in[8];
wire in3  = in[9];
wire in4  = in[10];
wire in5  = in[11];
wire in6  = in[12];
wire in7  = in[13];
wire in8  = in[14];
wire in9  = in[15];
wire in10 = in[16];
wire in11 = in[17];
wire in12 = in[18];
wire in13 = in[19];
wire in14 = in[20];
wire in15 = in[21];
wire in16 = in[22];
wire in17 = in[23];
wire in18 = in[24];
wire in19 = in[25];
wire in20 = in[26];
wire in21 = in[27];
wire in22 = in[28];
wire in23 = in[29];
wire in24 = in[30];
wire in25 = in[31];
wire in26 = in[32];
wire in27 = in[33];
wire in28 = in[34];
wire in29 = in[35];
wire in30 = in[36];
wire in31 = in[37];
wire in32 = in[38];
wire in33 = in[39];
wire in34 = in[40];
wire in35 = in[41];
wire in36 = in[42];
wire in37 = in[43];
wire in38 = in[44];
wire in39 = in[45];
wire in40 = in[46];
wire in41 = in[47];
wire in42 = in[48];
wire in43 = in[49];
wire in44 = in[50];
wire in45 = in[51];
wire in46 = in[52];
wire in47 = in[53];
wire in48 = in[54];
wire in49 = in[55];
wire in50 = in[56];
wire in51 = in[57];
wire in52 = in[58];
wire in53 = in[59];
wire in54 = in[60];
wire in55 = in[61];
wire in56 = in[62];
wire in57 = in[63];
wire in58 = in[64];
wire in59 = in[65];
wire in60 = in[66];
wire in61 = in[67];
wire in62 = in[68];
wire in63 = in[69];

mux64  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .in8(in8), .in9(in9), .in10(in10), .in11(in11), .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19), .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27), .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .in32(in32), .in33(in33), .in34(in34), .in35(in35), .in36(in36), .in37(in37), .in38(in38), .in39(in39),
  .in40(in40), .in41(in41), .in42(in42), .in43(in43), .in44(in44), .in45(in45), .in46(in46), .in47(in47),
  .in48(in48), .in49(in49), .in50(in50), .in51(in51), .in52(in52), .in53(in53), .in54(in54), .in55(in55),
  .in56(in56), .in57(in57), .in58(in58), .in59(in59), .in60(in60), .in61(in61), .in62(in62), .in63(in63),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4), .s5(s5),
  .outb(out)
);

mux64_behav  REF(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7),
  .in8(in8), .in9(in9), .in10(in10), .in11(in11), .in12(in12), .in13(in13), .in14(in14), .in15(in15),
  .in16(in16), .in17(in17), .in18(in18), .in19(in19), .in20(in20), .in21(in21), .in22(in22), .in23(in23),
  .in24(in24), .in25(in25), .in26(in26), .in27(in27), .in28(in28), .in29(in29), .in30(in30), .in31(in31),
  .in32(in32), .in33(in33), .in34(in34), .in35(in35), .in36(in36), .in37(in37), .in38(in38), .in39(in39),
  .in40(in40), .in41(in41), .in42(in42), .in43(in43), .in44(in44), .in45(in45), .in46(in46), .in47(in47),
  .in48(in48), .in49(in49), .in50(in50), .in51(in51), .in52(in52), .in53(in53), .in54(in54), .in55(in55),
  .in56(in56), .in57(in57), .in58(in58), .in59(in59), .in60(in60), .in61(in61), .in62(in62), .in63(in63),
  .s0(s0), .s1(s1), .s2(s2), .s3(s3), .s4(s4), .s5(s5),
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
  repeat (1 << 12) begin
    #5; 
    check(out, out_exp);
    in[69:64] = $random($$);
    in[63:32] = $random($$);
    in[31:0] = $random($$);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule