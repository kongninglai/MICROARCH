module reg16e(CLK, Din, Q, QBAR, CLR, PRE,en);
  input  CLK;
  input  CLR;
  input [15:0] Din;
  input  PRE;
  input  en;
  output [15:0] Q;
  output [15:0] QBAR;

  wire  [15:0] D;
  mux2$ mux2_reg16e[15:0](D, Q, Din, en);
  dff16$ dff16_reg16e(CLK, D, Q, QBAR, CLR, PRE);
endmodule