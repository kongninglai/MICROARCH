`timescale 1ns/1ps

module logic_tail_ptr_tb;

    // Inputs to DUT
    reg clk;
    reg rst_bar;
    reg [3:0] incr_amt;
    reg shft_reg_we; 
    reg flush;
    reg stall;
    reg fb_req_cl;
    reg eip_redirection; // <-- NEW: Replaced we_cl_byte_cnt

    // Output from Design
    wire [4:0] tail_ptr;

    // Internal Tracking
    integer errors = 0;
    reg [4:0] expected_ptr;
    reg [255:0] test_name; 
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // DESIGN UNDER TEST
    logic_tail_ptr dut (
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(incr_amt),
        .shft_reg_we(shft_reg_we), 
        .flush(flush),
        .stall(stall),
        .fb_req_cl(fb_req_cl),
        .eip_redirection(eip_redirection), // <-- NEW: Wired Redirection
        .tail_ptr(tail_ptr)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Reporting Task
    task verify;
        input [4:0] target;
        begin
            @(negedge clk); 
            if (tail_ptr === target) begin
                $display("[PASS] %0s | Expected: %d, Got: %d", test_name, target, tail_ptr);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                // Reading the internal we_cl_byte_cnt_temp to verify internal logic
                $display("[FAIL] %0s | Expected: %d (%b), Got: %d (%b) | Stall=%b Req=%b Flush=%b Decr=%d EIP_Redir=%b WE_Bytes=%d", 
                          test_name, target, target, tail_ptr, tail_ptr, stall, fb_req_cl, flush, incr_amt, eip_redirection, dut.we_cl_byte_cnt_temp[4:0]);
                
                $display("       Internal Wires: cl_incr_only=%d, out=%d, cl_incr=%d, decr=%d", 
                          dut.tail_ptr_cl_incr_only_w, dut.tail_ptr_out, 
                          dut.tail_ptr_cl_incr_w, dut.tail_ptr_decr_w);
                
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    initial begin
        // --- Initialization ---
        clk = 0; rst_bar = 0; flush = 0; stall = 0; fb_req_cl = 0; 
        incr_amt = 0; shft_reg_we = 0; expected_ptr = 0; eip_redirection = 0;

        $display("\n--- INITIALIZING TAIL POINTER TESTBENCH ---");
        #15 rst_bar = 1; // Release reset

        // TEST 1
        test_name = "Initial Reset Check";
        verify(5'd0);

        // TEST 2: Fill Only (Add 16)
        test_name = "Fill Only (Empty -> Add 16)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 0;
        expected_ptr = 16;
        verify(expected_ptr);

        // TEST 3: Decode + Fill 
        test_name = "Decode + Fill (16 - 3 + 16 = 29)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 0;
        incr_amt = 3;       // Consume 3 bytes
        expected_ptr = 29;
        verify(expected_ptr);

        // TEST 4: Normal Decrement
        test_name = "Normal Decrement (29 - 5 = 24)";
        stall = 0; fb_req_cl = 0; shft_reg_we = 1; eip_redirection = 0;
        incr_amt = 5; 
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 5: Stall (Hold Value via Mux IN2)
        test_name = "Stall/Hold Value (Stay at 24)";
        stall = 1; fb_req_cl = 0; shft_reg_we = 1; 
        incr_amt = 5;       
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 6: Stall + Fill 
        test_name = "Stall + Fill (24 + 16 = 40 -> 8)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 0;
        expected_ptr = 8; // 40 wraps around to 8 in 5-bit
        verify(expected_ptr);

        // TEST 7: Flush Priority
        test_name = "Flush Priority Check (Return to 0)";
        flush = 1; shft_reg_we = 1; eip_redirection = 1; incr_amt = 5; 
        expected_ptr = 0;
        verify(expected_ptr);
        flush = 0; 

        // TEST 8: Fill Only with Redirection (Add 10)
        // Offset is 6, so we_cl_byte_cnt should evaluate to 16 - 6 = 10
        test_name = "Redirection Fill (Empty -> Add 10)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 1; incr_amt = 6;
        expected_ptr = 10;
        verify(expected_ptr);

        // TEST 9: Fill Only with Redirection (Add 15)
        // Offset is 1, so we_cl_byte_cnt should evaluate to 16 - 1 = 15
        test_name = "Redirection Fill (10 + 15 = 25)";
        stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 1; incr_amt = 1;
        expected_ptr = 25;
        verify(expected_ptr);

        // TEST 10: Cross Cache Line Boundary (Wrap Around)
        // Normal fetch adds 16. Consume 5.
        // Math: 25 - 5 + 16 = 36. In 5-bit binary, 36 is 00100 (which is 4).
        test_name = "Cross Boundary Wrap (25 - 5 + 16 = 36 -> 4)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 0; incr_amt = 5; 
        expected_ptr = 4; 
        verify(expected_ptr);

        // TEST 11: Write Enable Low (Hold Value)
        test_name = "EDGE CASE: WE Low/Hold Value (Stay at 4)";
        stall = 0; fb_req_cl = 1; shft_reg_we = 0; 
        incr_amt = 3; eip_redirection = 0;
        expected_ptr = 4; 
        verify(expected_ptr);

        // TEST 12: Zero Decrement
        test_name = "EDGE CASE: Zero Decrement (4 - 0 = 4)";
        stall = 0; fb_req_cl = 0; shft_reg_we = 1; 
        incr_amt = 0; 
        expected_ptr = 4; 
        verify(expected_ptr);

        // --- NEW TESTS FOR CACHE LINE BYTE COUNT LOGIC ---

        // TEST 13: Redirection Max Offset
        test_name = "NEW: Redir Max Offset (Empty -> Add 1)";
        // 1. Explicitly flush using the verify task to keep clock synced
        flush = 1; stall = 0; fb_req_cl = 0; shft_reg_we = 1; eip_redirection = 0; incr_amt = 0;
        verify(5'd0); 
        
        // 2. Setup the actual test
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 1; incr_amt = 15;
        expected_ptr = 1; 
        verify(expected_ptr);

        // TEST 14: Redirection Zero Offset 
        test_name = "NEW: Redir Zero Offset (Empty -> Add 16)";
        // 1. Explicitly flush
        flush = 1; stall = 0; fb_req_cl = 0; shft_reg_we = 1; eip_redirection = 0; incr_amt = 0;
        verify(5'd0); 

        // 2. Setup the actual test
        flush = 0; stall = 1; fb_req_cl = 1; shft_reg_we = 1; eip_redirection = 1; incr_amt = 0;
        expected_ptr = 16; 
        verify(expected_ptr);

        // --- FINAL REPORTING ---
        $display("\n=======================================");
        if (errors == 0) begin
            $display("   FINAL STATUS: SUCCESS             ");
            $display("   ALL TEST CASES PASSED             ");
        end else begin
            $display("   FINAL STATUS: FAILURE             ");
            $display("   TOTAL ERRORS: %d                 ", errors);
        end
        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule