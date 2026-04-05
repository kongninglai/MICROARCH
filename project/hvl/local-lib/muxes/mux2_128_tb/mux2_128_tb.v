module  mux2_128_tb;

initial begin
  // $vcdplusfile("mux2_128_tb.dump.vpd");
  // $vcdpluson(0, mux2_128_tb); 
end


reg [127:0] in0, in1;
reg s0;
wire [127:0] out;

wire [127:0] out_bh;

mux2_128  DUT(
  .in0(in0), .in1(in1), .s0(s0), .out(out)
);

mux2_128_behav  REF(
  .in0(in0), .in1(in1), .s0(s0), .out(out_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task apply;
    input [127:0] test_in0, test_in1;
    input test_s0;
    begin 
        in0 = test_in0;
        in1 = test_in1;
        s0 = test_s0;
    end
endtask

task check;
  input [127:0] Y, Y_bh;
  if (Y !== Y_bh) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. Y_bh = %h, Y = %h\n", 
              $time, Y_bh, Y);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  // 1 << 8 is 256 random test cases. 
  repeat (1 << 8) begin
    
    apply(
        {$random, $random, $random, $random}, // Arg 1: 128-bit random for in0
        {$random, $random, $random, $random}, // Arg 2: 128-bit random for in1
        $random                               // Arg 3: 1-bit random for s0
    );
    
    #1.5; 
    check(out, out_bh);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule