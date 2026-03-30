`timescale 1ns/1ps

module big_increment_cout_tb;

    initial begin
      // Creates the waveform dump for debugging in VCS/DVE
      $vcdplusfile("big_increment_cout_tb.dump.vpd");
      $vcdpluson(0, big_increment_cout_tb); 
    end

    localparam WIDTH = 4; // Set to 4 to match your incrementer

    // Inputs and Outputs
    reg   [WIDTH-1:0]  in;
    wire  [WIDTH-1:0]  out, out_exp;
    wire               cout, cout_exp;

    // Structural Design Under Test
    big_increment_cout #(.WIDTH(WIDTH)) DUT(
        .a(in),
        .s(out), 
        .cout(cout)
    );

    // Behavioral Reference Model
    big_increment_cout_behav #(.WIDTH(WIDTH)) REF(
        .a(in),
        .s(out_exp), 
        .cout(cout_exp)
    );

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Task to check the WIDTH-bit sum AND the 1-bit carry-out
    task check;
      input [WIDTH-1:0] out_val, out_exp_val;
      input             cout_val, cout_exp_val;
      begin
          // Compare concatenated cout and sum
          if ({cout_val, out_val} !== {cout_exp_val, out_exp_val}) begin
            FAILURES = FAILURES + 1;
            $display("FAILURE AT TIME %t. in = %b | expected = %b_%b, got = %b_%b", 
                      $time, in, cout_exp_val, out_exp_val, cout_val, out_val);
          end else begin
            SUCCESSES = SUCCESSES + 1;
          end
      end
    endtask

    initial begin
      $display("\n--- STARTING INCREMENTER RANDOMIZED TEST ---");

      // Test 1: All Zeros
      in = 0; 
      #5; 
      check(out, out_exp, cout, cout_exp);
      
      // Test 2: All Ones (Guarantees the carry-out triggers)
      in = {WIDTH{1'b1}}; 
      #5; 
      check(out, out_exp, cout, cout_exp);
      
      // Test 3: Fuzz Testing
      repeat (1 << 12) begin
        in = $random; // Assign random value first
        #5;           // Wait for propagation
        check(out, out_exp, cout, cout_exp); // Check it
      end

      // --- FINAL REPORTING ---
      $display("\n=======================================");
      if (FAILURES == 0) begin
          $display("   FINAL STATUS: SUCCESS             ");
          $display("   ALL TEST CASES PASSED             ");
      end else begin
          $display("   FINAL STATUS: FAILURE             ");
          $display("   TOTAL ERRORS: %d                 ", FAILURES);
      end
      $display("=======================================");
      $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
      $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

      $finish;
    end

endmodule