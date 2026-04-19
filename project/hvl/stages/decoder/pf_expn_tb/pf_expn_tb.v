`timescale 1ns / 1ps

module tb_pf_expn();

    // 1. Inputs
    reg [15:0] pf_expn_bytes;
    reg [3:0]  instr_len;

    // 2. Outputs
    wire [1:0] exception_flags;

    // Tracking variables
    integer FAILURES = 0;
    integer SUCCESSES = 0;
    integer i;
    
    // Internal variables for behavioral checking
    reg expected_pf;
    reg [15:0] mask;

    // 3. Instantiate UUT
    pf_expn uut (
        .pf_expn_bytes(pf_expn_bytes),
        .instr_len(instr_len),
        .exception_flags(exception_flags)
    );

    // 4. Behavioral "Gold Standard" Calculation Function
    // This calculates the correct answer using high-level Verilog
    task calculate_expected;
        begin
            if (instr_len == 0) begin
                expected_pf = 1'b0;
            end else begin
                // Create a mask of 1s based on instruction length
                // e.g., length 3 -> mask is 16'b0000_0000_0000_0111
                mask = (1 << instr_len) - 1; 
                
                // Bitwise AND the faults with the mask, then Reduction OR (|) the result
                expected_pf = |(pf_expn_bytes & mask);
            end
        end
    endtask

    // 5. Verification Task
    task check_result;
        input [8*40:1] test_name;
        begin
            #5; // Wait for combinational logic to settle
            calculate_expected();
            
            if (exception_flags[0] === expected_pf && exception_flags[1] === 1'b0) begin
                SUCCESSES = SUCCESSES + 1;
                // Only print directed tests to avoid flooding the console
                if (test_name != "FUZZER") begin
                    $display("  ✅ PASS | %0s | Len: %0d | Bytes: %b -> PF: %b", 
                              test_name, instr_len, pf_expn_bytes, exception_flags[0]);
                end
            end else begin
                FAILURES = FAILURES + 1;
                $display("  ❌ FAIL | %0s", test_name);
                $display("     Inputs: Len: %0d | Bytes: %b", instr_len, pf_expn_bytes);
                $display("     EXPECTED PF: %b | ACTUAL PF: %b", expected_pf, exception_flags[0]);
            end
        end
    endtask

    // 6. Stimulus
    initial begin
        $dumpfile("pf_expn_tb.vcd");
        $dumpvars(0, tb_pf_expn);


        $display("=======================================");
        $display("       PAGE FAULT LOGIC TEST SUITE     ");
        $display("=======================================");

        // --- DIRECTED EDGE CASES ---
        
        // Test 0: Length 0 should always be 0
        instr_len = 4'd0; pf_expn_bytes = 16'hFFFF; 
        check_result("Length 0, All Faults   ");

        // Test 1: Length 3 should be 1 if any of the first 3 bits are 1
        instr_len = 4'd3; pf_expn_bytes = 16'hFFFF; 
        check_result("Length 3, All Faults   ");

        // Test 2: Clean instruction
        instr_len = 4'd4; pf_expn_bytes = 16'h0000; 
        check_result("Len 4, No Faults       ");

        // Test 3: Fault exactly at the boundary (Inside)
        instr_len = 4'd4; pf_expn_bytes = 16'b0000_0000_0000_1000; // Bit 3 is 1
        check_result("Len 4, Fault at Byte 3 ");

        // Test 4: Fault exactly at the boundary (Outside)
        // Instruction is 4 bytes (0,1,2,3). Fault is at byte 4. Should NOT trigger.
        instr_len = 4'd4; pf_expn_bytes = 16'b0000_0000_0001_0000; // Bit 4 is 1
        check_result("Len 4, Fault at Byte 4 ");

        // Test 5: Multiple faults inside and outside
        instr_len = 4'd2; pf_expn_bytes = 16'b1111_0000_0000_0010; // Bits 1, 12, 13, 14, 15
        check_result("Len 2, Mixed Faults    ");

        // Test 6: Multiple faults inside and outside
        instr_len = 4'd12; pf_expn_bytes = 16'b1111_0000_0000_0000; // Bits 1, 12, 13, 14, 15
        check_result("Len 12, Mixed Faults    ");

        // Test 7: Max length
        instr_len = 4'd15; pf_expn_bytes = 16'b0100_0000_0000_0000; // Bit 14
        check_result("Len 15, Fault at 14    ");
        
        // Test 8: Max length
        instr_len = 4'd15; pf_expn_bytes = 16'b1000_0000_0000_0000; // Bit 15
        check_result("Len 15, Fault at 15    ");

        $display("---------------------------------------");
        $display("Running 10,000 Randomized Fuzz Tests...");
        
        // --- RANDOM FUZZER ---
        for (i = 0; i < 10000; i = i + 1) begin
            instr_len = $random % 16;       // Random length 0-15
            pf_expn_bytes = $random;        // Random 16-bit vector
            check_result("FUZZER");
        end

        $display("---------------------------------------");
        if (FAILURES == 0)
            $display(" 🎉 ALL %0d TESTS PASSED! Module is mathematically perfect.", SUCCESSES);
        else
            $display(" ⚠️ WARNING: %0d Failures detected.", FAILURES);
        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule