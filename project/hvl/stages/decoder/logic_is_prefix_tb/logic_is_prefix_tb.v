`timescale 1ns/1ps

module logic_is_prefix_tb();

    // 1. Signals
    reg  [7:0] candidate_prefix;
    wire       is_rep, is_op_size, is_ext, is_es, is_cs, is_ss, is_ds, is_fs, is_gs;
    wire       is_any_prefix;
    
    // Self-checking variables
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 2. Instantiate the Unit Under Test (UUT)
    logic_is_prefix uut (
        .candidate_prefix(candidate_prefix),
        .is_rep(is_rep),
        .is_operand_size_override(is_op_size),
        .is_ext_opcode(is_ext),
        .is_es(is_es), .is_cs(is_cs), .is_ss(is_ss),
        .is_ds(is_ds), .is_fs(is_fs), .is_gs(is_gs),
        .is_any_prefix(is_any_prefix)
    );

    // 3. Test Procedure
    initial begin
        $display("\n--- Starting Comprehensive Prefix Decoder Test ---");
        $display("Time\t Input\t Any?\t REP\t OPSZ\t EXT\t Segments (ES|CS|SS|DS|FS|GS)");
        $display("------------------------------------------------------------");

        // --- GROUP 1: NON-PREFIXES (Expect 0) ---
        candidate_prefix = 8'h90; #10; check_results(1'b0); // NOP
        candidate_prefix = 8'h01; #10; check_results(1'b0); // ADD
        candidate_prefix = 8'hFF; #10; check_results(1'b0); // JUNK

        // --- GROUP 2: INSTRUCTION PREFIXES (Expect 1) ---
        candidate_prefix = 8'hF3; #10; check_results(1'b1); // REP
        candidate_prefix = 8'h66; #10; check_results(1'b1); // Operand Size Override
        candidate_prefix = 8'h0F; #10; check_results(1'b1); // 2-byte Escape (EXT_OP)

        // --- GROUP 3: SEGMENT OVERRIDES (Expect 1) ---
        candidate_prefix = 8'h26; #10; check_results(1'b1); // ES
        candidate_prefix = 8'h2E; #10; check_results(1'b1); // CS
        candidate_prefix = 8'h36; #10; check_results(1'b1); // SS
        candidate_prefix = 8'h3E; #10; check_results(1'b1); // DS
        candidate_prefix = 8'h64; #10; check_results(1'b1); // FS
        candidate_prefix = 8'h65; #10; check_results(1'b1); // GS

        $display("------------------------------------------------------------");
        if (error_count == 0) begin
            $display(">>> TEST PASSED: All 12 cases matched correctly. <<<");
        end else begin
            $display(">>> TEST FAILED: %0d errors detected. <<<", error_count);
        end
        $display("------------------------------------------------------------\n");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

    // Helper task to print results and track errors
    task check_results(input expected_any);
        begin
            $display("%0t\t %h\t %b\t %b\t %b\t %b\t %b %b %b %b %b %b", 
                $time, candidate_prefix, is_any_prefix, is_rep, is_op_size, is_ext, 
                is_es, is_cs, is_ss, is_ds, is_fs, is_gs);
            
            if (is_any_prefix !== expected_any) begin
                $display("  !! ERROR: mismatch at input %h! Expected is_any_prefix=%b, got %b", 
                         candidate_prefix, expected_any, is_any_prefix);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end
            else begin
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

endmodule