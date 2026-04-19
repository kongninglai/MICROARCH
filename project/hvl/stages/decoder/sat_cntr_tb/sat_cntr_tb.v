`timescale 1ns / 1ps

module tb_sat_cntr;

    reg CurState1, CurState0, Incr_or_Decr;
    wire dut_out1, dut_out0;
    wire behav_out1, behav_out0;

    sat_cntr DUT(
        .CurState1(CurState1), .CurState0(CurState0), .Incr_or_Decr(Incr_or_Decr), 
        .NextState1(dut_out1), .NextState0(dut_out0)
    );

    sat_cntr_behav DUT_golden(
        .CurState1(CurState1), .CurState0(CurState0), .Incr_or_Decr(Incr_or_Decr), 
        .NextState1(behav_out1), .NextState0(behav_out0)
    );

    integer i;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {CurState1, CurState0, Incr_or_Decr} = i;
            #10; // Wait for outputs to stabilize
            if ({dut_out1, dut_out0} !== {behav_out1, behav_out0}) begin
                $display("FAIL: Mismatch at input %b: DUT output = %b, Expected output = %b", {CurState1, CurState0, Incr_or_Decr}, {dut_out1, dut_out0}, {behav_out1, behav_out0});
                FAILURES = FAILURES + 1;
            end else begin
                $display("PASS: Match at input %b: Output = %b", {CurState1, CurState0, Incr_or_Decr}, {dut_out1, dut_out0});
                SUCCESSES = SUCCESSES + 1;
            end
        end
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule