module big_or #(
  parameter WIDTH=32
) (
  output            out,
  input     [31:0]  in
);

generate
  case (WIDTH)
    1: begin
      assign out = in[0];
    end
    2: begin
      or2$ or_0_0(out,in[0],in[1]);
    end
    3: begin
      or3$ or_0_0(out,in[0],in[1],in[2]);
    end
    4: begin
      or4$ or_0_0(out,in[0],in[1],in[2],in[3]);
    end
    5: begin
      wire or_0_0_out;
      wire or_0_1_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,in[0],in[1],in[2]);
      or2$ or_0_1(or_0_1_out,in[3],in[4]);
      assign out = or_0_0_out;
    end
    6: begin
      wire or_0_0_out;
      wire or_0_1_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,in[0],in[1],in[2]);
      or3$ or_0_1(or_0_1_out,in[3],in[4],in[5]);
      assign out = or_0_0_out;
    end
    7: begin
      wire or_0_0_out;
      wire or_0_1_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,in[0],in[1],in[2]);
      or4$ or_0_1(or_0_1_out,in[3],in[4],in[5],in[6]);
      assign out = or_0_0_out;
    end
    8: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,in[0],in[1]);
      or4$ or_0_1(or_0_1_out,in[2],in[3],in[4],in[5]);
      or2$ or_0_2(or_0_2_out,in[6],in[7]);
      assign out = or_0_0_out;
    end
    9: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,in[0],in[1]);
      or4$ or_0_1(or_0_1_out,in[2],in[3],in[4],in[5]);
      or3$ or_0_2(or_0_2_out,in[6],in[7],in[8]);
      assign out = or_0_0_out;
    end
    10: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,in[0],in[1]);
      or4$ or_0_1(or_0_1_out,in[2],in[3],in[4],in[5]);
      or4$ or_0_2(or_0_2_out,in[6],in[7],in[8],in[9]);
      assign out = or_0_0_out;
    end
    11: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,in[0]);
      or4$ or_0_1(or_0_1_out,in[1],in[2],in[3],in[4]);
      or4$ or_0_2(or_0_2_out,in[5],in[6],in[7],in[8]);
      or2$ or_0_3(or_0_3_out,in[9],in[10]);
      assign out = or_0_0_out;
    end
    12: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,in[0]);
      or4$ or_0_1(or_0_1_out,in[1],in[2],in[3],in[4]);
      or4$ or_0_2(or_0_2_out,in[5],in[6],in[7],in[8]);
      or3$ or_0_3(or_0_3_out,in[9],in[10],in[11]);
      assign out = or_0_0_out;
    end
    13: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,in[0]);
      or4$ or_0_1(or_0_1_out,in[1],in[2],in[3],in[4]);
      or4$ or_0_2(or_0_2_out,in[5],in[6],in[7],in[8]);
      or4$ or_0_3(or_0_3_out,in[9],in[10],in[11],in[12]);
      assign out = or_0_0_out;
    end
    14: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or2$ or_0_4(or_0_4_out,in[12],in[13]);
      assign out = or_0_0_out;
    end
    15: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or3$ or_0_4(or_0_4_out,in[12],in[13],in[14]);
      assign out = or_0_0_out;
    end
    16: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],in[15]);
      assign out = or_0_0_out;
    end
    17: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or2$ or_0_5(or_0_5_out,in[15],in[16]);
      assign out = or_0_0_out;
    end
    18: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or3$ or_0_5(or_0_5_out,in[15],in[16],in[17]);
      assign out = or_0_0_out;
    end
    19: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,in[15],in[16],in[17],in[18]);
      assign out = or_0_0_out;
    end
    20: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,in[15],in[16],in[17]);
      or2$ or_0_6(or_0_6_out,in[18],in[19]);
      assign out = or_0_0_out;
    end
    21: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,in[15],in[16],in[17]);
      or3$ or_0_6(or_0_6_out,in[18],in[19],in[20]);
      assign out = or_0_0_out;
    end
    22: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,in[15],in[16],in[17]);
      or4$ or_0_6(or_0_6_out,in[18],in[19],in[20],in[21]);
      assign out = or_0_0_out;
    end
    23: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,in[15],in[16]);
      or4$ or_0_6(or_0_6_out,in[17],in[18],in[19],in[20]);
      or2$ or_0_7(or_0_7_out,in[21],in[22]);
      assign out = or_0_0_out;
    end
    24: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,in[15],in[16]);
      or4$ or_0_6(or_0_6_out,in[17],in[18],in[19],in[20]);
      or3$ or_0_7(or_0_7_out,in[21],in[22],in[23]);
      assign out = or_0_0_out;
    end
    25: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,in[15],in[16]);
      or4$ or_0_6(or_0_6_out,in[17],in[18],in[19],in[20]);
      or4$ or_0_7(or_0_7_out,in[21],in[22],in[23],in[24]);
      assign out = or_0_0_out;
    end
    26: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,in[15]);
      or4$ or_0_6(or_0_6_out,in[16],in[17],in[18],in[19]);
      or4$ or_0_7(or_0_7_out,in[20],in[21],in[22],in[23]);
      or2$ or_0_8(or_0_8_out,in[24],in[25]);
      assign out = or_0_0_out;
    end
    27: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,in[15]);
      or4$ or_0_6(or_0_6_out,in[16],in[17],in[18],in[19]);
      or4$ or_0_7(or_0_7_out,in[20],in[21],in[22],in[23]);
      or3$ or_0_8(or_0_8_out,in[24],in[25],in[26]);
      assign out = or_0_0_out;
    end
    28: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,in[15]);
      or4$ or_0_6(or_0_6_out,in[16],in[17],in[18],in[19]);
      or4$ or_0_7(or_0_7_out,in[20],in[21],in[22],in[23]);
      or4$ or_0_8(or_0_8_out,in[24],in[25],in[26],in[27]);
      assign out = or_0_0_out;
    end
    29: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      wire or_0_9_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,or_0_9_out);
      or4$ or_0_6(or_0_6_out,in[15],in[16],in[17],in[18]);
      or4$ or_0_7(or_0_7_out,in[19],in[20],in[21],in[22]);
      or4$ or_0_8(or_0_8_out,in[23],in[24],in[25],in[26]);
      or2$ or_0_9(or_0_9_out,in[27],in[28]);
      assign out = or_0_0_out;
    end
    30: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      wire or_0_9_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,or_0_9_out);
      or4$ or_0_6(or_0_6_out,in[15],in[16],in[17],in[18]);
      or4$ or_0_7(or_0_7_out,in[19],in[20],in[21],in[22]);
      or4$ or_0_8(or_0_8_out,in[23],in[24],in[25],in[26]);
      or3$ or_0_9(or_0_9_out,in[27],in[28],in[29]);
      assign out = or_0_0_out;
    end
    31: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      wire or_0_9_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,or_0_9_out);
      or4$ or_0_6(or_0_6_out,in[15],in[16],in[17],in[18]);
      or4$ or_0_7(or_0_7_out,in[19],in[20],in[21],in[22]);
      or4$ or_0_8(or_0_8_out,in[23],in[24],in[25],in[26]);
      or4$ or_0_9(or_0_9_out,in[27],in[28],in[29],in[30]);
      assign out = or_0_0_out;
    end
    32: begin
      wire or_0_0_out;
      wire or_0_1_out;
      wire or_0_2_out;
      wire or_0_3_out;
      wire or_0_4_out;
      wire or_0_5_out;
      wire or_0_6_out;
      wire or_0_7_out;
      wire or_0_8_out;
      wire or_0_9_out;
      wire or_0_10_out;
      or4$ or_0_0(or_0_0_out,or_0_1_out,or_0_2_out,or_0_3_out,or_0_4_out);
      or4$ or_0_1(or_0_1_out,in[0],in[1],in[2],in[3]);
      or4$ or_0_2(or_0_2_out,in[4],in[5],in[6],in[7]);
      or4$ or_0_3(or_0_3_out,in[8],in[9],in[10],in[11]);
      or4$ or_0_4(or_0_4_out,in[12],in[13],in[14],or_0_5_out);
      or4$ or_0_5(or_0_5_out,or_0_6_out,or_0_7_out,or_0_8_out,or_0_9_out);
      or4$ or_0_6(or_0_6_out,in[15],in[16],in[17],in[18]);
      or4$ or_0_7(or_0_7_out,in[19],in[20],in[21],in[22]);
      or4$ or_0_8(or_0_8_out,in[23],in[24],in[25],in[26]);
      or4$ or_0_9(or_0_9_out,in[27],in[28],in[29],or_0_10_out);
      or2$ or_0_10(or_0_10_out,in[30],in[31]);
      assign out = or_0_0_out;
    end
  endcase
endgenerate



endmodule