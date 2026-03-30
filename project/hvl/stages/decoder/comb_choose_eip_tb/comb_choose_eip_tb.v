`timescale 1ns / 1ps

module comb_logic_gen_tb();

    // 1. Inputs
    reg P2, P1, P0;

    // 2. Outputs
    wire OUT1, OUT0;

    // Expected Outputs
    reg exp_OUT1, exp_OUT0;

    // 3. Instantiate UUT (Unit Under Test)
    comb_choose_eip uut (
        .P2(P2),
        .P1(P1),
        .P0(P0),
        .OUT1(OUT1),
        .OUT0(OUT0)
    );

    // 4. Test Tracking
    integer i;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    initial begin
        $display("==========================================================");
        $display(" P2 P1 P0 | Exp OUT1 Exp OUT0 | Got OUT1 Got OUT0 | Result");
        $display("==========================================================");

        // Loop through all 8 possible combinations (0 to 7)
        for (i = 0; i < 8; i = i + 1) begin
            
            // Assign bits to match Espresso's .ilb P2 P1 P0 order
            {P2, P1, P0} = i[2:0];

            // -------------------------------------------------------------
            // Expected logic based on your intended Espresso behavior:
            // OUT1 (previously OUT2) = P2 | P1
            // OUT0 (previously OUT1) = P2 | (~P1 & P0)
            // -------------------------------------------------------------
            exp_OUT1 = P2 | P1;
            exp_OUT0 = P2 | (~P1 & P0);

            // Wait for standard cell delays to propagate
            #10; 

            // Print the current state 
            $write("  %b  %b  %b |        %b        %b |        %b        %b | ",
                   P2, P1, P0, exp_OUT1, exp_OUT0, OUT1, OUT0);

            // Check if hardware matches the expected math
            if (OUT1 !== exp_OUT1 || OUT0 !== exp_OUT0) begin
                $display("❌ FAIL");
                FAILURES = FAILURES + 1;
            end else begin
                $display("✅ PASS");
                SUCCESSES = SUCCESSES + 1;
            end
        end

        $display("==========================================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $display("==========================================================");
        $finish;
    end

endmodule