/* CAUTION: This is NOT exactly a priority encoder. It has undefined behavior
   if multiple bits of in[3:0] are set. It will deassert valid when in[3:0] == 4'b0000 */

/* AUTO GENERATED COMBINATIONAL LOGIC */
module encoder4_2(in,out,valid);

/* I/Os */
input [3:0] in;
output [1:0] out;
output valid;

/* Inverters */
wire in0_bar;
inv1$ inv_0(in0_bar, in[0]);
wire in1_bar;
inv1$ inv_1(in1_bar, in[1]);
wire in2_bar;
inv1$ inv_2(in2_bar, in[2]);
wire in3_bar;
inv1$ inv_3(in3_bar, in[3]);

/* Product Expressions */
wire nand_0_0_0_out;
nand4$ nand_0_0_0(nand_0_0_0_out,in3_bar,in[2],in1_bar,in0_bar);
wire nand_1_0_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,in3_bar,in2_bar,in[1],in0_bar);
wire nand_2_0_0_out;
nand4$ nand_2_0_0(nand_2_0_0_out,in3_bar,in2_bar,in1_bar,in[0]);
wire nand_3_0_0_out;
nand4$ nand_3_0_0(nand_3_0_0_out,in[3],in2_bar,in1_bar,in0_bar);

/* Sum Expressions */
nand2$ nand_0_0_1(out[1],nand_0_0_0_out,nand_3_0_0_out);
nand2$ nand_1_0_1(out[0],nand_1_0_0_out,nand_3_0_0_out);
nand4$ nand_2_0_1(valid,nand_0_0_0_out,nand_1_0_0_out,nand_2_0_0_out,nand_3_0_0_out);

endmodule