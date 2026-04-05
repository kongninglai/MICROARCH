module  ex_inc_tb;

initial begin
  $vcdplusfile("ex_inc_tb.dump.vpd");
  $vcdpluson(0, ex_inc_tb); 
end

localparam WIDTH = 32;

reg   [WIDTH-1:0]   in;
reg   [1:0]         ds;
reg                 eflags_df;
wire  [WIDTH-1:0]   out, out_exp;

ex_inc DUT(.inc_out(out), .ds(ds), .eflags_df(eflags_df), .inc_in(in));

ex_inc_bh REF(.inc_out(out_exp), .ds(ds), .eflags_df(eflags_df), .inc_in(in));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
  if (out != out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  in = 0; ds=0; eflags_df=0;
  repeat (1 << 12) begin
    #8; 
    check(out, out_exp);
    in = $random;
    ds = $random;
    eflags_df = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule