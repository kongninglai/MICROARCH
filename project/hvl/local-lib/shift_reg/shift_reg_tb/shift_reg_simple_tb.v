`timescale 1ns/1ps

module shifter_simple_tb;

    // Inputs to DUT
    reg clk, rst_n, shift;
    reg [3:0] instr_len;
    reg [30:0] wr_en;
    reg [247:0] inbytes;

    // Outputs
    wire [127:0] outbytes;
    wire ready;

    // Test tracking
    integer total_tests = 0;
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // DUT Instantiation
    shift_reg dut(
        .clk(clk), .rst_n(rst_n), .shift(shift),
        .instr_len(instr_len), .gate(1'b1), .inbytes(inbytes),
        .wr_en(wr_en), .outbytes(outbytes), .ready(ready)
    );

    // Clock Gen
    initial clk = 0;
    always #5 clk = ~clk;

    // --- DEBUG TASK ---
    task print_state;
        input [8*20:1] label;
        begin
            $display("[%t] %0s | TP_Out: %h | Reset: %b | En[1]: %b", 
                     $time, label, outbytes[31:0], rst_n, dut.en[1]);
        end
    endtask

    // --- VERIFY TASK ---
    task check;
        input [127:0] expected;
        begin
            total_tests = total_tests + 1;
            if (outbytes !== expected) begin
                $display("  ❌ FAIL! Exp: %h", expected);
                $display("          Got: %h", outbytes);
                FAILURES = FAILURES + 1;
            end else begin
                SUCCESSES = SUCCESSES + 1;
                $display("  ✅ PASS");
            end
        end
    endtask

    initial begin
        $display("=== STARTING SIMPLIFIED SHIFT REG TEST ===");
        
        // 1. Properly Pulse Reset
        // If your hardware is Active-High Reset, we must drive 1 to clear it.
        shift = 0; wr_en = 0; inbytes = 0; instr_len = 0;
        rst_n = 0; // Resetting...
        #20;
        rst_n = 1; // Running...
        #5;
        check(128'h0);

        // 2. Load 8 bytes into the bottom of the buffer
        @(negedge clk);
        wr_en = 31'h0000_00FF; // Write to [7:0]
        inbytes = 248'h0807060504030201;
        @(posedge clk); #1;
        print_state("After Load");
        check(128'h00000000000000000807060504030201);

        // 3. Shift by 3 bytes
        // Data 04 (Byte 3) should move to Byte 0 position.
        @(negedge clk);
        wr_en = 0;
        shift = 1;
        instr_len = 3;
        @(posedge clk); #1;
        print_state("After Shift 3");
        // Expected: Original data shifted right by 3 bytes (LSB is at cl[7:0])
        check(128'h00000000000000000000000807060504);

        // 4. Reset again mid-test
        @(negedge clk);
        rst_n = 0; 
        @(posedge clk); #1;
        print_state("After Mid-Test Reset");
        check(128'h0);

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule