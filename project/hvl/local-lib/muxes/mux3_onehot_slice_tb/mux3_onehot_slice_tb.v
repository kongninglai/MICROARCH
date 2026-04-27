module mux3_onehot_slice_tb; // Renamed to match 3 inputs

initial begin
  // $vcdplusfile("mux3_onehot_slice_tb.dump.vpd");
  // $vcdpluson(0, mux3_onehot_slice_tb); 
end

reg [2:0] in_sel;
wire out, out_exp;

// Hardcoded data inputs (fine for a basic test)
reg in0 = 1'b0;
reg in1 = 1'b1;
reg in2 = 1'b0;

// Structural DUT
mux3_onehot_slice DUT(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2),
    .out(out)
);

// Behavioral Golden Model
mux3_onehot_slice_behav DUT_behav(
    .in_sel(in_sel),
    .in0(in0), .in1(in1), .in2(in2),
    .out(out_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;
integer i;

task check;
  input out, out_exp;
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