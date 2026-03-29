`timescale 1ns/1ps

module tb_ex_padd;

    reg  [63:0] dest_in;
    reg  [63:0] src_in;
    reg         padd_size;
    wire [63:0] dest_out;

    ex_padd dut (
        .dest_in(dest_in),
        .src_in(src_in),
        .padd_size(padd_size),
        .dest_out(dest_out)
    );

    // ---------------------------------------------------------
    // Golden models
    // ---------------------------------------------------------
    function [63:0] golden_paddw;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_paddw[15:0]   = d[15:0]   + s[15:0];
            golden_paddw[31:16]  = d[31:16]  + s[31:16];
            golden_paddw[47:32]  = d[47:32]  + s[47:32];
            golden_paddw[63:48]  = d[63:48]  + s[63:48];
        end
    endfunction

    function [63:0] golden_paddd;
        input [63:0] d;
        input [63:0] s;
        begin
            golden_paddd[31:0]   = d[31:0]   + s[31:0];
            golden_paddd[63:32]  = d[63:32]  + s[63:32];
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // ---------------------------------------------------------
    // Tasks
    // ---------------------------------------------------------
    task check_paddw;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in   = d;
            src_in    = s;
            padd_size = 1'b0;
            #8;
            expected = golden_paddw(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PADDW]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PADDW] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    task check_paddd;
        input [63:0] d;
        input [63:0] s;
        reg   [63:0] expected;
        begin
            dest_in   = d;
            src_in    = s;
            padd_size = 1'b1;
            #8;
            expected = golden_paddd(d, s);

            if (dest_out !== expected) begin
                FAILURES = FAILURES + 1;
                $display("[FAIL][PADDD]");
                $display("  dest_in  = 0x%016h", d);
                $display("  src_in   = 0x%016h", s);
                $display("  dest_out = 0x%016h", dest_out);
                $display("  expected = 0x%016h", expected);
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
                // $display("[PASS][PADDD] dest_in=0x%016h src_in=0x%016h out=0x%016h",
                //          d, s, dest_out);
            end
        end
    endtask

    integer i;

    initial begin

        // -----------------------------------------------------
        // Directed tests for PADDW
        // -----------------------------------------------------

        // simple
        check_paddw(64'h0001_0002_0003_0004, 64'h0001_0001_0001_0001);

        // wrap-around in 16-bit lanes
        check_paddw(64'hffff_7fff_8000_1234, 64'h0001_0001_8000_edcc);

        // mixed values
        check_paddw(64'h1111_2222_3333_4444, 64'h0101_0202_0303_0404);

        // all zeros
        check_paddw(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000);

        // -----------------------------------------------------
        // Directed tests for PADDD
        // -----------------------------------------------------

        // simple
        check_paddd(64'h00000001_00000002, 64'h00000003_00000004);

        // wrap-around in 32-bit lanes
        check_paddd(64'hffffffff_7fffffff, 64'h00000001_00000001);

        // mixed values
        check_paddd(64'h12345678_9abcdef0, 64'h11111111_22222222);

        // all zeros
        check_paddd(64'h00000000_00000000, 64'h00000000_00000000);

        // -----------------------------------------------------
        // Random tests
        // -----------------------------------------------------
        for (i = 0; i < 100; i = i + 1) begin
            check_paddw({$random, $random}, {$random, $random});
        end

        for (i = 0; i < 100; i = i + 1) begin
            check_paddd({$random, $random}, {$random, $random});
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end

endmodule