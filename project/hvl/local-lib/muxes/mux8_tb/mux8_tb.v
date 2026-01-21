module  mux8_tb;

// Dump all waveforms to d_latch.dump.vpd
initial begin
  $vcdplusfile("mux8_tb.dump.vpd");
  $vcdpluson(0, mux8_tb); 
end

localparam IN_WIDTH = 8 + 3;

reg   [IN_WIDTH-1:0]  in;
wire                  out, out_exp;

wire  s0 = in[0];
wire  s1 = in[1];
wire  s2 = in[2];
wire in0 = in[3];
wire in1 = in[4];
wire in2 = in[5];
wire in3 = in[6];
wire in4 = in[7];
wire in5 = in[8];
wire in6 = in[9];
wire in7 = in[10];

mux8  DUT(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2),
  .outb(out)
);

mux8_behav  REF(
  .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), .in6(in6), .in7(in7), .s0(s0), .s1(s1), .s2(s2),
  .outb(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // All possible tests with truth table
  in = 0;
  repeat (1 << IN_WIDTH) begin
    // PS2 version fails at 2.4, cascaded library muxes succeed
    // library 442 fails at 1.4
    #1.5; 
    check(out, out_exp);
    in = in + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule