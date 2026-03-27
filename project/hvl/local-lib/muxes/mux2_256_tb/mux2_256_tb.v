`timescale 1ns / 1ps

module mux2_256_tb;

    initial begin
      // $vcdplusfile("mux2_256_tb.dump.vpd");
      // $vcdpluson(0, mux2_256_tb); 
    end

    reg [255:0] in0, in1;
    reg s0;
    wire [255:0] out;
    wire [255:0] out_bh;

    // 1. FIXED: Instantiating the correct 256-bit module
    mux2_256 DUT(
      .out(out), .in0(in0), .in1(in1), .s0(s0)
    );

    // 2. FIXED: Replaced missing behavioral module with a simple assign
    assign out_bh = s0 ? in1 : in0;

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    task apply;
        input [255:0] test_in0, test_in1;
        input test_s0;
        begin 
            in0 = test_in0;
            in1 = test_in1;
            s0 = test_s0;
        end
    endtask

    // Enhanced check task to print the inputs if it fails
    task check;
      if (out !== out_bh) begin
        FAILURES = FAILURES + 1;
        $display("FAILURE AT TIME %t.\n  S0   = %b\n  IN0  = %h\n  IN1  = %h\n  Y_bh = %h\n  Y    = %h\n", 
                  $time, s0, in0, in1, out_bh, out);
      end else begin
        SUCCESSES = SUCCESSES + 1;
      end
    endtask

    function [255:0] rand256;
        input integer dummy;
        begin
            rand256 = {$random, $random, $random, $random, 
                       $random, $random, $random, $random};
        end
    endfunction

    initial begin
      $display("=== STARTING MUX2_256 TESTBENCH ===");
      
      // Initialize
      in0 = 256'b0;
      in1 = 256'b0;
      s0  = 1'b0;
      #5; 

      // 1 << 8 is 256 random test cases. 
      repeat (256) begin
        
        apply(
            rand256(0),   // Arg 1: 256-bit random for in0
            rand256(0),   // Arg 2: 256-bit random for in1
            $random % 2   // Arg 3: 1-bit random for s0 (safely bound to 0 or 1)
        );
        
        #5; 
        check();
      end

      $display("FAILURES  = %d out of %d", FAILURES, FAILURES + SUCCESSES);
      $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

      $finish;
    end

endmodule