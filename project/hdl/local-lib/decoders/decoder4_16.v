module decoder4_16  (
  input    [3:0]  SEL,
  output  [15:0]  Y,YBAR
);

wire  [7:0] Y_low, YBAR_low;

decoder3_8$ decoder3_8$_0(SEL[2:0],Y_low,YBAR_low);

mux2$       mux2$_0[7:0] ( Y[7:0], Y_low, 8'd0, SEL[3]);
mux2$       mux2$_1[15:8](Y[15:8], 8'd0, Y_low, SEL[3]);

mux2$       mux2$_2[7:0] ( YBAR[7:0], YBAR_low, 8'hFF, SEL[3]);
mux2$       mux2$_3[15:8](YBAR[15:8], 8'hFF, YBAR_low, SEL[3]);

endmodule