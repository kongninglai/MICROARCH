module  dff32_tb;

initial begin
  $vcdplusfile("dff32_tb.dump.vpd");
  $vcdpluson(0, dff32_tb); 
end

reg    [3:0]  WE, CLR;
reg           PRE;
reg   [31:0]  D;
wire  [31:0]  Q, QBAR;

reg   [31:0]  D_val;

localparam CYCLE_TIME    = 10;
localparam CYCLES_LOW    = 1;
localparam CYCLES_VALID  = 1;

dff32 DUT(
  .WE(WE), .CLR(CLR), .D(D), .PRE(PRE),
  .Q(Q), .QBAR(QBAR)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

reg clk;
initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2.0) clk = ~clk;
  end
end

task check;
  input [31:0] Q_exp;
  begin
    if (Q !== Q_exp) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. Q_exp = %h, Q = %h\n", 
                $time, Q_exp, Q);
    end else begin
      SUCCESSES = SUCCESSES + 1;
      // $display("SUCCESS AT TIME %t. Q_exp = %h, Q = %h\n", 
      //           $time, Q_exp, Q);
    end
  end
endtask

integer i;

initial begin
  D_val     <= 32'd1;
  CLR       <= 4'hF;
  PRE       <= 1'b1;
  WE        <= 4'hF;
  #(CYCLE_TIME);
  CLR       <= 4'h0;
  #(CYCLE_TIME);
  CLR       <= 4'hF;
  #(0.5*CYCLE_TIME);

  for (i = 0; i < 32; i = i + 1) begin

    D         <= D_val;
    WE        <= 4'h0;

    #(CYCLES_LOW * CYCLE_TIME);
    WE        <= 4'hF;

    #(CYCLES_VALID * CYCLE_TIME);
    check(D_val);
    D_val     =  D_val << 1;
  end

  CLR       <= 4'h0;
  D_val     <= 32'd1;
  #(CYCLES_LOW * CYCLE_TIME);
  CLR       <= 4'hF;

  for (i = 0; i < 32; i = i + 1) begin

    D         <= D_val;
    WE        <= 4'hE;

    #(CYCLES_LOW * CYCLE_TIME);
    WE        <= 4'hF;

    #(CYCLES_VALID * CYCLE_TIME);
    check(D_val & 32'h000000FF);
    D_val     =  D_val << 1;
  end

  CLR       <= 4'h0;
  D_val     <= 32'd1;
  #(CYCLES_LOW * CYCLE_TIME);
  CLR       <= 4'hF;

  for (i = 0; i < 32; i = i + 1) begin

    D         <= D_val;
    WE        <= 4'hD;

    #(CYCLES_LOW * CYCLE_TIME);
    WE        <= 4'hF;

    #(CYCLES_VALID * CYCLE_TIME);
    check(D_val & 32'h0000FF00);
    D_val     =  D_val << 1;
  end

  CLR       <= 4'h0;
  D_val     <= 32'd1;
  #(CYCLES_LOW * CYCLE_TIME);
  CLR       <= 4'hF;

  for (i = 0; i < 32; i = i + 1) begin

    D         <= D_val;
    WE        <= 4'hB;

    #(CYCLES_LOW * CYCLE_TIME);
    WE        <= 4'hF;

    #(CYCLES_VALID * CYCLE_TIME);
    check(D_val & 32'h00FF0000);
    D_val     =  D_val << 1;
  end

  CLR       <= 4'h0;
  D_val     <= 32'd1;
  #(CYCLES_LOW * CYCLE_TIME);
  CLR       <= 4'hF;

  for (i = 0; i < 32; i = i + 1) begin

    D         <= D_val;
    
    WE        <= 4'h7;

    #(CYCLES_LOW * CYCLE_TIME);
    WE        <= 4'hF;

    #(CYCLES_VALID * CYCLE_TIME);
    check(D_val & 32'hFF000000);
    D_val     =  D_val << 1;
  end

  #(10*CYCLE_TIME);

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule
