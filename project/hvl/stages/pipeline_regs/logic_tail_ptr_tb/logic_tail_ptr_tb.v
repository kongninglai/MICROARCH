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

    // Output from Design
    wire [4:0] tail_ptr;

    // Internal Tracking
    integer errors = 0;
    reg [4:0] expected_ptr;
    reg [255:0] test_name; // String for reporting
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
        .tail_ptr(tail_ptr)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Reporting Task
    task verify;
        input [4:0] target;
        begin
            // Wait exactly 2 falling edges (allows 1 full setup/hold cycle safely)
            @(negedge clk); 
            
            if (tail_ptr === target) begin
                // Note the %0s to prevent 256-bit empty space padding
                $display("[PASS] %0s | Expected: %d, Got: %d", test_name, target, tail_ptr);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                // Added %b for target and tail_ptr to easily spot 'x' or 'z' undefined states
                $display("[FAIL] %0s | Expected: %d (%b), Got: %d (%b) | Status: Stall=%b Req=%b Flush=%b Amt=%d", 
                          test_name, target, target, tail_ptr, tail_ptr, stall, fb_req_cl, flush, incr_amt);
                errors = errors + 1;
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    initial begin
        // --- Initialization ---
        clk = 0; rst_bar = 0; flush = 0; stall = 0; fb_req_cl = 0; 
        incr_amt = 0; de_valid = 0; expected_ptr = 0;

        $display("\n--- INITIALIZING TAIL POINTER TESTBENCH ---");
        #15 rst_bar = 1; // Release reset

        // TEST 1
        test_name = "Initial Reset Check";
        verify(5'd0);

        // TEST 2
        test_name = "Fill Only (Empty -> 16)";
        stall = 1; fb_req_cl = 1; de_valid = 0;
        expected_ptr = 16;
        verify(expected_ptr);

        // TEST 3
        test_name = "Decode + Fill (16 - 3 + 16 = 29)";
        stall = 0; fb_req_cl = 1; de_valid = 1; incr_amt = 3;
        expected_ptr = 29;
        verify(expected_ptr);

        // TEST 4
        test_name = "Normal Decrement (29 - 5 = 24)";
        stall = 0; fb_req_cl = 0; de_valid = 1; incr_amt = 5;
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 5
        test_name = "Stall/Hold Value (Stay at 24)";
        stall = 1; fb_req_cl = 0; de_valid = 0;
        expected_ptr = 24;
        verify(expected_ptr);

        // TEST 6
        test_name = "Stall + Fill (24 + 16 = 8 due to 5-bit wrap)";
        stall = 1; fb_req_cl = 1; de_valid = 0;
        expected_ptr = 8; 
        verify(expected_ptr);

        // TEST 7
        test_name = "Flush Priority Check (Return to 0)";
        flush = 1;
        expected_ptr = 0;
        verify(expected_ptr);
        flush = 0; // Release flush just in case more tests are added

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