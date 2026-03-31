module  gen_prop_2_tb;

initial begin
  // $vcdplusfile("gen_prop_2_tb.dump.vpd");
  // $vcdpluson(0, gen_prop_2_tb); 
end

localparam INP_WIDTH = 4;
localparam OUT_WIDTH = 2;

reg   [INP_WIDTH-1:0]   in;
wire  [OUT_WIDTH-1:0]   out, out_exp;

wire  Pi_k    = in[0];
wire  Pkm1_j  = in[1];
wire  Gi_k    = in[2];
wire  Gkm1_j  = in[3];

gen_prop_2 DUT (.Gi_j(out[1]), .Pi_j(out[0]), .Pi_k(Pi_k), .Pkm1_j(Pkm1_j), .Gi_k(Gi_k), .Gkm1_j(Gkm1_j));

gen_prop_2_behav REF (.Gi_j(out_exp[1]), .Pi_j(out_exp[0]), .Pi_k(Pi_k), .Pkm1_j(Pkm1_j), .Gi_k(Gi_k), .Gkm1_j(Gkm1_j));

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