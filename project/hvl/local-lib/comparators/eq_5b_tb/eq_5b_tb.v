module  eq_5b_tb;

initial begin
  $vcdplusfile("eq_5b_tb.dump.vpd");
  $vcdpluson(0, eq_5b_tb); 
end

localparam WIDTH = 5;

reg   [2*WIDTH-1:0] in_long;
wire                out, out_exp;

wire in0 = in_long[WIDTH-1:0];
wire in1 = in_long[2*WIDTH-1:WIDTH];

eq_5b DUT(.in0(in0), .in1(in1), .eq(out));

eq_5b_behav REF(.in0(in0), .in1(in1), .eq(out_exp));

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
  
  in_long = 0;
  repeat (1 << (2*WIDTH)) begin
    #40;
    check(out, out_exp);
    in_long = in_long + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule