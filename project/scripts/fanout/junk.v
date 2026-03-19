module nand2$(out, in0, in1); input in0,in1; output out; endmodule
module nand3$(out, in0, in1, in2); input in0,in1,in2; output out; endmodule
module nand4$(out, in0, in1, in2, in3); input in0,in1,in2,in3; output out; endmodule

module and2$(out, in0, in1); input in0,in1; output out; endmodule
module and3$(out, in0, in1, in2); input in0,in1,in2; output out; endmodule
module and4$(out, in0, in1, in2, in3); input in0,in1,in2,in3; output out; endmodule

module nor2$(out, in0, in1); input in0,in1; output out; endmodule
module nor3$(out, in0, in1, in2); input in0,in1,in2; output out; endmodule
module nor4$(out, in0, in1, in2, in3); input in0,in1,in2,in3; output out; endmodule

module or2$(out, in0, in1); input in0,in1; output out; endmodule
module or3$(out, in0, in1, in2); input in0,in1,in2; output out; endmodule
module or4$(out, in0, in1, in2, in3); input in0,in1,in2,in3; output out; endmodule

module xor2$(out, in0, in1); input in0,in1; output out; endmodule
module xnor2$(out, in0, in1); input in0,in1; output out; endmodule

module inv1$(out, in); input in; output out; endmodule

module dff$(clk,d,q,qbar,r,s);
input clk,d,r,s; output q,qbar;
endmodule

module dff8$(CLK,D,Q,QBAR,CLR,PRE);
input CLK,CLR,PRE; input [7:0] D;
output [7:0] Q,QBAR;
endmodule

module dff16$(CLK,D,Q,QBAR,CLR,PRE);
input CLK,CLR,PRE; input [15:0] D;
output [15:0] Q,QBAR;
endmodule

module jkff8$(CLK,CLR,J,K,PRE,Q,QBAR);
input CLK,CLR,PRE; input [7:0] J,K;
output [7:0] Q,QBAR;
endmodule

module jkff16$(CLK,CLR,J,K,PRE,Q,QBAR);
input CLK,CLR,PRE; input [15:0] J,K;
output [15:0] Q,QBAR;
endmodule

module buffer$(out,in); input in; output out; endmodule
module buffer8$(out,in); input [7:0] in; output [7:0] out; endmodule
module buffer16$(out,in); input [15:0] in; output [15:0] out; endmodule

module bufferH16$(out,in); input in; output out; endmodule
module bufferH64$(out,in); input in; output out; endmodule
module bufferH256$(out,in); input in; output out; endmodule
module bufferH1024$(out,in); input in; output out; endmodule
module bufferH4096$(out,in); input in; output out; endmodule

module bufferHInv16$(out,in); input in; output out; endmodule
module bufferHInv64$(out,in); input in; output out; endmodule
module bufferHInv256$(out,in); input in; output out; endmodule
module bufferHInv1024$(out,in); input in; output out; endmodule
module bufferHInv4096$(out,in); input in; output out; endmodule

module latch$(d,en,q,qbar,r,s);
input d,en,r,s; output q,qbar;
endmodule

module latch8$(CLR,D,EN,PRE,Q);
input CLR,EN,PRE; input [7:0] D;
output [7:0] Q;
endmodule

module latch16$(CLR,D,EN,PRE,Q);
input CLR,EN,PRE; input [15:0] D;
output [15:0] Q;
endmodule


module tristateL$(enbar,in,out);
input enbar,in; output out; endmodule

module tristate8L$(enbar,in,out);
input enbar; input [7:0] in; output [7:0] out; endmodule

module tristate16L$(enbar,in,out);
input enbar; input [15:0] in; output [15:0] out; endmodule

module tristateH$(enbar,in,out);
input enbar,in; output out; endmodule

module tristate8H$(enbar,in,out);
input enbar; input [7:0] in; output [7:0] out; endmodule

module tristate16H$(enbar,in,out);
input enbar; input [15:0] in; output [15:0] out; endmodule

module tristate_bus_driver1$(enbar,in,out);
input enbar,in; output out; endmodule

module tristate_bus_driver8$(enbar,in,out);
input enbar; input [7:0] in; output [7:0] out; endmodule

module tristate_bus_driver16$(enbar,in,out);
input enbar; input [15:0] in; output [15:0] out; endmodule



module dff16b$(CLK,D,Q,QBAR,CLR,PRE,A);
input CLK,CLR,PRE; input [15:0] D; input [3:0] A;
output [15:0] Q,QBAR;
endmodule

module dff32b$(CLK,D,Q,QBAR,CLR,PRE,A);
input CLK,CLR,PRE; input [31:0] D; input [4:0] A;
output [31:0] Q,QBAR;
endmodule

module reg64e$(CLK,Din,Q,QBAR,CLR,PRE,en);
input CLK,CLR,PRE,en; input [63:0] Din;
output [63:0] Q,QBAR;
endmodule

module reg32e$(CLK,Din,Q,QBAR,CLR,PRE,en);
input CLK,CLR,PRE,en; input [31:0] Din;
output [31:0] Q,QBAR;
endmodule

module ioreg8$(CLK,D,Q,QBAR,CLR,PRE);
input CLK,CLR,PRE; input [7:0] D;
output [7:0] Q,QBAR;
endmodule

module ioreg16$(CLK,D,Q,QBAR,CLR,PRE);
input CLK,CLR,PRE; input [15:0] D;
output [15:0] Q,QBAR;
endmodule


module regfile$(IN0,R1,R2,RE1,RE2,W,WE,OUT1,OUT2,CLOCK);
input [7:0] IN0;
input [3:0] R1,R2,W;
input RE1,RE2,WE,CLOCK;
output [7:0] OUT1,OUT2;
endmodule

module regfile8x8$(IN0,R1,R2,RE1,RE2,W,WE,OUT1,OUT2,CLOCK);
input [7:0] IN0;
input [2:0] R1,R2,W;
input RE1,RE2,WE,CLOCK;
output [7:0] OUT1,OUT2;
endmodule


module ram8b8w$(A,DIN,OE,WR,DOUT);
input [2:0] A; input [7:0] DIN;
input OE,WR; output [7:0] DOUT;
endmodule

module ram16b8w$(A,DIN,OE,WRH,WRL,DOUT);
input [2:0] A; input [15:0] DIN;
input OE,WRH,WRL; output [15:0] DOUT;
endmodule

module ram8b4w$(A,DIN,OE,WR,DOUT);
input [1:0] A; input [7:0] DIN;
input OE,WR; output [7:0] DOUT;
endmodule

module rom4b32w$(A,OE,DOUT);
input [4:0] A; input OE;
output [3:0] DOUT;
endmodule

module rom32b32w$(A,OE,DOUT);
input [4:0] A; input OE;
output [31:0] DOUT;
endmodule

module rom64b32w$(A,OE,DOUT);
input [4:0] A; input OE;
output [63:0] DOUT;
endmodule


module mux2$(outb,in0,in1,s0);
input in0,in1,s0; output outb; endmodule

module mux3$(outb,in0,in1,in2,s0,s1);
input in0,in1,in2,s0,s1; output outb; endmodule

module mux4$(outb,in0,in1,in2,in3,s0,s1);
input in0,in1,in2,in3,s0,s1; output outb; endmodule


module mux2_8$(Y,IN0,IN1,S0);
input [7:0] IN0,IN1; input S0; output [7:0] Y; endmodule

module mux2_16$(Y,IN0,IN1,S0);
input [15:0] IN0,IN1; input S0; output [15:0] Y; endmodule

module mux3_8$(Y,IN0,IN1,IN2,S0,S1);
input [7:0] IN0,IN1,IN2; input S0,S1; output [7:0] Y; endmodule

module mux3_16$(Y,IN0,IN1,IN2,S0,S1);
input [15:0] IN0,IN1,IN2; input S0,S1; output [15:0] Y; endmodule

module mux4_8$(Y,IN0,IN1,IN2,IN3,S0,S1);
input [7:0] IN0,IN1,IN2,IN3; input S0,S1; output [7:0] Y; endmodule

module mux4_16$(Y,IN0,IN1,IN2,IN3,S0,S1);
input [15:0] IN0,IN1,IN2,IN3; input S0,S1; output [15:0] Y; endmodule


module decoder2_4$(SEL,Y,YBAR);
input [1:0] SEL; output [3:0] Y,YBAR; endmodule

module decoder3_8$(SEL,Y,YBAR);
input [2:0] SEL; output [7:0] Y,YBAR; endmodule

module syn_cntr8$(CLK,CLR,D,EN,PRE,PL,UP,COUT,Q);
input CLK,CLR,EN,PRE,PL,UP; input [7:0] D;
output COUT; output [7:0] Q;
endmodule

module pencoder8_3v$(enbar,X,Y,valid);
input enbar; input [7:0] X;
output [2:0] Y; output valid;
endmodule

module pencoder8_3$(enbar,X,Y);
input enbar; input [7:0] X;
output [2:0] Y;
endmodule

module mag_comp8$(A,B,AGB,BGA);
input [7:0] A,B; output AGB,BGA;
endmodule

module mag_comp4$(A,B,AGB,BGA);
input [3:0] A,B; output AGB,BGA;
endmodule

module alu4$(a,b,cin,m,s,cout,out);
input [3:0] a,b,s; input cin,m;
output cout; output [3:0] out;
endmodule


module sram128x8$(A,DIO,OE,WR,CE);
input [6:0] A; inout [7:0] DIO;
input OE,WR,CE;
endmodule

module sram32x8$(A,DIO,OE,WR,CE);
input [4:0] A; inout [7:0] DIO;
input OE,WR,CE;
endmodule

module sram32x16$(A,DIO,OE,WRH,WRL,CE);
input [4:0] A; inout [15:0] DIO;
input OE,WRH,WRL,CE;
endmodule

module sram32x32$(A,DIO,OE,WR,CE);
input [4:0] A; inout [31:0] DIO;
input OE,WR,CE;
endmodule

module dma_disk_buffer (
  input              clk, rst, start_xfer,
  input      [31:0]  disk_addr, start_mem_addr,
  input      [7:0]   buf_addr,

  output reg         buf_valid,
  output reg         busy,

  output     [127:0] buf_data
);
endmodule