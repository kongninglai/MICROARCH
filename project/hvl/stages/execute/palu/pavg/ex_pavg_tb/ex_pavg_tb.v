`timescale 1ns/1ps

module tb_ex_pavg;

    reg  [63:0] dest_in;
    reg  [63:0] src_in;
    reg         pavg_size;   // 0: PAVGB, 1: PAVGW
    wire [63:0] dest_out;

    ex_pavg dut (
        .dest_in(dest_in),
        .src_in(src_in),
        .pavg_size(pavg_size),
        .dest_out(dest_out)
    );

    // ---------------------------------------------------------
    // Golden model helpers
    // ---------------------------------------------------------
    function [7:0] avg_u8;
        input [7:0] a;
        input [7:0] b;
        reg   [8:0] sum;
        begin
            sum = {1'b0, a} + {1'b0, b} + 9'd1;
            avg_u8 = sum[8:1];
        end
    endfunction

    function [15:0] avg_u16;
        input [15:0] a;
        input [15:0] b;
        reg   [16:0] sum;
        begin
            sum = {1'b0, a} + {1'b0, b} + 17'd1;
            avg_u16 = sum[16:1];
        end
    endfunction

    function [63:0] golden_pavgb;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_pavgb[7:0]   = avg_u8(d[7:0],   s[7:0]);
            golden_pavgb[15:8]  = avg_u8(d[15:8],  s[15:8]);
            golden_pavgb[23:16] = avg_u8(d[23:16], s[23:16]);
            golden_pavgb[31:24] = avg_u8(d[31:24], s[31:24]);
            golden_pavgb[39:32] = avg_u8(d[39:32], s[39:32]);
            golden_pavgb[47:40] = avg_u8(d[47:40], s[47:40]);
            golden_pavgb[55:48] = avg_u8(d[55:48], s[55:48]);
            golden_pavgb[63:56] = avg_u8(d[63:56], s[63:56]);
        end
    endfunction

    function [63:0] golden_pavgw;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_pavgw[15:0]   = avg_u16(d[15:0],   s[15:0]);
            golden_pavgw[31:16]  = avg_u16(d[31:16],  s[31:16]);
            golden_pavgw[47:32]  = avg_u16(d[47:32],  s[47:32]);
            golden_pavgw[63:48]  = avg_u16(d[63:48],  s[63:48]);
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // ---------------------------------------------------------
    // Tasks
    // ---------------------------------------------------------
    task check_pavgb;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in   = d;
            src_in    = s;
            pavg_size = 1'b0;
            #8;
            expected = golden_pavgb(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PAVGB]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PAVGB] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    task check_pavgw;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in   = d;
            src_in    = s;
            pavg_size = 1'b1;
            #8;
            expected = golden_pavgw(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PAVGW]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PAVGW] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    integer i;

    initial begin

        // -----------------------------------------------------
        // Directed tests: PAVGB
        // -----------------------------------------------------
        check_pavgb(64'h0000000000000000, 64'h0000000000000000);
        check_pavgb(64'hffffffffffffffff, 64'hffffffffffffffff);
        check_pavgb(64'h0101010101010101, 64'h0000000000000000); // rounding
        check_pavgb(64'h0001020304050607, 64'h0102030405060708);
        check_pavgb(64'hff00ff00ff00ff00, 64'h00ff00ff00ff00ff);
        check_pavgb(64'h7f8081fe01020304, 64'h0101010101010101);

        // -----------------------------------------------------
        // Directed tests: PAVGW
        // -----------------------------------------------------
        check_pavgw(64'h0000000000000000, 64'h0000000000000000);
        check_pavgw(64'hffffffffffffffff, 64'hffffffffffffffff);
        check_pavgw(64'h0001000100010001, 64'h0000000000000000); // rounding
        check_pavgw(64'h0001000200030004, 64'h0002000300040005);
        check_pavgw(64'hffff0000ffff0000, 64'h0000ffff0000ffff);
        check_pavgw(64'h7fff800000010002, 64'h0001000100010001);

        // -----------------------------------------------------
        // Random tests
        // -----------------------------------------------------
        for (i = 0; i < 100; i = i + 1) begin
            check_pavgb({$random, $random}, {$random, $random});
        end

        for (i = 0; i < 100; i = i + 1) begin
            check_pavgw({$random, $random}, {$random, $random});
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end

endmodule