module  mux2_32_tb;

initial begin
  // $vcdplusfile("mux2_32_tb.dump.vpd");
  // $vcdpluson(0, mux2_32_tb); 
end


reg [31:0] in0, in1;
reg s0;
wire [31:0] out;

wire [31:0] out_bh;

mux2_32  DUT(
  .in0(in0), .in1(in1), .s0(s0), .out(out)
);

mux2_32_behav  REF(
  .in0(in0), .in1(in1), .s0(s0), .out(out_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task apply;
    input [31:0] test_in0, test_in1;
    input test_s0;
    begin 
        in0 = test_in0;
        in1 = test_in1;
        s0 = test_s0;
    end
endtask

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
  // All possible tests with truth table
  repeat (1 << 8) begin
    apply({$random,$random}, {$random,$random}, $random);
    #1.5; 
    check(out, out_bh);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule