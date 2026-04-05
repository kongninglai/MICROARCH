module  lshf_chunks_tb;

initial begin
  // $vcdplusfile("lshf_chunks_tb.dump.vpd");
  // $vcdpluson(0, lshf_chunks_tb); 
end

localparam WIDTH = 256;
localparam SHF_ZEROS = 0;

reg   [WIDTH-1:0]   in;
wire  [WIDTH-1:0]   out, out_exp;

lshf_chunks #(.SHF_AMT(8), .SHF_ZEROS(SHF_ZEROS))  DUT (
  .in(in),
  .out(out)
);

lshf_chunks_behav #(.SHF_AMT(8), .SHF_ZEROS(SHF_ZEROS)) REF (
  .in(in),
  .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
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
  repeat (1 << 12) begin
    #5; 
    check(out, out_exp);
    in = ($random | 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule