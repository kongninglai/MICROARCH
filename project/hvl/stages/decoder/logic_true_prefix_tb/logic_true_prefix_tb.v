`timescale 1ns/1ps

module logic_true_prefix_tb();

    // Inputs
    reg [7:0] candidate_prefix0;
    reg [7:0] candidate_prefix1;
    reg [7:0] candidate_prefix2;
    reg [7:0] candidate_prefix3;

    // Outputs
    wire is_rep_true;
    wire is_operand_size_override_true;
    wire is_seg_ov;
    wire [2:0] seg_id;
    wire ext_op_true;
    wire [2:0] prefix_num;

    // Error Tracking
    integer errors;

    // Instantiate the Unit Under Test (UUT)
    logic_true_prefix uut (
        .candidate_prefix0(candidate_prefix0),
        .candidate_prefix1(candidate_prefix1),
        .candidate_prefix2(candidate_prefix2),
        .candidate_prefix3(candidate_prefix3),
        .is_rep_true(is_rep_true),
        .is_operand_size_override_true(is_operand_size_override_true),
        .is_seg_ov(is_seg_ov),
        .seg_id(seg_id),
        .ext_op_true(ext_op_true),
        .prefix_num(prefix_num)
    );

    // Self-Checking Task
    task test_instruction(
        input [7:0] b0, input [7:0] b1, input [7:0] b2, input [7:0] b3, 
        input [2:0] exp_count, 
        input exp_rep, 
        input exp_op_size, 
        input exp_ext, 
        input exp_seg_ov, 
        input [2:0] exp_seg_id, 
        input [127:0] test_name
    );
        begin
            candidate_prefix0 = b0;
            candidate_prefix1 = b1;
            candidate_prefix2 = b2;
            candidate_prefix3 = b3;
            
            #5; // Wait for combinational logic to settle (2.04ns + margin)
            
            // Compare results
            if ((prefix_num !== exp_count) || (is_rep_true !== exp_rep) || 
                (is_operand_size_override_true !== exp_op_size) || 
                (ext_op_true !== exp_ext) || (is_seg_ov !== exp_seg_ov) || 
                (is_seg_ov && (seg_id !== exp_seg_id))) begin 
                
                $display("ERROR at %0t: %s", $time, test_name);
                $display("  Bytes: [%h] [%h] [%h] [%h]", b0, b1, b2, b3);
                $display("  EXPECTED: Count=%d, REP=%b, OpSz=%b, Ext=%b, SegOv=%b (ID:%d)", 
                         exp_count, exp_rep, exp_op_size, exp_ext, exp_seg_ov, exp_seg_id);
                $display("  ACTUAL  : Count=%d, REP=%b, OpSz=%b, Ext=%b, SegOv=%b (ID:%d)", 
                         prefix_num, is_rep_true, is_operand_size_override_true, ext_op_true, is_seg_ov, seg_id);
                
                // --- INTERNAL WIRE DEBUGGING FOR FAILURES ---
                $display("\n  >>> INTERNAL HARDWARE STATE <<<");
                $display("  Stage 1 (is_any)        : [0]:%b [1]:%b [2]:%b [3]:%b", 
                         uut.is_any0, uut.is_any1, uut.is_any2, uut.is_any3);
                $display("  Stage 2 (is_any_actual) : [0]:%b [1]:%b [2]:%b [3]:%b", 
                         uut.is_any0_actual, uut.is_any1_actual, uut.is_any2_actual, uut.is_any3_actual);
                $display("  CS Override Bits        : [0]:%b [1]:%b [2]:%b [3]:%b",
                         uut.is_cs0, uut.is_cs1, uut.is_cs2, uut.is_cs3);
                $display("  ------------------------------------------------\n");

                errors = errors + 1;
            end else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("==================================================");
        $display("   Starting Self-Checking logic_true_prefix TB");
        $display("==================================================\n");

        $display("--- Testing All Segment Overrides (Byte 0) ---");
        test_instruction(8'h26, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd0, "Seg ES (0x26)");
        test_instruction(8'h2E, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd1, "Seg CS (0x2E)");
        test_instruction(8'h36, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd2, "Seg SS (0x36)");
        test_instruction(8'h3E, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd3, "Seg DS (0x3E)");
        test_instruction(8'h64, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd4, "Seg FS (0x64)");
        test_instruction(8'h65, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd5, "Seg GS (0x65)");

        $display("\n--- Testing Single Prefix in All 4 Positions ---");
        test_instruction(8'h2E, 8'h90, 8'h90, 8'h90,  3'd1, 0, 0, 0, 1, 3'd1, "CS at Byte 0");
        test_instruction(8'h90, 8'h2E, 8'h90, 8'h90,  3'd0, 0, 0, 0, 0, 3'd0, "CS at Byte 1 (Ignored)");
        test_instruction(8'h90, 8'h90, 8'h2E, 8'h90,  3'd0, 0, 0, 0, 0, 3'd0, "CS at Byte 2 (Ignored)");
        test_instruction(8'h90, 8'h90, 8'h90, 8'h2E,  3'd0, 0, 0, 0, 0, 3'd0, "CS at Byte 3 (Ignored)");

        $display("\n--- Testing 2-Prefix Combinations (OpSize 66 + CS 2E) ---");
        test_instruction(8'h66, 8'h2E, 8'h90, 8'h90,  3'd2, 0, 1, 0, 1, 3'd1, "Contiguous Byte 0,1");
        test_instruction(8'h66, 8'h90, 8'h2E, 8'h90,  3'd1, 0, 1, 0, 0, 3'd0, "Byte 0,2 (Gap kills byte 2)");
        test_instruction(8'h90, 8'h66, 8'h2E, 8'h90,  3'd0, 0, 0, 0, 0, 3'd0, "Byte 1,2 (Unaligned kills all)");
        
        $display("\n--- Testing 3 & 4 Prefix Combinations ---");
        test_instruction(8'h66, 8'hF3, 8'h2E, 8'h90,  3'd3, 1, 1, 0, 1, 3'd1, "3 Contiguous Prefixes");
        test_instruction(8'h66, 8'hF3, 8'h2E, 8'h0F,  3'd4, 1, 1, 1, 1, 3'd1, "4 Contiguous Prefixes");

        if (errors == 0) begin
            $display("\n************************************");
            $display("   TEST PASSED: All %0d checks OK!  ", errors); 
            $display("************************************");
        end else begin
            $display("\n************************************");
            $display("   TEST FAILED: %0d errors found.   ", errors);
            $display("************************************");
        end

        #10;
        $finish;
    end

endmodule