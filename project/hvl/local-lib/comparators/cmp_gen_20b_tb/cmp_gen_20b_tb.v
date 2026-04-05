module  cmp_gen_20b_tb;

initial begin
  // $vcdplusfile("cmp_gen_20b_tb.dump.vpd");
  // $vcdpluson(0, cmp_gen_20b_tb); 
end

localparam WIDTH = 20;

reg   [WIDTH-1:0] in0, in1;
wire  [2:0] out, out_exp;

cmp_gen_20b DUT(.in0(in0), .in1(in1), .lt(out[2]), .gt(out[1]), .eq(out[0]));

cmp_gen_20b_behav REF(.in0(in0), .in1(in1), .lt(out_exp[2]), .gt(out_exp[1]), .eq(out_exp[0]));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [2:0] out, out_exp;
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
  in0 = 20'hFFFFE; in1 = 20'hFFFFF; #40; check(out, out_exp);
  in0 = 20'hFFFFF; in1 = 20'hFFFFF; #40; check(out, out_exp);
  in0 = 0; in1 = 20'hFFFFF; #40; check(out, out_exp);
  in0 = 20'hFFFFF; in1 = 20'hFFFFF; #40; check(out, out_exp);
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