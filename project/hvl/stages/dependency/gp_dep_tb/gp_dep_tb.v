`timescale 1ns/1ps

module gp_dep_tb;

    reg  [2:0] dstA_id;
    reg  [2:0] dstB_id;
    reg        ld_dstA;
    reg        ld_dstB;
    reg  [1:0] dstA_size;
    reg  [1:0] dstB_size;
    reg  [2:0] src_id;
    reg  [1:0] src_size;
    reg        ld_src;

    wire       dep;

    integer    errors;

    gp_dep dut (
        .dstA_id   (dstA_id),
        .dstB_id   (dstB_id),
        .ld_dstA   (ld_dstA),
        .ld_dstB   (ld_dstB),
        .dstA_size (dstA_size),
        .dstB_size (dstB_size),
        .src_id    (src_id),
        .src_size  (src_size),
        .ld_src    (ld_src),
        .dep       (dep)
    );

    function [2:0] ref_pid;
        input [2:0] idx;
        input [1:0] size;
        begin
            if (size == 2'b00)
                ref_pid = {1'b0, idx[1:0]};
            else
                ref_pid = idx;
        end
    endfunction

    function ref_dep;
        input [2:0] dstA_id_f;
        input [2:0] dstB_id_f;
        input       ld_dstA_f;
        input       ld_dstB_f;
        input [1:0] dstA_size_f;
        input [1:0] dstB_size_f;
        input [2:0] src_id_f;
        input [1:0] src_size_f;
        input       ld_src_f;

        reg [2:0] dstA_pid_f, dstB_pid_f, src_pid_f;
        reg depA_f, depB_f;
        begin
            dstA_pid_f = ref_pid(dstA_id_f, dstA_size_f);
            dstB_pid_f = ref_pid(dstB_id_f, dstB_size_f);
            src_pid_f  = ref_pid(src_id_f , src_size_f );

            depA_f = ld_src_f & ld_dstA_f & (src_pid_f == dstA_pid_f);
            depB_f = ld_src_f & ld_dstB_f & (src_pid_f == dstB_pid_f);

            ref_dep = (depA_f | depB_f);
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    task run_case;
        input [2:0] t_dstA_id;
        input [2:0] t_dstB_id;
        input       t_ld_dstA;
        input       t_ld_dstB;
        input [1:0] t_dstA_size;
        input [1:0] t_dstB_size;
        input [2:0] t_src_id;
        input [1:0] t_src_size;
        input       t_ld_src;

        reg expected;
        reg [2:0] dstA_pid_dbg, dstB_pid_dbg, src_pid_dbg;
        begin
            dstA_id   = t_dstA_id;
            dstB_id   = t_dstB_id;
            ld_dstA   = t_ld_dstA;
            ld_dstB   = t_ld_dstB;
            dstA_size = t_dstA_size;
            dstB_size = t_dstB_size;
            src_id    = t_src_id;
            src_size  = t_src_size;
            ld_src    = t_ld_src;

            #3;

            expected = ref_dep(
                t_dstA_id, t_dstB_id, t_ld_dstA, t_ld_dstB,
                t_dstA_size, t_dstB_size,
                t_src_id, t_src_size, t_ld_src
            );

            dstA_pid_dbg = ref_pid(t_dstA_id, t_dstA_size);
            dstB_pid_dbg = ref_pid(t_dstB_id, t_dstB_size);
            src_pid_dbg  = ref_pid(t_src_id , t_src_size );

            if (dep !== expected) begin
                $display("FAIL");
                $display("  dstA_id=%0d dstA_size=%b -> dstA_pid=%0d ld_dstA=%b",
                         t_dstA_id, t_dstA_size, dstA_pid_dbg, t_ld_dstA);
                $display("  dstB_id=%0d dstB_size=%b -> dstB_pid=%0d ld_dstB=%b",
                         t_dstB_id, t_dstB_size, dstB_pid_dbg, t_ld_dstB);
                $display("  src_id =%0d src_size =%b -> src_pid =%0d ld_src =%b",
                         t_src_id, t_src_size, src_pid_dbg, t_ld_src);
                $display("  expected=%b got=%b",
                         expected, dep);
                FAILURES = FAILURES + 1;
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("gp_dep_tb.vcd");
        $dumpvars(0, gp_dep_tb);

        repeat (1 << 8) begin
            run_case($random, $random, $random, $random, $random, $random, $random, $random, $random);
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule