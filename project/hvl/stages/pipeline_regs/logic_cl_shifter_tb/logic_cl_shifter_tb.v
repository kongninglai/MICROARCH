`timescale 1ns / 1ps

module tb_logic_cl_shifter();

    // 1. Inputs
    reg [3:0] incr_amt;          
    reg eip_redirection;
    reg [127:0] cl;
    reg [4:0] tail_ptr;

    // 2. Outputs
    wire [247:0] cl_aligned;

    // 3. Internal Tracking
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 4. Instantiate UUT (Updated to remove wr_cl_byte_cnt)
    logic_cl_shifter uut (
        .incr_amt(incr_amt),
        .eip_redirection(eip_redirection),
        .cl(cl),
        .tail_ptr(tail_ptr),
        .cl_aligned(cl_aligned)
    );

    // 5. Verification Task (Updated to remove byte count checks)
    task check_result;
        input [8*35:1] test_name;
        input [127:0] exp_cl_aligned_128; 
        
        reg [247:0] expected_full_248;    // Internal 248-bit tracker
        begin
            #10; // Wait for shifters to settle
            
            // --- AUTOMATIC 248-BIT EXPECTED VALUE CALCULATION ---
            if (eip_redirection) begin
                // During a flush, tail_ptr goes to 0, so the upper 15 bytes are guaranteed to be 0
                expected_full_248 = {120'b0, exp_cl_aligned_128};
            end else begin
                // During a normal load, we take the original 16-byte cache line 
                // and perfectly shift it into the 31-byte space
                expected_full_248 = {120'b0, cl} << (tail_ptr * 8); 
            end
            
            $display("-------------------------------------------------------");
            $display("TEST: %0s", test_name);
            $display("  Offset (incr_amt): %0d | Redirection: %b | Tail Ptr: %0d", incr_amt, eip_redirection, tail_ptr);
            
            // Now we check against the full 248-bit wire!
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
        // TEST 1: Normal Sequential Fetch (No redirection)
        // --------------------------------------------------------------------
        eip_redirection = 0;
        incr_amt = 4'd0;       
        tail_ptr = 5'd4;       // Shift left by 4 slots
        
        check_result("Sequential Fetch (Tail = 4)        ", 
                     128'h0C_0B_0A_09_08_07_06_05_04_03_02_01_00_00_00_00);

        // --------------------------------------------------------------------
        // TEST 2: Branch Redirection (Flush & Pack)
        // --------------------------------------------------------------------
        eip_redirection = 1;
        incr_amt = 4'd5;       // Branch offset is 5.
        tail_ptr = 5'd0;       // Buffer is empty after flush!
        
        check_result("Branch Redirection (Offset=5, Tail=0)", 
                     128'h00_00_00_00_00_10_0F_0E_0D_0C_0B_0A_09_08_07_06); // Packed tightly at Byte 0!

        // --------------------------------------------------------------------
        // TEST 3: Branch Redirection (Perfectly Aligned Branch)
        // --------------------------------------------------------------------
        eip_redirection = 1;
        incr_amt = 4'd0;       
        tail_ptr = 5'd0;       
        
        check_result("Aligned Branch (Offset=0, Tail=0)    ", 
                     128'h10_0F_0E_0D_0C_0B_0A_09_08_07_06_05_04_03_02_01); 

        // --------------------------------------------------------------------
        // TEST 4: Tail Pointer Wrap-Around Edge Case
        // --------------------------------------------------------------------
        eip_redirection = 0;
        incr_amt = 4'd0; 
        tail_ptr = 5'd15;      // Align to the very last slot in the buffer
        
        check_result("Tail Ptr at end of buffer (Tail=15)", 
                     128'h01_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00);

        $display("=======================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule