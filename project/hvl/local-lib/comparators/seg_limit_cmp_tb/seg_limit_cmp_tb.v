module seg_limit_cmp_tb;

initial begin
  $vcdplusfile("seg_limit_cmp_tb.dump.vpd");
  $vcdpluson(0, seg_limit_cmp_tb); 
end

reg   [31:0] in;
reg   [19:0] seg_limit;

wire  [0:0] out, out_exp;

seg_limit_cmp DUT(.in(in), .seg_limit(seg_limit), .exception(out));

seg_limit_cmp_behav REF(.in(in), .seg_limit(seg_limit), .exception(out_exp));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [0:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  
  in = 0; seg_limit = 1; #40; check(out, out_exp);
  in = 1; seg_limit = 1; #40; check(out, out_exp);
  in = 2; seg_limit = 1; #40; check(out, out_exp);
  in = 32'h000FFFFE; seg_limit = 20'hFFFFF; #40; check(out, out_exp);
  in = 32'h000FFFFF; seg_limit = 20'hFFFFF; #40; check(out, out_exp);
  in = 0; seg_limit = 20'hFFFFF; #40; check(out, out_exp);
  in = 32'h00100000; seg_limit = 20'hFFFFF; #40; check(out, out_exp);

  in = 0; seg_limit = 1;
  repeat (1 << 16) begin
    #40;
    check(out, out_exp);
    in  = $random;
    if ($random % 10 == 0) begin
      if ($random % 2 == 0) begin
        seg_limit  = in[19:0];
      end else begin
        in = in & 32'h000FFFFF;
      end
    end else begin
      seg_limit  = $random;
    end
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule