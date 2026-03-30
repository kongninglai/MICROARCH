module  seg_limit_tb;

initial begin
  $vcdplusfile("seg_limit_tb.dump.vpd");
  $vcdpluson(0, seg_limit_tb); 
end

localparam WIDTH = 32;

reg   [WIDTH-1:0] in0, in1;
wire out, out_exp;

seg_limit_cmp DUT(.in(in0), .seg_limit(in1), .exception(out));

seg_limit_cmp_bh REF(.in(in0), .seg_limit(in1), .exception(out_exp));

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
  
  in0 = 0; in1 = 1; #40; check(out, out_exp);
  in0 = 1; in1 = 1; #40; check(out, out_exp);
  in0 = 2; in1 = 1; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFE; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFF; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 0; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFF; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 0; in1 = 1;
  repeat (1 << 12) begin
    #40;
    check(out, out_exp);
    in0  = $random;
    if ($random % 10 == 0) begin
      in1  = in0;
    end else begin
      in1  = $random;
    end
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule