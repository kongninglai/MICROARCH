module ioreg32 #(
  parameter CYCLE_TIME    = 10,
  parameter SETUP_D       = 10,
  parameter NEGEDGE_W     = 5,
  parameter CLK_DELAY     = 5,

  parameter CYCLES_STABLE = (SETUP_D    / CYCLE_TIME) + 1,
  parameter CYCLES_LOW    = (NEGEDGE_W  / CYCLE_TIME) + 1,
  parameter CYCLES_VALID  = (CLK_DELAY  / CYCLE_TIME) + 1
) (
  input    [3:0]  WE, CLR,
  input   [31:0]  D, 
  input           PRE,
  
  output  [31:0]  Q, QBAR
);

ioreg8$  ioreg8$_3(.CLK(WE[3]), .D(D[31:24]), .Q(Q[31:24]), .QBAR(QBAR[31:24]), .CLR(CLR[3]), .PRE(PRE));
ioreg8$  ioreg8$_2(.CLK(WE[2]), .D(D[23:16]), .Q(Q[23:16]), .QBAR(QBAR[23:16]), .CLR(CLR[2]), .PRE(PRE));
ioreg8$  ioreg8$_1(.CLK(WE[1]), .D(D[15:8]),  .Q(Q[15:8]),  .QBAR(QBAR[15:8]),  .CLR(CLR[1]), .PRE(PRE));
ioreg8$  ioreg8$_0(.CLK(WE[0]), .D(D[7:0]),   .Q(Q[7:0]),   .QBAR(QBAR[7:0]),   .CLR(CLR[0]), .PRE(PRE));

endmodule