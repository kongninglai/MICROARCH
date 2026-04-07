module  SUB_32b_tb;

initial begin
  // $vcdplusfile("SUB_32b_tb.dump.vpd");
  // $vcdpluson(0, SUB_32b_tb); 
end

localparam WIDTH = 32;

reg   [2*WIDTH-1:0] in_long;
wire  [2*WIDTH-1:0] out, out_exp;

wire  [WIDTH-1:0]   in0   = in_long[WIDTH-1:0];
wire  [WIDTH-1:0]   in1   = in_long[2*WIDTH-1:WIDTH];
reg cin;

SUB_32b DUT(.s(out[2*WIDTH-1:WIDTH]), .cout(out[WIDTH-1:0]), .cin(cin), .in0(in0), .in1(in1));

SUB_32b_behav REF(.s(out_exp[2*WIDTH-1:WIDTH]), .cout(out_exp[WIDTH-1:0]), .cin(cin), .in0(in0), .in1(in1));

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [2*WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    // $display("SUCCESS AT TIME %t. in0 = %h, in1 = %h, out_exp=%h, cout_exp=%h\n", 
    //           $time, in0, in1, out_exp[2*WIDTH-1:WIDTH], out_exp[WIDTH-1:0]);
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  in_long = {32'h00000000, 32'h00000000}; cin=1'b0; #40; check(out, out_exp);
  in_long = {32'h00000005, 32'h00000003}; cin=1'b0; #40; check(out, out_exp);
  in_long = {32'h00000003, 32'h00000005}; cin=1'b0; #40; check(out, out_exp);
  in_long = {32'h00000001, 32'h7FFFFFFF}; cin=1'b0; #40; check(out, out_exp);
  in_long = {32'h00000001, 32'h80000000}; cin=1'b0; #40; check(out, out_exp);
  in_long = {32'h00000001, 32'h00001000}; cin=1'b0; #40; check(out, out_exp);
  in_long = 0;
  cin = 1'b0;
  repeat (1 << 9) begin
    #40;
    check(out, out_exp);
    in_long[WIDTH-1:0]        = $random;
    in_long[2*WIDTH-1:WIDTH]  = $random;
    cin = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule