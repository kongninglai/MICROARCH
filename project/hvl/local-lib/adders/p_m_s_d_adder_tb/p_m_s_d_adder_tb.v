`timescale 1ns / 1ps

module tb_p_m_s_d_adder();

    // Inputs
    reg [2:0] p_m_s_in;
    reg [2:0] disp_size_inbytes;

    // Outputs
    wire [3:0] total_offset;

    // Verification variables
    integer i, j;
    reg [3:0] expected_sum;
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    p_m_s_d_adder uut (
        .p_m_s_in(p_m_s_in),
        .disp_size_inbytes(disp_size_inbytes),
        .total_offset(total_offset)
    );

    initial begin
        // Initialize inputs
        p_m_s_in = 0;
        disp_size_inbytes = 0;

        $display("=======================================================================");
        $display("Starting Exhaustive Self-Checking TB for Fast CLA Adder...");
        $display("=======================================================================");
        $display("Time | p_m_s_in | disp_size | Exp Sum | Actual Sum | Result");
        $display("-----------------------------------------------------------------------");

        // Wait a bit for initial global resets
        #10; 

        // Exhaustive test: 8 x 8 = 64 total combinations
        for (i = 0; i <= 7; i = i + 1) begin
            for (j = 0; j <= 7; j = j + 1) begin
                
                // Apply stimulus
                p_m_s_in = i[2:0];
                disp_size_inbytes = j[2:0];
                
                // Calculate expected 4-bit sum behaviorally
                expected_sum = p_m_s_in + disp_size_inbytes;

                // Wait past the 1.40ns max gate delay
                #5; 

                // Verify Actual vs Expected
                if (total_offset !== expected_sum) begin
                    $display("❌ [%4t] |     %0d    |     %0d     |    %0d    |     %0d      | FAIL", 
                             $time, p_m_s_in, disp_size_inbytes, expected_sum, total_offset);
                    error_count = error_count + 1;
                    FAILURES = FAILURES + 1;
                end else begin
                    $display("✅ [%4t] |     %0d    |     %0d     |    %0d    |     %0d      | PASS", 
                             $time, p_m_s_in, disp_size_inbytes, expected_sum, total_offset);
                    SUCCESSES = SUCCESSES + 1;
                end
            end
        end

        // Final Result Summary
        $display("=======================================================================");
        if (error_count == 0) begin
            $display("🎉 ALL 64 TESTS PASSED! (0 Errors) - Fast Adder logic is flawless.");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("=======================================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule