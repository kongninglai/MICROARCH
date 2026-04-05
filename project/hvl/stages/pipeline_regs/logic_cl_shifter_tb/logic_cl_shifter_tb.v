`timescale 1ns / 1ps

module tb_logic_cl_shifter();

    // 1. Inputs
    reg [3:0] offset;          
    reg [127:0] cl;
    reg [4:0] tail_ptr;

    // 2. Outputs
    wire unaligned_eip_redir;
    wire [247:0] cl_aligned;

    // 3. Internal Tracking
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 4. Instantiate UUT (Updated to match new port list)
    logic_cl_shifter uut (
        .offset(offset),
        .cl(cl),
        .tail_ptr(tail_ptr),
        .unaligned_eip_redir(unaligned_eip_redir),
        .cl_aligned(cl_aligned)
    );

    // 5. Verification Task
    task check_result;
        input [8*35:1] test_name;
        input [127:0] dummy_exp; // Kept for backwards compatibility if you want to hardcode 128b checks
        
        reg [247:0] expected_full_248;    // Internal 248-bit tracker
        begin
            #10; // Wait for shifters to settle
            
            // --- AUTOMATIC 248-BIT EXPECTED VALUE CALCULATION ---
            // If tail_ptr == 0 AND offset != 0, it's a jump to the middle of the cache line.
            if (tail_ptr == 0 && offset != 0) begin
                // Shift right (little endian) by offset bytes
                expected_full_248 = {120'b0, cl} >> (offset * 8);
            end else begin
                // Normal sequential fetch: shift left by tail_ptr bytes
                expected_full_248 = {120'b0, cl} << (tail_ptr * 8); 
            end
            
            $display("-------------------------------------------------------");
            $display("TEST: %0s", test_name);
            $display("  Offset: %0d | Tail Ptr: %0d", offset, tail_ptr);
            $display("  Redir Flag: %b", unaligned_eip_redir);
            
            // Now we check against the full 248-bit wire
            if (cl_aligned === expected_full_248) begin
                $display("  ✅ PASS");
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL");
                $display("     DATA MISMATCH (Showing full 248-bit / 31-byte bus)");
                $display("       Exp: %h", expected_full_248);
                $display("       Got: %h", cl_aligned);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 6. Stimulus 
    initial begin
        $dumpfile("logic_cl_shifter_tb.vpd");
        $dumpvars(0, tb_logic_cl_shifter);
        
        $display("=======================================================");
        $display("          CACHE LINE SHIFTER / ALIGNER TEST            ");
        $display("=======================================================");

        // Base Cache Line (Sequential 1 to 16 bytes for easy tracking)
        // [Byte 15] ... [Byte 0]
        cl = 128'h10_0F_0E_0D_0C_0B_0A_09_08_07_06_05_04_03_02_01;

        // --------------------------------------------------------------------
        // TEST 1: Normal Sequential Fetch (Aligned Append)
        // --------------------------------------------------------------------
        offset = 4'd0;       
        tail_ptr = 5'd4;       // Shift left by 4 slots
        
        check_result("Sequential Fetch (Tail = 4)        ", 128'h0);

        // --------------------------------------------------------------------
        // TEST 2: Branch Redirection (Flush & Jump to Middle)
        // --------------------------------------------------------------------
        offset = 4'd5;         // Branch offset is 5
        tail_ptr = 5'd0;       // Buffer is empty after flush!
        
        check_result("Middle Jump (Offset=5, Tail=0)     ", 128'h0);

        // --------------------------------------------------------------------
        // TEST 3: Branch Redirection (Perfectly Aligned Branch)
        // --------------------------------------------------------------------
        offset = 4'd0;       
        tail_ptr = 5'd0;       
        
        check_result("Aligned Branch (Offset=0, Tail=0)  ", 128'h0); 

        // --------------------------------------------------------------------
        // TEST 4: Tail Pointer Wrap-Around Edge Case
        // --------------------------------------------------------------------
        offset = 4'd0; 
        tail_ptr = 5'd15;      // Align to the very last slot in the buffer
        
        check_result("Tail Ptr at end of buffer (Tail=15)", 128'h0);

        $display("=======================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule