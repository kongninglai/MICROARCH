module  decoder4_16_tb;

initial begin
  $vcdplusfile("decoder4_16_tb.dump.vpd");
  $vcdpluson(0, decoder4_16_tb); 
end

localparam INP_WIDTH = 4;
localparam OUT_WIDTH = 16;

reg   [INP_WIDTH-1:0]   SEL;
wire  [2*OUT_WIDTH-1:0] out, out_exp;

decoder4_16 DUT(.SEL(SEL), .Y(out[2*OUT_WIDTH-1:OUT_WIDTH]), .YBAR(out[OUT_WIDTH-1:0]));

decoder4_16_behav REF(.SEL(SEL), .Y(out_exp[2*OUT_WIDTH-1:OUT_WIDTH]), .YBAR(out_exp[OUT_WIDTH-1:0]));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [OUT_WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  SEL = 0;
  repeat (1 << INP_WIDTH) begin
    #40;
    check(out, out_exp);
    SEL = SEL + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule