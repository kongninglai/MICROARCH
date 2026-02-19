module  big_eq_tb;

initial begin
  $vcdplusfile("big_eq_tb.dump.vpd");
  $vcdpluson(0, big_eq_tb); 
end

localparam WIDTH = 32;

reg   [31:0]  in0, in1;
wire          out, out_exp;

big_eq #(.WIDTH(WIDTH)) DUT(.in0(in0), .in1(in1), .eq(out));

big_eq_behav #(.WIDTH(WIDTH)) REF(.in0(in0), .in1(in1), .eq(out_exp));

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
    // $display("SUCCESS AT TIME %t. out_exp = %h, out = %h\n", 
    //           $time, out_exp, out);
  end
endtask

initial begin
  
  in0 = 0; in1 = 1; #40; check(out, out_exp);
  in0 = 1; in1 = 1; #40; check(out, out_exp);
  in0 = 2; in1 = 1; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFE; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFF; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFF; in1 = 32'h0000FFFF; #40; check(out, out_exp);
  in0 = 32'hFFFFFFFF; in1 = 32'h000000FF; #40; check(out, out_exp);
  in0 = 0; in1 = 32'hFFFFFFFF; #40; check(out, out_exp);
  in0 = 0; in1 = 1;
  repeat (1 << 8) begin
    #40;
    check(out, out_exp);
    in0  = $random;
    in1  = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule