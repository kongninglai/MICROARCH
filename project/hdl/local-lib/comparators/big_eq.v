module big_eq #(
  parameter WIDTH=32
) (
  input     [WIDTH-1:0]   in0, in1,
  output                  eq
);

wire		[WIDTH-1:0]	in, in_inv;
	
// xnor2$(out, in0, in1);
xnor2$	xnor2$_0[WIDTH-1:0](in, in0, in1);
xor2$	   xor2$_0[WIDTH-1:0](in_inv, in0, in1);

generate
  case (WIDTH)
    1: begin : width1_gen
      assign eq = in[0];
    end
    2: begin : width2_gen
      // Optimized for logic_disp_size
      nor2$ and_0_0(eq,in_inv[0],in_inv[1]);
    end
    3: begin : width3_gen
      // Optimized for set comparison
      nor3$ and_0_0(eq,in_inv[0],in_inv[1],in_inv[2]);
    end
    4: begin : width4_gen
      and4$ and_0_0(eq,in[0],in[1],in[2],in[3]);
    end
    5: begin : width5_gen
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and2$ and_0_1(and_0_1_out,in[3],in[4]);
      assign eq = and_0_0_out;
    end
    6: begin : width6_gen
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and3$ and_0_1(and_0_1_out,in[3],in[4],in[5]);
      assign eq = and_0_0_out;
    end
    7: begin : width7_gen
      wire and_0_0_out;
      wire and_0_1_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,in[0],in[1],in[2]);
      and4$ and_0_1(and_0_1_out,in[3],in[4],in[5],in[6]);
      assign eq = and_0_0_out;
    end
    8: begin : width8_gen
      // Optimized for cache tag compares
      wire nor_0_0_out;
      wire nand_0_0_out;
      wire nand_0_1_out;
      nor2$   nor_0_0(nor_0_0_out,nand_0_0_out,nand_0_1_out);
      nand4$  nand_0_0(nand_0_0_out,in[0],in[1],in[2],in[3]);
      nand4$  nand_0_1(nand_0_1_out,in[4],in[5],in[6],in[7]);
      assign eq = nor_0_0_out;
    end
    9: begin : width9_gen
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,in[0],in[1]);
      and4$ and_0_1(and_0_1_out,in[2],in[3],in[4],in[5]);
      and3$ and_0_2(and_0_2_out,in[6],in[7],in[8]);
      assign eq = and_0_0_out;
    end
    10: begin : width10_gen
      wire and_0_0_out;
      wire and_0_1_out;
      wire and_0_2_out;
      and4$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out,in[0],in[1]);
      and4$ and_0_1(and_0_1_out,in[2],in[3],in[4],in[5]);
      and4$ and_0_2(and_0_2_out,in[6],in[7],in[8],in[9]);
      assign eq = and_0_0_out;
    end
    11: begin : width11_gen
      // Optimized for physical cache line address compares (mcu row buffer)
      wire nor_0_0_out;
      wire nand_0_0_out;
      wire nand_0_1_out;
      wire nand_0_2_out;
      nor3$  nor_0_0(nor_0_0_out,nand_0_0_out,nand_0_1_out,nand_0_2_out);
      nand4$ nand_0_0(nand_0_0_out,in[1],in[2],in[3],in[4]);
      nand4$ nand_0_1(nand_0_1_out,in[5],in[6],in[7],in[8]);
      nand3$ nand_0_2(nand_0_2_out,in[9],in[10],in[0]);
      assign eq = nor_0_0_out;
    end
    12: begin : width12_gen
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
    13: begin : width13_gen
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
    14: begin : width14_gen
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
    15: begin : width15_gen
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
    16: begin : width16_gen
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
    17: begin : width17_gen
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
    18: begin : width18_gen
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
    19: begin : width19_gen
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
    20: begin : width20_gen
      // Optimized for TLB lookups
      wire nor_0_0_out;
      wire nor_0_1_out;
      wire nor_0_2_out;
      wire nor_0_3_out;
      wire nor_0_4_out;
      wire or_0_0_out;
      wire nand_0_1_out;
      wire nand_0_2_out;
      nor3$   nor_0_0(nor_0_0_out,nand_0_1_out,nand_0_2_out, or_0_0_out);
      nand2$ nand_0_1(nand_0_1_out, nor_0_1_out, nor_0_2_out);
      nand2$ nand_0_2(nand_0_2_out, nor_0_3_out, nor_0_4_out);
      nor4$   nor_0_1(nor_0_1_out,in_inv[0],in_inv[1],in_inv[2],in_inv[3]);
      nor4$   nor_0_2(nor_0_2_out,in_inv[4],in_inv[5],in_inv[6],in_inv[7]);
      nor4$   nor_0_3(nor_0_3_out,in_inv[8],in_inv[9],in_inv[10],in_inv[11]);
      nor4$   nor_0_4(nor_0_4_out,in_inv[12],in_inv[13],in_inv[14],in_inv[15]);
      or4$     or_0_0(or_0_0_out,in_inv[16],in_inv[17],in_inv[18],in_inv[19]);
      assign eq = nor_0_0_out;
    end
    21: begin : width21_gen
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
    22: begin : width22_gen
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
    23: begin : width23_gen
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
    24: begin : width24_gen
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
    25: begin : width25_gen
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
    26: begin : width26_gen
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
    27: begin : width27_gen
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
    28: begin : width28_gen
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
    29: begin : width29_gen
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
    30: begin : width30_gen
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
    31: begin : width31_gen
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
    32: begin : width32_gen
      // Optimized for 32-bit compares
      wire nor_0_0_out;
      wire nor_0_1_out;
      wire nand_0_0_out;
      wire nand_0_1_out;
      wire nand_0_2_out;
      wire nand_0_3_out;
      wire nand_0_4_out;
      wire nand_0_5_out;
      wire nand_0_6_out;
      wire nand_0_7_out;

      and2$   and_eq(eq, nor_0_0_out, nor_0_1_out);
      nor4$   nor_0_0(nor_0_0_out,nand_0_0_out,nand_0_1_out,nand_0_2_out,nand_0_3_out);
      nor4$   nor_0_1(nor_0_1_out,nand_0_4_out,nand_0_5_out,nand_0_6_out,nand_0_7_out);
      nand4$  nand_0_0(nand_0_0_out,in[0],in[1],in[2],in[3]);
      nand4$  nand_0_1(nand_0_1_out,in[4],in[5],in[6],in[7]);
      nand4$  nand_0_2(nand_0_2_out,in[8],in[9],in[10],in[11]);
      nand4$  nand_0_3(nand_0_3_out,in[12],in[13],in[14],in[15]);
      nand4$  nand_0_4(nand_0_4_out,in[16],in[17],in[18],in[19]);
      nand4$  nand_0_5(nand_0_5_out,in[20],in[21],in[22],in[23]);
      nand4$  nand_0_6(nand_0_6_out,in[24],in[25],in[26],in[27]);
      nand4$  nand_0_7(nand_0_7_out,in[28],in[29],in[30],in[31]);
    end
  endcase
endgenerate



endmodule