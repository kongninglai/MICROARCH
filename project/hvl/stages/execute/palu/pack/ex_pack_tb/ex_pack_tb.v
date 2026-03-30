`timescale 1ns/1ps

module tb_ex_pack;

    reg  [63:0] dest_in;
    reg  [63:0] src_in;
    reg         pack_size;
    wire [63:0] dest_out;

    ex_pack dut (
        .dest_in(dest_in),
        .src_in(src_in),
        .pack_size(pack_size),
        .dest_out(dest_out)
    );

    // =========================================================
    // Golden model helpers
    // =========================================================
    function [7:0] sat16_to_8;
        input [15:0] x;
        begin
            if ($signed(x) > 127)
                sat16_to_8 = 8'sd127;
            else if ($signed(x) < -128)
                sat16_to_8 = -8'sd128;
            else
                sat16_to_8 = x[7:0];
        end
    endfunction

    function [15:0] sat32_to_16;
        input [31:0] x;
        begin
            if ($signed(x) > 32767)
                sat32_to_16 = 16'sd32767;
            else if ($signed(x) < -32768)
                sat32_to_16 = -16'sd32768;
            else
                sat32_to_16 = x[15:0];
        end
    endfunction

    function [63:0] golden_packsswb;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_packsswb[7:0]   = sat16_to_8(d[15:0]);
            golden_packsswb[15:8]  = sat16_to_8(d[31:16]);
            golden_packsswb[23:16] = sat16_to_8(d[47:32]);
            golden_packsswb[31:24] = sat16_to_8(d[63:48]);

            golden_packsswb[39:32] = sat16_to_8(s[15:0]);
            golden_packsswb[47:40] = sat16_to_8(s[31:16]);
            golden_packsswb[55:48] = sat16_to_8(s[47:32]);
            golden_packsswb[63:56] = sat16_to_8(s[63:48]);
        end
    endfunction

    function [63:0] golden_packssdw;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_packssdw[15:0]   = sat32_to_16(d[31:0]);
            golden_packssdw[31:16]  = sat32_to_16(d[63:32]);
            golden_packssdw[47:32]  = sat32_to_16(s[31:0]);
            golden_packssdw[63:48]  = sat32_to_16(s[63:32]);
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // =========================================================
    // Tasks
    // =========================================================
    task check_packsswb;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in    = d;
            src_in     = s;
            pack_size  = 1'b0;
            #5;
            expected = golden_packsswb(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PACKSSWB]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PACKSSWB] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    task check_packssdw;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in    = d;
            src_in     = s;
            pack_size  = 1'b1;
            #5;
            expected = golden_packssdw(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PACKSSDW]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PACKSSDW] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    integer i;

    initial begin

        // -----------------------------------------------------
        // Directed tests: PACKSSWB
        // lanes from low to high:
        // d0, d1, d2, d3 / s0, s1, s2, s3
        // -----------------------------------------------------

        // d: 127, 128, -128, -129
        // s: 0, 1, 200, -200
        check_packsswb(
            {16'hff7f, 16'hff80, 16'h0080, 16'h007f},
            {16'hff38, 16'h00c8, 16'h0001, 16'h0000}
        );

        check_packsswb(
            64'h000A_FFF6_0032_FF9C,   // 10, -10, 50, -100
            64'h7FFF_8000_0080_FF80    // sat+, sat-, +128, -128
        );

        // -----------------------------------------------------
        // Directed tests: PACKSSDW
        // -----------------------------------------------------

        // d: 32767, 32768
        // s: -32768, -32769
        check_packssdw(
            {32'h00008000, 32'h00007fff},
            {32'hffff7fff, 32'hffff8000}
        );

        check_packssdw(
            {32'd100, -32'd100},
            {32'd100000, -32'd100000}
        );

        // -----------------------------------------------------
        // Random tests
        // -----------------------------------------------------
        for (i = 0; i < 100; i = i + 1) begin
            check_packsswb({$random, $random}, {$random, $random});
        end

        for (i = 0; i < 100; i = i + 1) begin
            check_packssdw({$random, $random}, {$random, $random});
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end

endmodule