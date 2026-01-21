module  gen_prop_tb;

initial begin
  $vcdplusfile("gen_prop_tb.dump.vpd");
  $vcdpluson(0, gen_prop_tb); 
end

localparam INP_WIDTH = 2;
localparam OUT_WIDTH = 2;

reg   [INP_WIDTH-1:0]   in;
wire  [OUT_WIDTH-1:0]   out, out_exp;

wire  in0     = in[0];
wire  in1     = in[1];

gen_prop DUT (.gen(out[1]), .prop(out[0]), .in0(in0), .in1(in1));

gen_prop_behav REF (.gen(out_exp[1]), .prop(out_exp[0]), .in0(in0), .in1(in1));

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
  in = 0;
  repeat (1 << INP_WIDTH) begin
    #5; 
    check(out, out_exp);
    in = in + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule