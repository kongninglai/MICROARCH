`timescale 1ns / 1ps

module tb_logic_seg_ov();

    // 1. Signals to connect to the Design Under Test (DUT)
    reg is_es0, is_es1, is_es2, is_es3;
    reg is_cs0, is_cs1, is_cs2, is_cs3;
    reg is_ss0, is_ss1, is_ss2, is_ss3;
    reg is_ds0, is_ds1, is_ds2, is_ds3;
    reg is_fs0, is_fs1, is_fs2, is_fs3;
    reg is_gs0, is_gs1, is_gs2, is_gs3;
    reg is_any_p0, is_any_p1, is_any_p2, is_any_p3;
    
    wire is_seg_ov;
    wire [2:0] seg_id;

    // 2. Instantiate the DUT
    logic_seg_ov dut (
        .is_es0(is_es0), .is_es1(is_es1), .is_es2(is_es2), .is_es3(is_es3),
        .is_cs0(is_cs0), .is_cs1(is_cs1), .is_cs2(is_cs2), .is_cs3(is_cs3),
        .is_ss0(is_ss0), .is_ss1(is_ss1), .is_ss2(is_ss2), .is_ss3(is_ss3),
        .is_ds0(is_ds0), .is_ds1(is_ds1), .is_ds2(is_ds2), .is_ds3(is_ds3),
        .is_fs0(is_fs0), .is_fs1(is_fs1), .is_fs2(is_fs2), .is_fs3(is_fs3),
        .is_gs0(is_gs0), .is_gs1(is_gs1), .is_gs2(is_gs2), .is_gs3(is_gs3),
        .is_any_prefix0(is_any_p0), .is_any_prefix1(is_any_p1), 
        .is_any_prefix2(is_any_p2), .is_any_prefix3(is_any_p3),
        .is_seg_ov(is_seg_ov),
        .segment_override_reg_id(seg_id)
    );

    // 3. Task for checking results to keep the code clean
    // Replace 'string' with a large enough reg array (e.g., 32 characters/256 bits)
    task check_results(input expected_ov, input [2:0] expected_id, input [255:0] test_name);
        begin
            #5; 
            if (is_seg_ov !== expected_ov || (expected_ov && seg_id !== expected_id)) begin
                // Using %s will still work for the reg array
                $display("FAIL: %s | Expected OV: %b ID: %d | Got OV: %b ID: %d", 
                        test_name, expected_ov, expected_id, is_seg_ov, seg_id);
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    // 4. Stimulus Logic
    initial begin
        // Initialize all inputs to 0
        {is_es0, is_es1, is_es2, is_es3} = 4'b0;
        {is_cs0, is_cs1, is_cs2, is_cs3} = 4'b0;
        {is_ss0, is_ss1, is_ss2, is_ss3} = 4'b0;
        {is_ds0, is_ds1, is_ds2, is_ds3} = 4'b0;
        {is_fs0, is_fs1, is_fs2, is_fs3} = 4'b0;
        {is_gs0, is_gs1, is_gs2, is_gs3} = 4'b0;
        {is_any_p0, is_any_p1, is_any_p2, is_any_p3} = 4'b0;

        $display("Starting Segment Override Tests...");

        // TEST 1: No prefixes active
        check_results(1'b0, 3'd0, "No Prefix Test");

        // TEST 2: ES prefix in slot 0
        is_es0 = 1; 
        check_results(1'b1, 3'd0, "ES in Slot 0");

        // TEST 3: CS prefix in slot 2 (requires prefix0 and prefix1 to be active)
        is_es0 = 0; // Reset
        is_any_p0 = 1; is_any_p1 = 1; is_cs2 = 1;
        check_results(1'b1, 3'd1, "CS in Slot 2");

        // TEST 4: Priority Test (GS in slot 0, ES in slot 1)
        // Since GS has higher index (5) than ES (0), GS should win in the encoder.
        is_gs0 = 1; is_any_p0 = 1; is_es1 = 1;
        check_results(1'b1, 3'd5, "Priority Test (GS wins)");

        // TEST 5: Verify segment override bit triggers for FS
        is_gs0 = 0; is_any_p0 = 0; is_es1 = 0; is_cs2 = 0; is_any_p1 = 0;
        is_fs3 = 1; is_any_p0 = 1; is_any_p1 = 1; is_any_p2 = 1;
        check_results(1'b1, 3'd4, "FS in Slot 3");

        $display("Tests Completed.");
        $finish;
    end

endmodule