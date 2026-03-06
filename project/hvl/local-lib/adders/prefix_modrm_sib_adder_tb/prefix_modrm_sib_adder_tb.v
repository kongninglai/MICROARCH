`timescale 1ns / 1ps

module tb_prefix_modrm_sib_adder();

    // Inputs
    reg [2:0] prefix_num;
    reg has_sib;

    // Outputs
    wire [2:0] total_offset;

    // Self-checking variables
    integer error_count = 0;
    integer i, j;
    reg [2:0] expected_val;

    // Instantiate the Unit Under Test (UUT)
    prefix_modrm_sib_adder uut (
        .prefix_num(prefix_num),
        .has_sib(has_sib),
        .total_offset(total_offset)
    );

    initial begin
        // Initialize Inputs
        prefix_num = 0;
        has_sib = 0;

        $display("===============================================================");
        $display("Starting Self-Checking TB for prefix_modrm_sib_adder...");
        $display("===============================================================");
        $display("Time | prefix_num | has_sib | Exp Offset | Actual Offset");
        $display("---------------------------------------------------------------");

        // Wait 10 ns for global reset
        #10;

        // Test valid range of prefix_num (0 to 4)
        for (i = 0; i <= 4; i = i + 1) begin
            
            // Test with both has_sib = 0 and has_sib = 1
            for (j = 0; j <= 1; j = j + 1) begin
                prefix_num = i[2:0];
                has_sib = j[0];
                
                // Calculate behavioral expected value
                expected_val = prefix_num + has_sib;

                // Wait 10ns for logic gates to settle
                #10; 

                // Verify Actual vs Expected
                if (total_offset !== expected_val) begin
                    $display("❌ FAIL [%4t]:      %0d     |    %0d    |     %0d      |      %0d", 
                             $time, prefix_num, has_sib, expected_val, total_offset);
                    error_count = error_count + 1;
                end else begin
                    $display("✅ PASS [%4t]:      %0d     |    %0d    |     %0d      |      %0d", 
                             $time, prefix_num, has_sib, expected_val, total_offset);
                end
            end
        end

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $finish;
    end
endmodule