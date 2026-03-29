`timescale 1ns/1ps

module ex_aaa_tb;

    reg  [31:0] eax;
    reg         eflags_af;

    wire [31:0] aaa_out;
    wire [31:0] aaa_eflags;
    wire [31:0] aaa_eflags_mask;

    ex_aaa dut (
        .eax(eax),
        .eflags_af(eflags_af),
        .aaa_out(aaa_out),
        .aaa_eflags(aaa_eflags),
        .aaa_eflags_mask(aaa_eflags_mask)
    );

    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;

    function [31:0] ref_out;
        input [31:0] eax_i;
        input        af_i;
        reg   [7:0]  al_i;
        reg   [7:0]  ah_i;
        reg   [7:0]  al_tmp;
        reg   [7:0]  ah_tmp;
        reg          adjust;
        begin
            al_i = eax_i[7:0];
            ah_i = eax_i[15:8];

            adjust = ((al_i[3:0] > 4'd9) || (af_i == 1'b1));

            if (adjust) begin
                al_tmp = al_i + 8'h06;
                ah_tmp = ah_i + 8'h01;
            end else begin
                al_tmp = al_i;
                ah_tmp = ah_i;
            end

            ref_out = {eax_i[31:16], ah_tmp, 4'b0000, al_tmp[3:0]};
        end
    endfunction

    function [31:0] ref_eflags;
        input [31:0] eax_i;
        input        af_i;
        reg   [7:0]  al_i;
        reg          adjust;
        begin
            al_i = eax_i[7:0];
            adjust = ((al_i[3:0] > 4'd9) || (af_i == 1'b1));

            ref_eflags = 32'b0;
            ref_eflags[4] = adjust; // AF
            ref_eflags[0] = adjust; // CF
        end
    endfunction


    task run_test;
        input [255:0] name;
        input [31:0]  t_eax;
        input         t_af;
        reg   [31:0]  exp_out;
        reg   [31:0]  exp_flags;
        reg   [31:0]  exp_mask;
        begin
            eax       = t_eax;
            eflags_af = t_af;

            #8;

            exp_out   = ref_out(t_eax, t_af);
            exp_flags = ref_eflags(t_eax, t_af);
            exp_mask  = {27'b0, 1'b1, 3'b0, 1'b1}; // AF bit4, CF bit0

            if ((aaa_out === exp_out) &&
                (aaa_eflags === exp_flags) &&
                (aaa_eflags_mask === exp_mask)) begin
                SUCCESSES = SUCCESSES + 1;
            end else begin
                FAILURES = FAILURES + 1;
                $display("--------------------------------------------------");
                $display("FAIL: %0s", name);
                $display("eax=0x%08h af_in=%0d", t_eax, t_af);
                $display("aaa_out         = 0x%08h, expected = 0x%08h", aaa_out, exp_out);
                $display("aaa_eflags      = 0x%08h, expected = 0x%08h", aaa_eflags, exp_flags);
                $display("aaa_eflags_mask = 0x%08h, expected = 0x%08h", aaa_eflags_mask, exp_mask);
            end
        end
    endtask

    task run_random_tests;
        input integer n;
        reg [31:0] rand_eax;
        reg        rand_af;
        begin
            for (i = 0; i < n; i = i + 1) begin
                rand_eax = $random;
                rand_af  = $random & 1'b1;
                run_test("random", rand_eax, rand_af);
            end
        end
    endtask

    initial begin

        // No adjust cases
        run_test("AAA no adjust AL=0",        32'h00000000, 1'b0);
        run_test("AAA no adjust AL=5",        32'h00001205, 1'b0);
        run_test("AAA no adjust AL=9",        32'h12345609, 1'b0);

        // Adjust because low nibble > 9
        run_test("AAA adjust AL=0x0A",        32'h0000000A, 1'b0);
        run_test("AAA adjust AL=0x0E",        32'h0000000E, 1'b0);
        run_test("AAA adjust AL=0x1B",        32'h0000121B, 1'b0);

        // Adjust because AF input is 1
        run_test("AAA adjust by AF only",     32'h00003405, 1'b1);
        run_test("AAA adjust AF with AL=9",   32'h00005609, 1'b1);

        // AH increment / carry behavior
        run_test("AAA 9+5 style",             32'h0000000E, 1'b0); // expect AH++, AL=4
        run_test("AAA AH increment wrap",     32'h0000FF0A, 1'b0); // AH wraps if incremented
        run_test("AAA preserve upper 16",     32'hABCD120E, 1'b0);

        // Random
        run_random_tests(300);

        $display("==============================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

        $finish;
    end

endmodule