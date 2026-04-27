module mux3_onehot_tb; // Renamed to match 3 inputs

initial begin
  // $vcdplusfile("mux3_onehot_tb.dump.vpd");
  // $vcdpluson(0, mux3_onehot_tb); 
end

reg [2:0] in_sel;
wire [31:0] out, out_exp;

// Hardcoded data inputs (fine for a basic test)
reg [31:0] in0 = 32'd0;
reg [31:0] in1 = 32'd1;
reg [31:0] in2 = 32'd2;

// Structural DUT
mux3_onehot DUT(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2), 
    .out(out)
);

// Behavioral Golden Model
mux3_onehot_tb_behav DUT_behav(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2),
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
  in_sel = 3'b001; 

  // Loop exactly 3 times for 3 one-hot states
  for (i = 0; i < 3; i = i + 1) begin
    #10; // Give logic plenty of time to settle (10ns)
    check(out, out_exp);
    
    // Shift the '1' to the left to test the next select line
    in_sel = in_sel << 1; 
  end

  // Optional: Test the all-zero (no selection) state
  in_sel = 3'b000;
  #10;
  check(out, out_exp);

  $display("\nTEST COMPLETE");
  $display("FAILURES  = %d", FAILURES);
  $display("SUCCESSES = %d", SUCCESSES);

  $finish;
end

endmodule