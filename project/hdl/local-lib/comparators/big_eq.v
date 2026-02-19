module big_eq #(
  parameter WIDTH=32
) (
  input     [31:0]    in0, in1,
  output              eq
);

wire		[31:0]	in;
	
// xnor2$(out, in0, in1);
xnor2$	xnor2$_0[31:0](in, in0, in1);

generate
  case (WIDTH)
    1: begin
      assign eq = in[0];
    end
    2: begin
      and2$ and_0_0(eq,in[0],in[1]);
    end
    3: begin
      and3$ and_0_0(eq,in[0],in[1],in[2]);
    end
    4: begin
      and4$ and_0_0(eq,in[0],in[1],in[2],in[3]);
    end
    5: begin
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and2$ and_0_1(and_0_1_out,in[3],in[4]);
      assign eq = and_0_0_out;
    end
    6: begin
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and3$ and_0_1(and_0_1_out,in[3],in[4],in[5]);
      assign eq = and_0_0_out;
    end
    7: begin
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and4$ and_0_1(and_0_1_out,in[3],in[4],in[5],in[6]);
      assign eq = and_0_0_out;
    end
    8: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,in[0],in[1]);
      and4$ and_0_1(and_0_1_out,in[2],in[3],in[4],in[5]);
      and2$ and_0_2(and_0_2_out,in[6],in[7]);
      assign eq = and_0_0_out;
    end
    9: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,in[0],in[1]);
      and4$ and_0_1(and_0_1_out,in[2],in[3],in[4],in[5]);
      and3$ and_0_2(and_0_2_out,in[6],in[7],in[8]);
      assign eq = and_0_0_out;
    end
    10: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,in[0],in[1]);
      and4$ and_0_1(and_0_1_out,in[2],in[3],in[4],in[5]);
      and4$ and_0_2(and_0_2_out,in[6],in[7],in[8],in[9]);
      assign eq = and_0_0_out;
    end
    11: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,in[0]);
      and4$ and_0_1(and_0_1_out,in[1],in[2],in[3],in[4]);
      and4$ and_0_2(and_0_2_out,in[5],in[6],in[7],in[8]);
      and2$ and_0_3(and_0_3_out,in[9],in[10]);
      assign eq = and_0_0_out;
    end
    12: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,in[0]);
      and4$ and_0_1(and_0_1_out,in[1],in[2],in[3],in[4]);
      and4$ and_0_2(and_0_2_out,in[5],in[6],in[7],in[8]);
      and3$ and_0_3(and_0_3_out,in[9],in[10],in[11]);
      assign eq = and_0_0_out;
    end
    13: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,in[0]);
      and4$ and_0_1(and_0_1_out,in[1],in[2],in[3],in[4]);
      and4$ and_0_2(and_0_2_out,in[5],in[6],in[7],in[8]);
      and4$ and_0_3(and_0_3_out,in[9],in[10],in[11],in[12]);
      assign eq = and_0_0_out;
    end
    14: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and2$ and_0_4(and_0_4_out,in[12],in[13]);
      assign eq = and_0_0_out;
    end
    15: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and3$ and_0_4(and_0_4_out,in[12],in[13],in[14]);
      assign eq = and_0_0_out;
    end
    16: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],in[15]);
      assign eq = and_0_0_out;
    end
    17: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and2$ and_0_5(and_0_5_out,in[15],in[16]);
      assign eq = and_0_0_out;
    end
    18: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and3$ and_0_5(and_0_5_out,in[15],in[16],in[17]);
      assign eq = and_0_0_out;
    end
    19: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,in[15],in[16],in[17],in[18]);
      assign eq = and_0_0_out;
    end
    20: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,in[15],in[16],in[17]);
      and2$ and_0_6(and_0_6_out,in[18],in[19]);
      assign eq = and_0_0_out;
    end
    21: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,in[15],in[16],in[17]);
      and3$ and_0_6(and_0_6_out,in[18],in[19],in[20]);
      assign eq = and_0_0_out;
    end
    22: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,in[15],in[16],in[17]);
      and4$ and_0_6(and_0_6_out,in[18],in[19],in[20],in[21]);
      assign eq = and_0_0_out;
    end
    23: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,in[15],in[16]);
      and4$ and_0_6(and_0_6_out,in[17],in[18],in[19],in[20]);
      and2$ and_0_7(and_0_7_out,in[21],in[22]);
      assign eq = and_0_0_out;
    end
    24: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,in[15],in[16]);
      and4$ and_0_6(and_0_6_out,in[17],in[18],in[19],in[20]);
      and3$ and_0_7(and_0_7_out,in[21],in[22],in[23]);
      assign eq = and_0_0_out;
    end
    25: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,in[15],in[16]);
      and4$ and_0_6(and_0_6_out,in[17],in[18],in[19],in[20]);
      and4$ and_0_7(and_0_7_out,in[21],in[22],in[23],in[24]);
      assign eq = and_0_0_out;
    end
    26: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,in[15]);
      and4$ and_0_6(and_0_6_out,in[16],in[17],in[18],in[19]);
      and4$ and_0_7(and_0_7_out,in[20],in[21],in[22],in[23]);
      and2$ and_0_8(and_0_8_out,in[24],in[25]);
      assign eq = and_0_0_out;
    end
    27: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,in[15]);
      and4$ and_0_6(and_0_6_out,in[16],in[17],in[18],in[19]);
      and4$ and_0_7(and_0_7_out,in[20],in[21],in[22],in[23]);
      and3$ and_0_8(and_0_8_out,in[24],in[25],in[26]);
      assign eq = and_0_0_out;
    end
    28: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,in[15]);
      and4$ and_0_6(and_0_6_out,in[16],in[17],in[18],in[19]);
      and4$ and_0_7(and_0_7_out,in[20],in[21],in[22],in[23]);
      and4$ and_0_8(and_0_8_out,in[24],in[25],in[26],in[27]);
      assign eq = and_0_0_out;
    end
    29: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      wire and_0_9_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,and_0_9_out);
      and4$ and_0_6(and_0_6_out,in[15],in[16],in[17],in[18]);
      and4$ and_0_7(and_0_7_out,in[19],in[20],in[21],in[22]);
      and4$ and_0_8(and_0_8_out,in[23],in[24],in[25],in[26]);
      and2$ and_0_9(and_0_9_out,in[27],in[28]);
      assign eq = and_0_0_out;
    end
    30: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      wire and_0_9_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,and_0_9_out);
      and4$ and_0_6(and_0_6_out,in[15],in[16],in[17],in[18]);
      and4$ and_0_7(and_0_7_out,in[19],in[20],in[21],in[22]);
      and4$ and_0_8(and_0_8_out,in[23],in[24],in[25],in[26]);
      and3$ and_0_9(and_0_9_out,in[27],in[28],in[29]);
      assign eq = and_0_0_out;
    end
    31: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      wire and_0_9_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,and_0_9_out);
      and4$ and_0_6(and_0_6_out,in[15],in[16],in[17],in[18]);
      and4$ and_0_7(and_0_7_out,in[19],in[20],in[21],in[22]);
      and4$ and_0_8(and_0_8_out,in[23],in[24],in[25],in[26]);
      and4$ and_0_9(and_0_9_out,in[27],in[28],in[29],in[30]);
      assign eq = and_0_0_out;
    end
    32: begin
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      wire and_0_3_out;
      wire and_0_4_out;
      wire and_0_5_out;
      wire and_0_6_out;
      wire and_0_7_out;
      wire and_0_8_out;
      wire and_0_9_out;
      wire and_0_10_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,and_0_3_out,and_0_4_out);
      and4$ and_0_1(and_0_1_out,in[0],in[1],in[2],in[3]);
      and4$ and_0_2(and_0_2_out,in[4],in[5],in[6],in[7]);
      and4$ and_0_3(and_0_3_out,in[8],in[9],in[10],in[11]);
      and4$ and_0_4(and_0_4_out,in[12],in[13],in[14],and_0_5_out);
      and4$ and_0_5(and_0_5_out,and_0_6_out,and_0_7_out,and_0_8_out,and_0_9_out);
      and4$ and_0_6(and_0_6_out,in[15],in[16],in[17],in[18]);
      and4$ and_0_7(and_0_7_out,in[19],in[20],in[21],in[22]);
      and4$ and_0_8(and_0_8_out,in[23],in[24],in[25],in[26]);
      and4$ and_0_9(and_0_9_out,in[27],in[28],in[29],and_0_10_out);
      and2$ and_0_10(and_0_10_out,in[30],in[31]);
      assign eq = and_0_0_out;
    end
  endcase
endgenerate



endmodule