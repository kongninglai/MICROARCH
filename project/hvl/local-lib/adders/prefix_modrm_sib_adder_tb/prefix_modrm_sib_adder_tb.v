`timescale 1ns / 1ps

module tb_prefix_modrm_sib_adder();

    // Inputs
    reg [2:0] prefix_num;
    reg has_modrm; // ADDED: Declare the missing input
    reg has_sib;

    // Outputs
    wire [2:0] total_offset;

    // Self-checking variables
    integer error_count = 0;
    integer i, j, k; // ADDED 'k' for the new loop
    reg [2:0] expected_val;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    prefix_modrm_sib_adder uut (
        .prefix_num(prefix_num),
        .has_modrm(has_modrm), // ADDED: Connect the port
        .has_sib(has_sib),
        .total_offset(total_offset)
    );

    initial begin
        // Initialize Inputs
        prefix_num = 0;
        has_modrm = 0;
        has_sib = 0;

        $display("=========================================================================");
        $display("Starting Self-Checking TB for prefix_modrm_sib_adder...");
        $display("=========================================================================");
        $display("Time | prefix_num | has_modrm | has_sib | Exp Offset | Actual Offset");
        $display("-------------------------------------------------------------------------");

        // Wait 10 ns for global reset
        #10;

        // Test valid range of prefix_num (0 to 4)
        for (i = 0; i <= 4; i = i + 1) begin
            
            // Test with has_modrm = 0 and 1
            for (k = 0; k <= 1; k = k + 1) begin
                
                // Test with has_sib = 0 and 1
                for (j = 0; j <= 1; j = j + 1) begin
                    prefix_num = i[2:0];
                    has_modrm = k[0];
                    has_sib = j[0];
                    
                    // Calculate behavioral expected value
                    expected_val = prefix_num + has_modrm + has_sib;

                    // Wait 10ns for logic gates to settle
                    #10; 

                    // Verify Actual vs Expected
                    if (total_offset !== expected_val) begin
                        $display("❌ FAIL [%4t]:      %0d      |     %0d     |    %0d    |      %0d       |       %0d", 
                                 $time, prefix_num, has_modrm, has_sib, expected_val, total_offset);
                        error_count = error_count + 1;
                        FAILURES = FAILURES + 1;
                    end else begin
                        $display("✅ PASS [%4t]:      %0d      |     %0d     |    %0d    |      %0d       |       %0d", 
                                 $time, prefix_num, has_modrm, has_sib, expected_val, total_offset);
                        SUCCESSES = SUCCESSES + 1;
                    end
                end
            end
        end

        // Final Result Summary
        $display("=========================================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("=========================================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule