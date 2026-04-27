module mux11_onehot_tb; // Renamed to match 11 inputs

initial begin
  // $vcdplusfile("mux11_onehot_tb.dump.vpd");
  // $vcdpluson(0, mux11_onehot_tb); 
end

reg [10:0] in_sel;
wire [31:0] out, out_exp;

// Hardcoded data inputs (fine for a basic test)
reg [31:0] in0 = 32'd0;
reg [31:0] in1 = 32'd1;
reg [31:0] in2 = 32'd2;
reg [31:0] in3 = 32'd3;
reg [31:0] in4 = 32'd4;
reg [31:0] in5 = 32'd5;
reg [31:0] in6 = 32'd6;
reg [31:0] in7 = 32'd7;
reg [31:0] in8 = 32'd8;
reg [31:0] in9 = 32'd9;
reg [31:0] in10 = 32'd10;

// Structural DUT
mux11_onehot DUT(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), 
    .in6(in6), .in7(in7), .in8(in8), .in9(in9), .in10(in10),
    .out(out)
);

// Behavioral Golden Model
mux11_onehot_tb_behav DUT_behav(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), 
    .in6(in6), .in7(in7), .in8(in8), .in9(in9), .in10(in10),
    .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;
integer i;

task check;
  input [31:0]out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. in_sel = %b, out_exp = %b, out = %b", 
              $time, in_sel, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  $display("Starting One-Hot Mux Test...");
  
  // Initialize to the first one-hot state
  in_sel = 11'b00000000001; 

  // Loop exactly 11 times for 11 one-hot states
  for (i = 0; i < 11; i = i + 1) begin
    #10; // Give logic plenty of time to settle (10ns)
    check(out, out_exp);
    
    // Shift the '1' to the left to test the next select line
    in_sel = in_sel << 1; 
  end

  // Optional: Test the all-zero (no selection) state
  in_sel = 11'b00000000000;
  #10;
  check(out, out_exp);

  $display("\nTEST COMPLETE");
  $display("FAILURES  = %d", FAILURES);
  $display("SUCCESSES = %d", SUCCESSES);

  $finish;
end

endmodule