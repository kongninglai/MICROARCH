`timescale 1ns/1ps

module logic_tail_ptr_tb;

    // Inputs to DUT
    reg clk;
    reg rst_bar;
    reg [3:0] incr_amt;
    reg de_valid;
    reg flush;
    reg stall;
    reg fb_req_cl;
    reg [4:0] we_cl_byte_cnt;

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
        .de_valid(de_valid),
        .flush(flush),
        .stall(stall),
        .fb_req_cl(fb_req_cl),
        .we_cl_byte_cnt(we_cl_byte_cnt), // <-- NEW: Wired the byte count
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
                // NEW: Added the WE Byte Count to the failure printout
                $display("[FAIL] %0s | Expected: %d (%b), Got: %d (%b) | Stall=%b Req=%b Flush=%b Decr=%d Incr=%d", 
                          test_name, target, target, tail_ptr, tail_ptr, stall, fb_req_cl, flush, incr_amt, we_cl_byte_cnt);
                
                $display("tail_ptr_cl_incr_only_w %d (%b), tail_ptr_out %d (%b),  tail_ptr_cl_incr_w %d (%b), tail_ptr_decr_w %d (%b)", 
                          dut.tail_ptr_cl_incr_only_w, dut.tail_ptr_cl_incr_only_w, dut.tail_ptr_out, dut.tail_ptr_out, 
                          dut.tail_ptr_cl_incr_w, dut.tail_ptr_cl_incr_w, dut.tail_ptr_decr_w, dut.tail_ptr_decr_w);
                
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    initial begin
        // --- Initialization ---
        clk = 0; rst_bar = 0; flush = 0; stall = 0; fb_req_cl = 0; 
        incr_amt = 0; de_valid = 0; expected_ptr = 0; we_cl_byte_cnt = 0;

        $display("\n--- INITIALIZING TAIL POINTER TESTBENCH ---");
        #15 rst_bar = 1; // Release reset

        // TEST 1
        test_name = "Initial Reset Check";
        verify(5'd0);

        // TEST 2: Fill Only (Variable amount)
        test_name = "Fill Only (Empty -> Add 16)";
        stall = 1; fb_req_cl = 1; de_valid = 0; we_cl_byte_cnt = 16;
        expected_ptr = 16;
        verify(expected_ptr);

        // TEST 3: Decode + Fill (Variable amount)
        test_name = "Decode + Fill (16 - 3 + 11 = 24)";
        stall = 0; fb_req_cl = 1; de_valid = 1; 
        incr_amt = 3;       // Consume 3 bytes
        we_cl_byte_cnt = 11; // Write 11 bytes (e.g. branch offset was 5)
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 4: Normal Decrement
        test_name = "Normal Decrement (24 - 5 = 19)";
        stall = 0; fb_req_cl = 0; de_valid = 1; 
        incr_amt = 5; 
        we_cl_byte_cnt = 0; // No fetch this cycle
        expected_ptr = 19;
        verify(expected_ptr);

        // TEST 5: Stall (Hold Value)
        test_name = "Stall/Hold Value (Stay at 19)";
        stall = 1; fb_req_cl = 0; de_valid = 0; 
        incr_amt = 5;       // Simulator might have data here, but stall should ignore it
        expected_ptr = 19;
        verify(expected_ptr);

        // TEST 6: Stall + Fill 
        test_name = "Stall + Fill (19 + 10 = 29)";
        stall = 1; fb_req_cl = 1; de_valid = 0; 
        we_cl_byte_cnt = 10;
        expected_ptr = 29; 
        verify(expected_ptr);

        // TEST 7: Flush Priority
        test_name = "Flush Priority Check (Return to 0)";
        flush = 1;
        expected_ptr = 0;
        verify(expected_ptr);
        flush = 0;

        // TEST 8: Fill Only (Variable amount)
        test_name = "Fill Only (Empty -> Add 10)";
        stall = 1; fb_req_cl = 1; de_valid = 0; we_cl_byte_cnt = 10;
        expected_ptr = 10;
        verify(expected_ptr);

        // TEST 9: Fill Only (Variable amount)
        test_name = "Fill Only (Empty -> Add 15)";
        stall = 1; fb_req_cl = 1; de_valid = 0; we_cl_byte_cnt = 15;
        expected_ptr = 25;
        verify(expected_ptr);

        // TEST 8: Cross Cache Line Boundary (Wrap Around)
        // Scenario: Pointer is at 28. Consume 6 bytes, write 14 new bytes.
        // Math: 28 - 6 + 14 = 36. In 5-bit binary, 36 is 00100 (which is 4).
        test_name = "Cross Boundary Wrap (25 - 1 + 14 = 38 ->00110)";
        stall = 0; 
        fb_req_cl = 1; 
        de_valid = 1; 
        incr_amt = 1; 
        we_cl_byte_cnt = 14;
        expected_ptr = 6; 
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