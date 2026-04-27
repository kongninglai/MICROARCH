module HA_4b_tb;

initial begin
  $vcdplusfile("HA_4b_tb.dump.vpd");
  $vcdpluson(0, HA_4b_tb); 
end

localparam WIDTH = 4;

reg   [2*WIDTH-1:0] in_long;

wire  [WIDTH-1:0]   out, out_exp;
wire                cout, cout_exp;

wire  [WIDTH-1:0]   in0 = in_long[WIDTH-1:0];
wire  [WIDTH-1:0]   in1 = in_long[2*WIDTH-1:WIDTH];

HA_4b DUT(
  .s(out),
  .cout(cout),
  .in0(in0),
  .in1(in1)
);

HA_4b_behav REF(
  .s(out_exp),
  .cout(cout_exp),
  .in0(in0),
  .in1(in1)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
  input cout, cout_exp;

  begin
    if ((out !== out_exp) || (cout !== cout_exp)) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t", $time);
      $display("exp: s=%h cout=%b | got: s=%h cout=%b",
                out_exp, cout_exp, out, cout);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

integer i, j;

initial begin

  in_long = {4'd7, 4'd0};
  #5;
  check(out, out_exp, cout, cout_exp);

  in_long = {4'd7, 4'd1};
  #5;
  check(out, out_exp, cout, cout_exp);

  for (i = 0; i < 16; i = i + 1) begin
    for (j = 0; j < 16; j = j + 1) begin
      in_long = {i[3:0], j[3:0]};
      #5;
      check(out, out_exp, cout, cout_exp);
    end
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule