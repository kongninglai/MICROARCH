`timescale 1ns / 1ps

module tb_br_target();

    // 1. Inputs
    reg [31:0] o_eip;

    // 2. Outputs
    wire hit;
    wire [31:0] bp_eip_target;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    br_target uut (
        .o_eip(o_eip),
        .hit(hit),
        .bp_eip_target(bp_eip_target)
    );

    // 4. Checking Task
    task check_result;
        input [8*25:1] test_name; 
        input exp_hit;
        input [31:0] exp_target;
        begin
            #5; // Wait 5ns for combinational logic to propagate
            if (hit === exp_hit && bp_eip_target === exp_target) begin
                $display("  ✅ PASS | %0s | Hit: %b | Target: %h", test_name, hit, bp_eip_target);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: Hit=%b | Target=%h", exp_hit, exp_target);
                $display("     ACTUAL  : Hit=%b | Target=%h", hit, bp_eip_target);
                FAILURES = FAILURES + 1;
            end
            #5; // Padding before next test
        end
    endtask

    // 5. Stimulus
    initial begin
        $dumpfile("br_target_tb.vpd");
        $dumpvars(0, tb_br_target);

        $display("=======================================");
        $display("     BRANCH TARGET (BTB) STUB TEST     ");
        $display("=======================================");

        // --------------------------------------------------------
        // TEST 1: Standard PC
        // Expected: hit = 0, target = 0000_1000
        // --------------------------------------------------------
        o_eip = 32'h0000_1000;
        check_result("Standard Address   ", 1'b0, 32'h0000_1000);

        // --------------------------------------------------------
        // TEST 2: High Address
        // Expected: hit = 0, target = FFFF_FFFF
        // --------------------------------------------------------
        o_eip = 32'hFFFF_FFFF;
        check_result("High Address       ", 1'b0, 32'hFFFF_FFFF);

        // --------------------------------------------------------
        // TEST 3: Random Address
        // Expected: hit = 0, target = 1234_5678
        // --------------------------------------------------------
        o_eip = 32'h1234_5678;
        check_result("Random Address     ", 1'b0, 32'h1234_5678);

        // --------------------------------------------------------
        // TEST 4: Zero Address
        // Expected: hit = 0, target = 0000_0000
        // --------------------------------------------------------
        o_eip = 32'h0000_0000;
        check_result("Zero Address       ", 1'b0, 32'h0000_0000);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule