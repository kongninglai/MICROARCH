`timescale 1ns / 1ps

module tb_logic_seg_ov();

    reg is_es0, is_es1, is_es2;
    reg is_cs0, is_cs1, is_cs2;
    reg is_ss0, is_ss1, is_ss2;
    reg is_ds0, is_ds1, is_ds2;
    reg is_fs0, is_fs1, is_fs2;
    reg is_gs0, is_gs1, is_gs2;
    reg is_any_p0, is_any_p1;
    
    wire is_seg_ov;
    wire [2:0] seg_id;

    integer FAILURES = 0;
    integer SUCCESSES = 0;

    logic_seg_ov dut (
        .is_es0(is_es0), .is_es1(is_es1), .is_es2(is_es2),
        .is_cs0(is_cs0), .is_cs1(is_cs1), .is_cs2(is_cs2),
        .is_ss0(is_ss0), .is_ss1(is_ss1), .is_ss2(is_ss2),
        .is_ds0(is_ds0), .is_ds1(is_ds1), .is_ds2(is_ds2),
        .is_fs0(is_fs0), .is_fs1(is_fs1), .is_fs2(is_fs2),
        .is_gs0(is_gs0), .is_gs1(is_gs1), .is_gs2(is_gs2),
        .is_any_prefix0(is_any_p0), .is_any_prefix1(is_any_p1), 
        .is_seg_ov(is_seg_ov),
        .segment_override_reg_id(seg_id)
    );

    // Modified check_results to ALWAYS check the ID
    task check_results(input expected_ov, input [2:0] expected_id, input [255:0] test_name);
        begin
            #5; 
            if (is_seg_ov !== expected_ov || seg_id !== expected_id) begin
                $display("FAIL: %s | Expected OV: %b ID: %d | Got OV: %b ID: %d", 
                        test_name, expected_ov, expected_id, is_seg_ov, seg_id);
                FAILURES = FAILURES + 1;
            end else begin
                $display("PASS: %s (OV: %b, ID: %d)", test_name, is_seg_ov, seg_id);
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin
        // Reset all inputs
        {is_es0, is_es1, is_es2} = 3'b0;
        {is_cs0, is_cs1, is_cs2} = 3'b0;
        {is_ss0, is_ss1, is_ss2} = 3'b0;
        {is_ds0, is_ds1, is_ds2} = 3'b0;
        {is_fs0, is_fs1, is_fs2} = 3'b0;
        {is_gs0, is_gs1, is_gs2} = 3'b0;
        {is_any_p0, is_any_p1} = 2'b0;

        $display("Starting Segment Override Tests...");

        // TEST 1: No prefixes active (Verifies the MUX selects DS=3)
        check_results(1'b0, 3'd3, "Default DS Test (No Prefix)");

        // TEST 2: ES prefix in slot 0 (Valid bit high, MUX selects ES=0)
        is_es0 = 1; 
        check_results(1'b1, 3'd0, "ES Override");

        // TEST 3: CS prefix in slot 2 
        is_es0 = 0; 
        is_any_p0 = 1; is_any_p1 = 1; is_cs2 = 1;
        check_results(1'b1, 3'd1, "CS Override");

        // TEST 4: Priority Test (GS wins over ES)
        is_gs0 = 1; is_any_p0 = 1; is_es1 = 1;
        check_results(1'b1, 3'd5, "Priority Test (GS wins)");

        // TEST 5: Verify segment override bit triggers for FS
        is_gs0 = 0; is_any_p0 = 0; is_es1 = 0; is_cs2 = 0; is_any_p1 = 0;
        is_fs2 = 1; is_any_p0 = 1; is_any_p1 = 1;
        check_results(1'b1, 3'd4, "FS Override");

        // TEST 6: Transition back to default (Clear all inputs)
        {is_fs2, is_any_p0, is_any_p1} = 3'b0;
        check_results(1'b0, 3'd3, "Return to Default DS");

        $display("----------------------------------------");
        $display("Tests Completed.");
        $display("SUCCESSES: %d", SUCCESSES);
        $display("FAILURES:  %d", FAILURES);
        $display("----------------------------------------");

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

        $finish;
    end

endmodule