module  neq_6b_tb;

initial begin
  $vcdplusfile("neq_6b_tb.dump.vpd");
  $vcdpluson(0, neq_6b_tb); 
end

localparam WIDTH = 6;

reg   [2*WIDTH-1:0] in_long;
wire                out, out_exp;

wire in0 = in_long[WIDTH-1:0];
wire in1 = in_long[2*WIDTH-1:WIDTH];

neq_6b DUT(.in0(in0), .in1(in1), .neq(out));

neq_6b_behav REF(.in0(in0), .in1(in1), .neq(out_exp));

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