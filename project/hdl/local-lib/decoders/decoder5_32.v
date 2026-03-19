module decoder5_32  (
  input    [4:0]  SEL,
  output  [31:0]  Y,YBAR
);

wire  [15:0]  Y_low, YBAR_low;

wire          SEL4_buf64;

bufferH64$    bufferH64$_SEL4_buf64(SEL4_buf64, SEL[4]);

decoder4_16   decoder4_16_0(SEL[3:0],Y_low,YBAR_low);

mux2$       mux2$_0[15:0] ( Y[15:0] , Y_low, 16'd0, SEL4_buf64);
mux2$       mux2$_1[31:16]( Y[31:16], 16'd0, Y_low, SEL4_buf64);

mux2$       mux2$_2[15:0] ( YBAR[15:0] , YBAR_low, 16'hFFFF, SEL4_buf64);
mux2$       mux2$_3[31:16]( YBAR[31:16], 16'hFFFF, YBAR_low, SEL4_buf64);

endmodule