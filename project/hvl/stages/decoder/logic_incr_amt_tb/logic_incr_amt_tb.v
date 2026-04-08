`timescale 1ns / 1ps

module tb_logic_incr_amt();

    // 1. Signals matching the logic_incr_amt ports
    reg  [7:0] opcode;          // <--- ADDED OPCODE REG
    reg  [2:0] rom_sum;
    reg  [2:0] disp_plus_sib;
    reg  [2:0] prefix_amount;
    wire [3:0] incr_amt;

    // 2. Instantiate the Unit Under Test (UUT)
    logic_incr_amt uut (
        .opcode(opcode),        // <--- MAPPED OPCODE
        .rom_sum(rom_sum),
        .disp_plus_sib(disp_plus_sib),
        .prefix_amount(prefix_amount),
        .incr_amt(incr_amt)
    );

    // 3. Test Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i, j, k, l;
    
    // Golden reference calculation
    reg [3:0] expected_val;

    // Array to hold the halt/ret opcodes for testing
    reg [7:0] end_opcodes [0:5];

    initial begin
        // Initialize the end opcodes array
        end_opcodes[0] = 8'hF4; // HLT
        end_opcodes[1] = 8'hC3; // RET near
        end_opcodes[2] = 8'hCB; // RET far
        end_opcodes[3] = 8'hC2; // RET near16
        end_opcodes[4] = 8'hCA; // RET far16
        end_opcodes[5] = 8'hCF; // IRET

        $display("---------------------------------------------------------");
        $display("STARTING INSTRUCTION LENGTH DECODER VERIFICATION");
        $display("---------------------------------------------------------");

        // Set opcode to a normal instruction so end_program logic doesn't trigger
        opcode = 8'h00; 

        // Loop through all possible combinations (8 * 8 * 8 = 512 total tests)
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    // Set Inputs
                    rom_sum       = i[2:0];
                    disp_plus_sib = j[2:0];
                    prefix_amount = k[2:0];

                    // Wait for maximum arrival time + gate delays.
                    #15;

                    // Calculate Golden Value
                    expected_val = rom_sum + disp_plus_sib + prefix_amount;

                    // Check Result
                    if (incr_amt !== expected_val) begin
                        $display("❌ FAIL | Rom:%d Disp+SIB:%d Pref:%d | Got Length: %d | Exp: %d", 
                                  rom_sum, disp_plus_sib, prefix_amount, incr_amt, expected_val);
                        FAILURES = FAILURES + 1;
                    end else begin
                        SUCCESSES = SUCCESSES + 1;
                    end
                end
            end
        end

        // ---------------------------------------------------------
        // NEW TEST CASES: End Program Opcodes
        // ---------------------------------------------------------
        $display("---------------------------------------------------------");
        $display("STARTING END-PROGRAM OPCODE VERIFICATION");
        $display("---------------------------------------------------------");

        // Set the lengths to maximum to ensure we have a non-zero candidate
        rom_sum       = 3'b111;
        disp_plus_sib = 3'b111;
        prefix_amount = 3'b111;
        expected_val  = 4'b0000; // We expect 0 for all of these!

        for (l = 0; l < 6; l = l + 1) begin
            opcode = end_opcodes[l];
            
            #15; // Wait for logic to settle

            if (incr_amt !== expected_val) begin
                $display("❌ FAIL | Opcode: %h | Got Length: %d | Exp: %d", 
                          opcode, incr_amt, expected_val);
                FAILURES = FAILURES + 1;
            end else begin
                $display("✅ PASS | Opcode: %h | Got Length: %d", opcode, incr_amt);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        // 4. Final Report
        $display("---------------------------------------------------------");
        $display("DECODER ADDER SUMMARY:");
        $display("  TOTAL TESTS: %0d", FAILURES + SUCCESSES);
        $display("  SUCCESSES:   %0d", SUCCESSES);
        $display("  FAILURES:    %0d", FAILURES);
        
        if (FAILURES == 0)
            $display("🎉 VERIFICATION PASSED: The top-level length decoder is perfect!");
        else
            $display("💥 VERIFICATION FAILED: Check your logic gates and wiring.");
        $display("---------------------------------------------------------");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule