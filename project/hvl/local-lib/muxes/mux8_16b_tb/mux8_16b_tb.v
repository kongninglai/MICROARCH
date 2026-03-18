module mux8_16b_tb;

initial begin
  $vcdplusfile("mux8_16b_tb.dump.vpd");
  $vcdpluson(0, mux8_16b_tb);
end

localparam WIDTH = 16;

reg [2:0]       in;
reg [WIDTH-1:0] in0 ,
                in1 ,
                in2 ,
                in3 ,
                in4 ,
                in5 ,
                in6 ,
                in7 ;
wire [WIDTH-1:0] out, out_exp;

wire s0 = in[0];
wire s1 = in[1];
wire s2 = in[2];

mux8_16b DUT(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .s0(s0), .s1(s1), .s2(s2),
  .outb(out)
);

mux8_16b_behav REF(
  .in0(in0),  .in1(in1),  .in2(in2),  .in3(in3),
  .in4(in4),  .in5(in5),  .in6(in6),  .in7(in7),
  .s0(s0), .s1(s1), .s2(s2),
  .outb(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input out_val, out_exp_val;
  if (out_val !== out_exp_val) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h", $time, out_exp_val, out_val);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  repeat (1 << 15) begin
    in = 0;
    in0   <= $random;
    in1   <= $random;
    in2   <= $random;
    in3   <= $random;
    in4   <= $random;
    in5   <= $random;
    in6   <= $random;
    in7   <= $random;
    repeat (1 << 4) begin
      #5;
      check(out, out_exp);
      in = in + 3'd1;
    end
  end

  $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule