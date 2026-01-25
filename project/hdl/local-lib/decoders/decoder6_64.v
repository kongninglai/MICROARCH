module decoder6_64 (
    input   [5:0]   SEL,
    output [63:0]   Y,
    output [63:0]   YBAR
);

wire [15:0] Y_low, Y_high;
wire [15:0] YBAR_low, YBAR_high;

decoder4_16 dec4_16_0 (
  .SEL(SEL[3:0]),
  .Y(Y_low),
  .YBAR(YBAR_low)
);

mux4$ mux4_Y_0 [15:0] (Y[15:0],   Y_low, 16'd0, 16'd0, 16'd0, SEL[4], SEL[5]);
mux4$ mux4_Y_1 [15:0] (Y[31:16],  16'd0, Y_low, 16'd0, 16'd0, SEL[4], SEL[5]);
mux4$ mux4_Y_2 [15:0] (Y[47:32],  16'd0, 16'd0, Y_low, 16'd0, SEL[4], SEL[5]);
mux4$ mux4_Y_3 [15:0] (Y[63:48],  16'd0, 16'd0, 16'd0, Y_low, SEL[4], SEL[5]);

mux4$ mux4_YBAR_0 [15:0] (YBAR[15:0],   YBAR_low, 16'hFFFF, 16'hFFFF, 16'hFFFF, SEL[4], SEL[5]);
mux4$ mux4_YBAR_1 [15:0] (YBAR[31:16],  16'hFFFF, YBAR_low, 16'hFFFF, 16'hFFFF, SEL[4], SEL[5]);
mux4$ mux4_YBAR_2 [15:0] (YBAR[47:32],  16'hFFFF, 16'hFFFF, YBAR_low, 16'hFFFF, SEL[4], SEL[5]);
mux4$ mux4_YBAR_3 [15:0] (YBAR[63:48],  16'hFFFF, 16'hFFFF, 16'hFFFF, YBAR_low, SEL[4], SEL[5]);

endmodule