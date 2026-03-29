`timescale 1ns/1ps

module tb_sat_signed_narrow;

    // =========================================================
    // DUT 1: 16 -> 8
    // =========================================================
    reg  [15:0] in16;
    wire [7:0]  out8;

    sat_signed_narrow #(
        .IN_WIDTH(16),
        .OUT_WIDTH(8)
    ) dut_word_to_byte (
        .in(in16),
        .out(out8)
    );

    // =========================================================
    // DUT 2: 32 -> 16
    // =========================================================
    reg  [31:0] in32;
    wire [15:0] out16;

    sat_signed_narrow #(
        .IN_WIDTH(32),
        .OUT_WIDTH(16)
    ) dut_dword_to_word (
        .in(in32),
        .out(out16)
    );

    // =========================================================
    // Golden model functions
    // =========================================================
    function [7:0] golden_sat_16_to_8;
        input [15:0] val;
        begin
            if ($signed(val) > 127)
                golden_sat_16_to_8 = 8'sd127;
            else if ($signed(val) < -128)
                golden_sat_16_to_8 = -8'sd128;
            else
                golden_sat_16_to_8 = val[7:0];
        end
    endfunction

    function [15:0] golden_sat_32_to_16;
        input [31:0] val;
        begin
            if ($signed(val) > 32767)
                golden_sat_32_to_16 = 16'sd32767;
            else if ($signed(val) < -32768)
                golden_sat_32_to_16 = -16'sd32768;
            else
                golden_sat_32_to_16 = val[15:0];
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // =========================================================
    // Tasks
    // =========================================================
    task check_16_to_8;
        input [15:0] val;
        reg   [7:0] expected;
        begin
            in16 = val;
            #5;
            expected = golden_sat_16_to_8(val);

            if (out8 !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][16->8] in=%0d (0x%h), out=%0d (0x%h), expected=%0d (0x%h)",
                         $signed(val), val, $signed(out8), out8, $signed(expected), expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][16->8] in=%0d (0x%h), out=%0d (0x%h)",
                //          $signed(val), val, $signed(out8), out8);
            end
        end
    endtask

    task check_32_to_16;
        input [31:0] val;
        reg   [15:0] expected;
        begin
            in32 = val;
            #5;
            expected = golden_sat_32_to_16(val);

            if (out16 !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][32->16] in=%0d (0x%h), out=%0d (0x%h), expected=%0d (0x%h)",
                         $signed(val), val, $signed(out16), out16, $signed(expected), expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][32->16] in=%0d (0x%h), out=%0d (0x%h)",
                //          $signed(val), val, $signed(out16), out16);
            end
        end
    endtask

    integer i;

    initial begin
        // -----------------------------------------------------
        // Directed tests: 16 -> 8
        // -----------------------------------------------------
        check_16_to_8(16'sd0);
        check_16_to_8(16'sd1);
        check_16_to_8(-16'sd1);
        check_16_to_8(16'sd127);
        check_16_to_8(-16'sd128);
        check_16_to_8(16'sd126);
        check_16_to_8(-16'sd127);

        check_16_to_8(16'sd128);      // positive saturation
        check_16_to_8(16'sd200);      // positive saturation
        check_16_to_8(16'sd30000);    // positive saturation

        check_16_to_8(-16'sd129);     // negative saturation
        check_16_to_8(-16'sd200);     // negative saturation
        check_16_to_8(-16'sd30000);   // negative saturation

        check_16_to_8(16'h007f);      // +127
        check_16_to_8(16'h0080);      // +128 -> sat
        check_16_to_8(16'hff80);      // -128
        check_16_to_8(16'hff7f);      // -129 -> sat

        // -----------------------------------------------------
        // Directed tests: 32 -> 16
        // -----------------------------------------------------
        check_32_to_16(32'sd0);
        check_32_to_16(32'sd1);
        check_32_to_16(-32'sd1);
        check_32_to_16(32'sd32767);
        check_32_to_16(-32'sd32768);
        check_32_to_16(32'sd32766);
        check_32_to_16(-32'sd32767);

        check_32_to_16(32'sd32768);        // positive saturation
        check_32_to_16(32'sd50000);        // positive saturation
        check_32_to_16(32'sd1000000000);   // positive saturation

        check_32_to_16(-32'sd32769);       // negative saturation
        check_32_to_16(-32'sd50000);       // negative saturation
        check_32_to_16(-32'sd1000000000);  // negative saturation

        check_32_to_16(32'h00007fff);      // +32767
        check_32_to_16(32'h00008000);      // +32768 -> sat
        check_32_to_16(32'hffff8000);      // -32768
        check_32_to_16(32'hffff7fff);      // -32769 -> sat

        // -----------------------------------------------------
        // Random tests
        // -----------------------------------------------------
        for (i = 0; i < 100; i = i + 1) begin
            check_16_to_8($random);
        end

        for (i = 0; i < 100; i = i + 1) begin
            check_32_to_16($random);
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end

endmodule