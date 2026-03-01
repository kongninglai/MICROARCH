module  HA_32b_tb;

initial begin
  $vcdplusfile("HA_32b_tb.dump.vpd");
  $vcdpluson(0, HA_32b_tb); 
end

localparam WIDTH = 32;

reg   [2*WIDTH-1:0] in_long;
wire  [2*WIDTH-1:0] out, out_exp;

wire  [WIDTH-1:0]   in0   = in_long[WIDTH-1:0];
wire  [WIDTH-1:0]   in1   = in_long[2*WIDTH-1:WIDTH];

HA_32b DUT(.s(out[2*WIDTH-1:WIDTH]), .cout(out[WIDTH-1:0]), .in0(in0), .in1(in1));

HA_32b_behav REF(.s(out_exp[2*WIDTH-1:WIDTH]), .cout(out_exp[WIDTH-1:0]), .in0(in0), .in1(in1));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [2*WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  
  in_long = {32'hFFFFFFFF, 32'd0}; #40; check(out, out_exp);
  in_long = {32'hFFFFFFFF, 32'd1}; #40; check(out, out_exp);
  in_long = {32'h7FFFFFFF, 32'd0}; #40; check(out, out_exp);
  in_long = {32'h7FFFFFFF, 32'd1}; #40; check(out, out_exp);
  in_long = {32'h80000000, 32'h80000000}; #40; check(out, out_exp);
  in_long = {32'h2FFFFFFF, 32'h300F0000}; #40; check(out, out_exp);
  in_long = 0;
  repeat (1 << 8) begin
    #40;
    check(out, out_exp);
    in_long[WIDTH-1:0]        = $random;
    in_long[2*WIDTH-1:WIDTH]  = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule