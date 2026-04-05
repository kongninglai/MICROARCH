`timescale 1ns / 1ps

module fetch_buffer_simple_tb;

    // ---------------------------------------------------------
    // DUT I/O
    // ---------------------------------------------------------
    reg clk, rst_bar, de_valid, flush_wb, flush_ex, redir, stall, cl_pf;
    reg f_icache_valid; 
    reg [3:0] instr_len;
    reg [3:0] offset;        // ADDED: New offset input
    reg [127:0] cache_line;

    wire [4:0]  tail_ptr;
    wire [127:0] outbytes;
    wire [15:0]  pf_out;
    wire ready;
    wire shft_reg_we; 

    integer total_tests = 0;
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // DUT Instantiation
    fetch_buffer uut (
        .clk(clk), .rst_bar(rst_bar),
        .from_de_instr_len(instr_len), .from_de_valid(de_valid),
        .ICACHE_VALID(f_icache_valid),
        .from_wb_flush(flush_wb), .from_ex_flush(flush_ex),
        .from_de_stall(stall), .from_f_cl_pf(cl_pf),
        .from_f_cache_line(cache_line), 
        .from_de_eip_redirection(redir), 
        .offset(offset),     // ADDED: Wired to DUT
        .shft_reg_we(shft_reg_we), 
        .tail_ptr(tail_ptr), .to_de_outbytes(outbytes),
        .to_de_pf_expn_bytes_out(pf_out), .ready(ready)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // Debug Dump Task
    // ---------------------------------------------------------
    task debug_dump;
        input [8*60:1] label;
        begin
            $display("\n--- [%t] INTERNAL STATE DUMP: %0s ---", $time, label);
            $display("INTERNAL REQ (comp): %b | STABLE REQ (dff): %b | V_CL_LD: %b", 
                     uut.from_de_cache_line_load_signal, uut.fb_req_cl_stable, uut.v_cl_ld);
            $display("TAIL POINTER: %d", tail_ptr);
            $display("MASTER EN (shft_reg_we): %b | WE MASK (gated): %b", shft_reg_we, uut.wr_en);
            $display("------------------------------------------------------------");
        end
    endtask

    // ---------------------------------------------------------
    // Verification Task
    // ---------------------------------------------------------
    task verify;
        input [8*40:1] test_name;
        input [4:0]    exp_tp;
        input [127:0]  exp_data;
        begin
            total_tests = total_tests + 1;
            debug_dump(test_name);
            
            if (tail_ptr !== exp_tp) begin
                $display("[%t] ❌ FAIL: %0s | TP Mismatch! Exp: %0d, Got: %0d", $time, test_name, exp_tp, tail_ptr);
                FAILURES = FAILURES + 1;
            end 
            else if (outbytes[63:0] !== exp_data[63:0]) begin
                $display("[%t] ❌ FAIL: %0s | Data Mismatch!", $time, test_name);
                $display("      Exp: %h", exp_data[63:0]);
                $display("      Got: %h", outbytes[63:0]);
                FAILURES = FAILURES + 1;
            end
            else begin
                $display("[%t] ✅ PASS: %0s", $time, test_name);
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    initial begin
        // 1. ALL REGS INITIALIZED TO ZERO 
        clk = 0; rst_bar = 0; de_valid = 0; instr_len = 0; stall = 0; offset = 0; // Set offset to 0
        f_icache_valid = 0; flush_wb = 0; flush_ex = 0; redir = 0; 
        cl_pf = 0; cache_line = 0;

        // 2. STABLE RESET
        repeat (5) @(posedge clk);
        #1 rst_bar = 1; 
        #1 verify("Reset State", 5'd0, 128'h0);

        // 3. LOAD FIRST CACHE LINE 
        @(negedge clk);
        f_icache_valid = 1; 
        cache_line = 128'h0102030405060708_0000000000000000; 

        @(posedge clk); 
        @(posedge clk); 
        #2 verify("First CL Loaded", 5'd16, 128'h0807060504030201);

        // 4. CONSUME 3 BYTES
        @(negedge clk);
        f_icache_valid = 0; 
        de_valid = 1; instr_len = 3;
        
        @(posedge clk); 
        #2 verify("Consumed 3", 5'd13, 128'h0000000807060504);
        
        @(negedge clk);
        de_valid = 0;

        // 5. TOP-UP 
        @(negedge clk);
        f_icache_valid = 1;
        cache_line = 128'h0000000000000A0B_0000000000000000; 
        
        @(posedge clk); 
        #2 verify("Buffer Topped Up", 5'd29, 128'h0000000807060504);

        // 6. FLUSH TEST
        @(negedge clk);
        f_icache_valid = 0;
        flush_wb = 1;
        
        @(posedge clk); 
        #2 verify("Flush Logic", 5'd0, 128'h0);
        flush_wb = 0;

        // =========================================================
        // EXTRA TESTS (BIG ENDIAN INPUT)
        // =========================================================
        $display("\n=== STARTING COMPREHENSIVE TESTS ===");

        // --- Setup Baseline ---
        @(negedge clk);
        rst_bar = 0; 
        @(negedge clk);
        rst_bar = 1;
        f_icache_valid = 1;
        
        cache_line = 128'h0102030405060708_090A0B0C0D0E0F10; 
        @(posedge clk); @(posedge clk);
        f_icache_valid = 0;
        
        // ---------------------------------------------------------
        // INDIVIDUAL SIGNAL TESTS 
        // ---------------------------------------------------------
        
        // 1. de_valid = 1, instr_len = 7
        @(negedge clk);
        de_valid = 1; instr_len = 7; stall = 0;
        @(posedge clk); #2;
        verify("Indiv: consume 7", 5'd9, 128'h0000000000000010_0F0E0D0C0B0A0908);
        
        // 2. de_valid = 1, instr_len = 8 
        @(negedge clk);
        de_valid = 1; instr_len = 8; stall = 0;
        @(posedge clk); #2;
        verify("Indiv: consume 8", 5'd1, 128'h0000000000000000_0000000000000010);

        // 3. f_icache_valid = 1 
        @(negedge clk);
        de_valid = 0; instr_len = 0;
        f_icache_valid = 1; 
        cache_line = 128'hFF00000000000000_0000000000000000;
        @(posedge clk); @(posedge clk); #2;
        verify("Indiv: Top-up f_icache_valid=1", 5'd17, 128'h0000000000000000_000000000000FF10); 

        // 4. flush_wb = 1
        @(negedge clk);
        f_icache_valid = 0;
        flush_wb = 1;
        @(posedge clk); #2;
        verify("Indiv: flush_wb=1", 5'd0, 128'h0);
        flush_wb = 0;

        // ---------------------------------------------------------
        // COMBINATIONAL TESTS 
        // ---------------------------------------------------------

        // Setup Baseline again
        @(negedge clk);
        rst_bar = 0; @(negedge clk); rst_bar = 1;
        f_icache_valid = 1;
        cache_line = 128'h1122334455667788_99AABBCCDDEEFF00; 
        @(posedge clk); @(posedge clk); f_icache_valid = 0;

        // 5. Consume (de_valid=1, len=4) + Stall = 1
        @(negedge clk);
        de_valid = 1; instr_len = 4; stall = 1;
        @(posedge clk); #2;
        verify("Combo: consume 4, stall=1", 5'd16, 128'h00FFEEDDCCBBAA99_8877665544332211);

        // 6. Drop TP to 12 (Forces fb_req_cl_stable to activate)
        @(negedge clk);
        stall = 0; de_valid = 1; instr_len = 4; f_icache_valid = 0;
        @(posedge clk); #2;
        verify("Combo: Drop TP to 12", 5'd12, 128'h0000000000FFEEDD_CCBBAA9988776655);

        // Wait 1 cycle for fb_req_cl_stable flip flop to latch the 1
        @(negedge clk);
        de_valid = 0; instr_len = 0;
        @(posedge clk); #2;

        // 7. Consume (de_valid=1, len=4) + Load (f_icache_valid=1)
        @(negedge clk);
        de_valid = 1; instr_len = 4; 
        f_icache_valid = 1; 
        cache_line = 128'hFFFFFFFF00000000_0000000000000000;
        @(posedge clk); #2;
        verify("Combo: consume 4 + load", 5'd24, 128'hFFFFFFFF00000000_00FFEEDDCCBBAA99);

        // 8. Consume (de_valid=1, len=7) + Redir/Flush (redir=1)
        @(negedge clk);
        de_valid = 1; instr_len = 7; f_icache_valid = 0;
        redir = 1; // Decode branch taken
        @(posedge clk); #2;
        verify("Combo: consume 7 + redir=1", 5'd0, 128'h0);

        // Cleanup
        @(negedge clk);
        de_valid = 0; instr_len = 0; redir = 0; f_icache_valid = 0;

        $display("\n========================================");
        if (FAILURES == 0) $display("  ✅ SUCCESS: All Tests Passed");
        else $display("  ❌ FAILURE: %0d tests failed", FAILURES);
        $display("========================================\n");
        
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule