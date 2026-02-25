module dff32 #(
  parameter CYCLES_LOW    = 1,
  parameter CYCLES_VALID  = 1
) (
  input    [3:0]  WE, CLR,
  input   [31:0]  D, 
  input           PRE,
  
  output  [31:0]  Q, QBAR
);

dff8$  dff8$_3(.CLK(WE[3]), .D(D[31:24]), .Q(Q[31:24]), .QBAR(QBAR[31:24]), .CLR(CLR[3]), .PRE(PRE));
dff8$  dff8$_2(.CLK(WE[2]), .D(D[23:16]), .Q(Q[23:16]), .QBAR(QBAR[23:16]), .CLR(CLR[2]), .PRE(PRE));
dff8$  dff8$_1(.CLK(WE[1]), .D(D[15:8]),  .Q(Q[15:8]),  .QBAR(QBAR[15:8]),  .CLR(CLR[1]), .PRE(PRE));
dff8$  dff8$_0(.CLK(WE[0]), .D(D[7:0]),   .Q(Q[7:0]),   .QBAR(QBAR[7:0]),   .CLR(CLR[0]), .PRE(PRE));

endmodule