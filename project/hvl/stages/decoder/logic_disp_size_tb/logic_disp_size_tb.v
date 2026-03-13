`timescale 1ns / 1ps

module tb_logic_disp_size();

    // Inputs
    reg [7:0] modrm_byte;
    reg is_modrm_true;
    reg [2:0] prefix_num;

    // Outputs
    wire [2:0] disp_size_inbytes;
    wire [1:0] disp_size;

    // Self-checking variables
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    logic_disp_size uut (
        .modrm_byte(modrm_byte), 
        .is_modrm_true(is_modrm_true), 
        .prefix_num(prefix_num), 
        .disp_size_inbytes(disp_size_inbytes), 
        .disp_size(disp_size)
    );

    // Task to automatically verify outputs
    task check_result;
        input integer test_num;
        input [1:0] expected_size_bits;
        input [2:0] expected_size_bytes;
        begin
            if (disp_size !== expected_size_bits || disp_size_inbytes !== expected_size_bytes) begin
                $display("❌ FAIL [Test %0d]: ModR/M=%b, is_modrm=%b | Exp SizeBits=%b, Bytes=%0d | Got SizeBits=%b, Bytes=%0d", 
                         test_num, modrm_byte, is_modrm_true, expected_size_bits, expected_size_bytes, disp_size, disp_size_inbytes);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("✅ PASS [Test %0d]: ModR/M=%b, is_modrm=%b -> Validly output %0d Bytes", 
                         test_num, modrm_byte, is_modrm_true, disp_size_inbytes);
                SUCCESSES = SUCCESSES + 1;  
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        modrm_byte = 0;
        is_modrm_true = 0;
        prefix_num = 0;
        
        $display("===============================================================");
        $display("Starting Self-Checking Testbench for logic_disp_size...");
        $display("===============================================================");

        // Wait 10 ns for global reset to finish
        #10;
        
        // Test 1: Mod = 01 (1-byte disp)
        is_modrm_true = 1'b1;
        modrm_byte = 8'b01_000_000; // Mod 01, RM 000
        #10;
        check_result(1, 2'b01, 3'd1);

        // Test 2: Mod = 10 (4-byte disp)
        modrm_byte = 8'b10_000_000; // Mod 10, RM 000
        #10; 
        check_result(2, 2'b10, 3'd4);

        // Test 3: Mod = 00, R/M = 101 (4-byte disp - special case)
        modrm_byte = 8'b00_000_101; // Mod 00, RM 101
        #10; 
        check_result(3, 2'b10, 3'd4);

        // Test 4: Mod = 00, R/M = 000 (0-byte disp)
        modrm_byte = 8'b00_000_000; // Mod 00, RM 000
        #10; 
        check_result(4, 2'b00, 3'd0);

        // Test 5: is_modrm_true = 0 (Should mask to 0)
        is_modrm_true = 1'b0;
        modrm_byte = 8'b10_000_000; // Even with Mod 10, should output 0
        #10; 
        check_result(5, 2'b00, 3'd0);

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule