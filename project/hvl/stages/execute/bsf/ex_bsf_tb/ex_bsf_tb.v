`timescale 1ns/1ps

module tb_ex_bsf;

    reg  [31:0] bsf_data;
    reg  [1:0]  ds;

    wire [31:0] bsf_out;
    wire [31:0] bsf_eflags;
    wire [31:0] bsf_eflags_mask;

    ex_bsf dut (
        .bsf_data(bsf_data),
        .ds(ds),
        .bsf_out(bsf_out),
        .bsf_eflags(bsf_eflags),
        .bsf_eflags_mask(bsf_eflags_mask)
    );

    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;

    function [31:0] width_mask;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b01: width_mask = 32'h0000FFFF;
                2'b10: width_mask = 32'hFFFFFFFF;
                default: width_mask = 32'h00000000;
            endcase
        end
    endfunction

    function ref_zf;
        input [1:0]  ds_i;
        input [31:0] data_i;
        reg   [31:0] masked;
        begin
            masked = data_i & width_mask(ds_i);
            ref_zf = (masked == 32'b0);
        end
    endfunction

    function [31:0] ref_out;
        input [1:0]  ds_i;
        input [31:0] data_i;
        reg   [31:0] masked;
        integer k;
        reg found;
        begin
            masked  = data_i & width_mask(ds_i);
            ref_out = 32'b0;
            found   = 1'b0;

            for (k = 0; k < 32; k = k + 1) begin
                if (!found && masked[k]) begin
                    ref_out = k;
                    found = 1'b1;
                end
            end
        end
    endfunction

    function [31:0] ref_eflags;
        input [1:0]  ds_i;
        input [31:0] data_i;
        reg zf_v;
        begin
            zf_v = ref_zf(ds_i, data_i);
            ref_eflags = 32'b0;
            ref_eflags[6] = zf_v;
        end
    endfunction

    function [31:0] ref_mask;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b01, 2'b10: ref_mask = 32'h0000_0040;
                default:      ref_mask = 32'h0000_0000;
            endcase
        end
    endfunction

    task run_test;
        input [255:0] name;
        input [1:0]   t_ds;
        input [31:0]  t_data;
        reg   [31:0]  exp_out;
        reg   [31:0]  exp_flags;
        reg   [31:0]  exp_mask;
        begin
            ds       = t_ds;
            bsf_data = t_data;

            #5;

            exp_out   = ref_out(t_ds, t_data);
            exp_flags = ref_eflags(t_ds, t_data);
            exp_mask  = ref_mask(t_ds);

            if (((bsf_out === exp_out) || (exp_out == 32'h0)) &&
                (bsf_eflags === exp_flags) &&
                (bsf_eflags_mask === exp_mask)) begin
                SUCCESSES = SUCCESSES + 1;
            end else begin
                FAILURES = FAILURES + 1;
                $display("--------------------------------------------------");
                $display("FAIL: %0s", name);
                $display("ds=%b data=0x%08h", t_ds, t_data);
                $display("bsf_out         = 0x%08h, expected = 0x%08h", bsf_out, exp_out);
                $display("bsf_eflags      = 0x%08h, expected = 0x%08h", bsf_eflags, exp_flags);
                $display("bsf_eflags_mask = 0x%08h, expected = 0x%08h", bsf_eflags_mask, exp_mask);
            end
        end
    endtask

    task run_random_tests;
        input integer n;
        reg [1:0]  rand_ds;
        reg [31:0] rand_data;
        begin
            for (i = 0; i < n; i = i + 1) begin
                rand_ds = ($random & 1) ? 2'b01 : 2'b10;
                rand_data = $random;
                run_test("random", rand_ds, rand_data);
            end
        end
    endtask

    initial begin

        // 16-bit tests
        run_test("BSF16 zero",     2'b01, 32'h00000000);
        run_test("BSF16 bit0",     2'b01, 32'h00000001);
        run_test("BSF16 bit1",     2'b01, 32'h00000002);
        run_test("BSF16 bit8",     2'b01, 32'h00000100);
        run_test("BSF16 bit15",    2'b01, 32'h00008000);
        run_test("BSF16 mixed",    2'b01, 32'h00008220); // lowest 1 at bit5

        // 32-bit tests
        run_test("BSF32 zero",     2'b10, 32'h00000000);
        run_test("BSF32 bit0",     2'b10, 32'h00000001);
        run_test("BSF32 bit5",     2'b10, 32'h00000020);
        run_test("BSF32 bit16",    2'b10, 32'h00010000);
        run_test("BSF32 bit31",    2'b10, 32'h80000000);
        run_test("BSF32 mixed",    2'b10, 32'h90000020); // lowest 1 at bit5


        // random
        run_random_tests(500);

        $display("==============================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end

endmodule