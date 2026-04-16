`timescale 1ns/1ps

module comb_logic_gen_tb();
    // Inputs (Regs)
    reg P0, P1, P2, P3;
    
    // Outputs (Wires)
    wire OUT2, OUT1, OUT0;
    
    // Internal tracking
    integer i;
    integer errors;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    reg [2:0] expected_val;

    // Concatenate for easier display
    wire [2:0] result = {1'b0, OUT1, OUT0};

    // Instantiate the Unit Under Test (UUT)
    logic_prefix_combadder uut (
        .P0(P0), .P1(P1), .P2(P2), .P3(P3),
        .OUT1(OUT1), .OUT0(OUT0)
    );

    // Task to check individual cases
    // Task to check individual cases with internal signal debugging
    task check_case(input [3:0] in_pattern, input [2:0] exp_out, input [127:0] msg);
        begin
            {P3, P2, P1, P0} = in_pattern;
            #2; // Wait for gate delays
            
            // Display internal Layer 3 wires for debugging
            //$display("\n--- Debugging Internal Wires for: %s ---", msg);
            //$display("ODD  Wires: w0=%b, w1=%b, w2=%b", uut.nor_btwn_odd_w0, uut.nor_btwn_odd_w1, uut.nor_btwn_odd_w2);
            //$display("EVEN Wires: w0=%b, w1=%b, w2=%b", uut.nor_btwn_even_w0, uut.nor_btwn_even_w1, uut.nor_btwn_even_w2);

            if (result !== exp_out) begin
                $display("ERROR at %0t: %s | Expected: %b, Got: %b", $time, msg, exp_out, result);
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("PASS  at %0t: %s | Result: %b", $time, msg, result);
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("--- Starting Self-Checking Testbench for Prefix Decoder ---");

        // One-Hot Test Cases: Map the active prefix bit to its numeric value
        check_case(4'b0000, 3'd0, "0 Prefix");
        check_case(4'b0001, 3'd1, "1 Prefix");
        check_case(4'b0010, 3'd0, "0 Prefix");
        check_case(4'b0011, 3'd2, "2 Prefix");
        check_case(4'b0100, 3'd0, "0 Prefix");
        check_case(4'b0101, 3'd1, "1 Prefix");
        check_case(4'b0110, 3'd0, "0 Prefix");
        check_case(4'b0111, 3'd3, "3 Prefix");

        // Exhaustive Sweep (Optional: only if you know the 'Don't Care' behavior)
        $display("\n--- Performing Exhaustive Sweep ---");
        for (i = 0; i < 16; i = i + 1) begin
            {P3, P2, P1, P0} = i;
            #1;
            // You can add logic here to check other combinations if required.
        end

        // Final Report
        if (errors == 0) begin
            $display("\n************************************");
            $display("   TEST PASSED: All cases correct!  ");
            $display("************************************");
        end else begin
            $display("\n************************************");
            $display("   TEST FAILED: %0d errors found.   ", errors);
            $display("************************************");
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule