module encoder4_2_tb;

initial begin
  $vcdplusfile("encoder4_2_tb.dump.vpd");
  $vcdpluson(0, encoder4_2_tb); 
end

localparam IN_WIDTH  = 4;
localparam OUT_WIDTH = 2;

reg  [IN_WIDTH-1:0]  in;
wire [OUT_WIDTH-1:0] out, out_exp;
wire valid, valid_exp;

encoder4_2 DUT(
  .in(in),
  .out(out),
  .valid(valid)
);

encoder4_2_behav REF(
  .in(in),
  .out(out_exp),
  .valid(valid_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [OUT_WIDTH-1:0] out_actual, out_expected;
  input valid_actual, valid_expected;
  integer ones_count;
  begin
    ones_count = in[0] + in[1] + in[2] + in[3];

    if (ones_count > 1) begin
    end else if (ones_count == 0) begin
      if (valid_actual !== valid_expected) begin
        FAILURES = FAILURES + 1;
        $display("FAILURE AT TIME %t", $time);
        $display("  in = %b", in);
        $display("  valid_exp = %b, valid = %b\n", valid_expected, valid_actual);
      end else begin
        SUCCESSES = SUCCESSES + 1;
      end
    end else begin
      if ((out_actual !== out_expected) || (valid_actual !== valid_expected)) begin
        FAILURES = FAILURES + 1;
        $display("FAILURE AT TIME %t", $time);
        $display("  in = %b", in);
        $display("  out_exp = %b, out = %b", out_expected, out_actual);
        $display("  valid_exp = %b, valid = %b\n", valid_expected, valid_actual);
      end else begin
        SUCCESSES = SUCCESSES + 1;
      end
    end
  end
endtask

integer i;

initial begin
  in = 0;
  repeat (1 << IN_WIDTH) begin
    #10;
    check(out, out_exp, valid, valid_exp);
    in = in + 1;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule