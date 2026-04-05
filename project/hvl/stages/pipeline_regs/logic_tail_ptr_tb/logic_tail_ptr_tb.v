`timescale 1ns/1ps

module logic_tail_ptr_tb;

    // Inputs to DUT
    reg clk;
    reg rst_bar;
    reg [3:0] incr_amt;            // RESTORED: Kept exactly as incr_amt
    reg [3:0] offset;              
    reg shft_reg_we; 
    reg flush;
    reg stall;
    reg fb_req_cl;
    reg unaligned_eip_redir;       

    // Output from Design
    wire [4:0] tail_ptr;

    // Internal Tracking
    integer errors = 0;
    reg [4:0] expected_ptr;
    reg [8*64:1] test_name;        // Expanded to prevent string truncation
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // DESIGN UNDER TEST
    logic_tail_ptr dut (
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(incr_amt),       // EXACT MATCH
        .offset(offset),
        .shft_reg_we(shft_reg_we), 
        .flush(flush),
        .stall(stall),
        .fb_req_cl(fb_req_cl),
        .unaligned_eip_redir(unaligned_eip_redir),
        .tail_ptr(tail_ptr)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Reporting Task 1: Verify the Latched Tail Pointer
    task verify;
        input [4:0] target;
        begin
            @(negedge clk); 
            if (tail_ptr === target) begin
                $display("[PASS PTR] %0s | Expected: %d, Got: %d", test_name, target, tail_ptr);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("[FAIL PTR] %0s | Expected: %d, Got: %d | Stall=%b Req=%b Flush=%b Incr_Amt=%d Offset=%d Unaligned_Redir=%b", 
                          test_name, target, tail_ptr, stall, fb_req_cl, flush, incr_amt, offset, unaligned_eip_redir);
                
                $display("       Internal Wires: cl_incr_only=%d, out=%d, cl_incr=%d, decr=%d", 
                          dut.tail_ptr_cl_incr_only_w, dut.tail_ptr_out, 
                          dut.tail_ptr_cl_incr_w, dut.tail_ptr_decr_w);
                
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // Reporting Task 2: Verify the Combinational we_cl_byte_cnt Logic
    task verify_we_cl_bytes;
        input [4:0] expected_bytes;
        begin
            // FIXED: Wait 8ns to allow the adders and muxes to physically settle!
            // This prevents us from reading intermediate "glitch" values.
            #8; 
            if (dut.we_cl_byte_cnt === expected_bytes) begin
                $display("[PASS WE_CL] %0s | Expected WE Bytes: %d, Got: %d", test_name, expected_bytes, dut.we_cl_byte_cnt);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("[FAIL WE_CL] %0s | Expected WE Bytes: %d, Got: %d | Redir=%b Offset=%d", 
                          test_name, expected_bytes, dut.we_cl_byte_cnt, unaligned_eip_redir, offset);
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    initial begin
        // --- Initialization ---
        clk = 0; rst_bar = 0; flush = 0; stall = 0; fb_req_cl = 0; 
        offset = 0; incr_amt = 0; shft_reg_we = 0; expected_ptr = 0; unaligned_eip_redir = 0;

        $display("\n--- INITIALIZING TAIL POINTER TESTBENCH ---");
        #15 rst_bar = 1; // Release reset

        // TEST 1
        test_name = "Initial Reset Check";
        verify(5'd0);

        // TEST 2: Fill Only (Add 16)
        test_name = "Fill Only (Empty -> Add 16)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0;
        incr_amt = 0; 
        expected_ptr = 16;
        verify(expected_ptr);

        // TEST 3: Decode + Fill 
        test_name = "Decode + Fill (16 - 3 + 16 = 29)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0;
        incr_amt = 3; 
        expected_ptr = 29;
        verify(expected_ptr);

        // TEST 4: Normal Decrement
        test_name = "Normal Decrement (29 - 5 = 24)";
        stall = 0; fb_req_cl = 0; shft_reg_we = 1; unaligned_eip_redir = 0;
        incr_amt = 5; 
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 5: Stall (Hold Value via Mux IN2)
        test_name = "Stall/Hold Value (Stay at 24)";
        stall = 1; fb_req_cl = 0; shft_reg_we = 1; 
        incr_amt = 0; 
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 6: Stall + Fill 
        test_name = "Stall + Fill (24 + 16 = 40 -> 8)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0;
        incr_amt = 0; 
        expected_ptr = 8; 
        verify(expected_ptr);

        // TEST 7: Flush Priority
        test_name = "Flush Priority Check (Return to 0)";
        flush = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 5; 
        incr_amt = 0; 
        expected_ptr = 0;
        verify(expected_ptr);
        flush = 0; 

        // TEST 8: Fill Only with Redirection (Add 10)
        test_name = "Redirection Fill (Empty -> Add 10)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 6;
        incr_amt = 0;
        expected_ptr = 10;
        verify(expected_ptr);

        // TEST 9: Fill Only with Redirection (Add 15)
        test_name = "Redirection Fill (10 + 15 = 25)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 1;
        incr_amt = 0;
        expected_ptr = 25;
        verify(expected_ptr);

        // TEST 10: Cross Cache Line Boundary (Wrap Around)
        test_name = "Cross Boundary Wrap (25 - 5 + 16 = 36 -> 4)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0; 
        incr_amt = 5; 
        expected_ptr = 4; 
        verify(expected_ptr);

        // TEST 11: Write Enable Low (Hold Value)
        test_name = "EDGE CASE: WE Low/Hold Value (Stay at 4)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 0; 
        incr_amt = 3; unaligned_eip_redir = 0;
        expected_ptr = 4; 
        verify(expected_ptr);

        // TEST 12: Zero Decrement
        test_name = "EDGE CASE: Zero Decrement (4 - 0 = 4)";
        stall = 0; fb_req_cl = 0; shft_reg_we = 1; 
        incr_amt = 0; 
        expected_ptr = 4; 
        verify(expected_ptr);

        // --- EXHAUSTIVE CACHE LINE BYTE COUNT LOGIC TESTS ---
        
        // Reset buffer explicitly for cleaner testing below
        flush = 1; stall = 0; fb_req_cl = 0; shft_reg_we = 1; unaligned_eip_redir = 0; offset = 0; incr_amt = 0;
        verify(5'd0); 

        // TEST 13: Redirection Max Offset (16 - 15 = 1 byte)
        test_name = "Redir Max Offset (16 - 15 = 1)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 15; incr_amt = 0;
        verify_we_cl_bytes(5'd1);  // Check combinational logic (now safely delayed)
        verify(5'd1);              // Check tail pointer latched result

        flush = 1; verify(5'd0); 

        // TEST 14: Redirection Zero Offset (16 - 0 = 16 bytes)
        test_name = "Redir Zero Offset (16 - 0 = 16)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 0; incr_amt = 0;
        verify_we_cl_bytes(5'd16); 
        verify(5'd16);             

        flush = 1; verify(5'd0); 
        
        // TEST 15: Intermediate Offset (16 - 5 = 11 bytes)
        test_name = "Redir Mid Offset 1 (16 - 5 = 11)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 5; incr_amt = 0;
        verify_we_cl_bytes(5'd11); 
        verify(5'd11);             

        flush = 1; verify(5'd0); 
        
        // TEST 16: Intermediate Offset (16 - 8 = 8 bytes)
        test_name = "Redir Mid Offset 2 (16 - 8 = 8)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 8; incr_amt = 0;
        verify_we_cl_bytes(5'd8);  
        verify(5'd8);              

        flush = 1; verify(5'd0); 

        // TEST 17: Normal Fetch (No Redir -> Always 16 bytes regardless of offset port)
        test_name = "Normal Fetch (Offset Ignored, Always 16)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0; offset = 7; incr_amt = 0;
        verify_we_cl_bytes(5'd16); 
        verify(5'd16);       

        // ====================================================================
        // --- NEW TESTS: PROVING TAIL POINTER != WE BYTES ---
        // ====================================================================
        $display("\n--- RUNNING TAIL POINTER DECOUPLING TESTS ---");

        // SETUP: Flush the buffer, then add exactly 7 bytes so we start from a non-zero state.
        flush = 1; verify(5'd0);
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 9; incr_amt = 0; // 16 - 9 = 7 bytes
        verify(5'd7); // The current tail pointer is now sitting at 7.

        // TEST 18: Normal Fetch on a partially full buffer
        // WE_CL should be 16. 
        // Tail Pointer should become 7 (Current) + 16 (WE) - 0 (Consume) = 23.
        test_name = "Tail != WE | Normal Fetch (7 + 16 = 23)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0; offset = 0; incr_amt = 0;
        verify_we_cl_bytes(5'd16); 
        verify(5'd23); 

        // TEST 19: Normal Fetch WITH Decode Consumption
        // WE_CL should be 16. 
        // Tail Pointer should become 23 (Current) + 16 (WE) - 5 (Consume) = 34. 
        // Since it is a 5-bit register (max 31), 34 wraps around to 2.
        test_name = "Tail != WE | Fetch + Consume (23 + 16 - 5 = 2)";
        flush = 0; stall = 0; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 0; offset = 0; incr_amt = 5;
        verify_we_cl_bytes(5'd16);
        verify(5'd2);

        // TEST 20: Redirection (Without Flush) on partially full buffer
        // WE_CL should be (16 - 6) = 10. 
        // Tail Pointer should become 2 (Current) + 10 (WE) - 0 (Consume) = 12.
        test_name = "Tail != WE | Redirection (2 + 10 = 12)";
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; unaligned_eip_redir = 1; offset = 6; incr_amt = 0;
        verify_we_cl_bytes(5'd10);
        verify(5'd12);      

        // --- FINAL REPORTING ---
        $display("\n=======================================");
        if (errors == 0) begin
            $display("   FINAL STATUS: SUCCESS             ");
            $display("   ALL TEST CASES PASSED             ");
        end else begin
            $display("   FINAL STATUS: FAILURE             ");
            $display("   TOTAL ERRORS: %d                ", errors);
        end
        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule