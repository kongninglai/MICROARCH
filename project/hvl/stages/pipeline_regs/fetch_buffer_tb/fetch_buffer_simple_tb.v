`timescale 1ns / 1ps

module fetch_buffer_simple_tb;

    // ---------------------------------------------------------
    // DUT I/O
    // ---------------------------------------------------------
    reg clk, rst_bar, de_valid, flush_wb, flush_ex, redir, stall, cl_pf, shft_reg_we;
    reg f_icache_valid; 
    reg [3:0] instr_len;
    reg [127:0] cache_line;

    wire [4:0]  tail_ptr;
    wire [127:0] outbytes;
    wire [15:0]  pf_out;
    wire ready;

    integer total_tests = 0;
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // DUT Instantiation
    fetch_buffer uut (
        .clk(clk), .rst_bar(rst_bar),
        .from_de_instr_len(instr_len), .from_de_valid(de_valid),
        .from_f_icache_valid(f_icache_valid),
        .from_wb_flush(flush_wb), .from_ex_flush(flush_ex),
        .from_de_stall(stall), .from_f_cl_pf(cl_pf),
        .from_f_cache_line(cache_line), 
        .from_de_eip_redirection(redir), .shft_reg_we(shft_reg_we),
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
        // 1. ALL REGS INITIALIZED TO ZERO (Prevents 'X' propagation)
        clk = 0; rst_bar = 0; de_valid = 0; instr_len = 0; stall = 0;
        f_icache_valid = 0; flush_wb = 0; flush_ex = 0; redir = 0; 
        cl_pf = 0; shft_reg_we = 1; cache_line = 0;

        // 2. STABLE RESET
        // Hold reset for several cycles to clear structural registers
        repeat (5) @(posedge clk);
        #1 rst_bar = 1; 
        #1 verify("Reset State", 5'd0, 128'h0);

        // 3. LOAD FIRST CACHE LINE (2-Cycle Turnaround)
        @(negedge clk);
        f_icache_valid = 1; 
        // ORIGINAL LE: 128'h0807060504030201 (implicitly padded with 0s at the top)
        // BIG ENDIAN: Byte 0 (01) is at the MSB [127:120], Byte 1 (02) at [119:112], etc.
        cache_line = 128'h0102030405060708_0000000000000000; 

        // Cycle 1: Request registers (fb_req_cl_stable goes 1)
        @(posedge clk); 
        // Cycle 2: Data latches into buffer
        @(posedge clk); 
        #2 verify("First CL Loaded", 5'd16, 128'h0807060504030201);

        // 4. CONSUME 3 BYTES
        @(negedge clk);
        de_valid = 1; instr_len = 3;
        
        @(posedge clk); 
        #2 verify("Consumed 3", 5'd13, 128'h0000000807060504);
        
        @(negedge clk);
        de_valid = 0;

        // 5. TOP-UP (Load while buffer has 13 bytes)
        // Note: Stable Req is already high because 13 < 16
        @(negedge clk);
        // ORIGINAL LE: 128'h0B0A000000000000
        // BIG ENDIAN: Bytes 0-5 are 00. Byte 6 (0A) at [79:72], Byte 7 (0B) at [71:64].
        cache_line = 128'h0000000000000A0B_0000000000000000; 
        
        @(posedge clk); 
        #2 verify("Buffer Topped Up", 5'd29, 128'h0000000807060504);

        // 6. FLUSH TEST
        @(negedge clk);
        flush_wb = 1;
        
        @(posedge clk); 
        #2 verify("Flush Logic", 5'd0, 128'h0);
        flush_wb = 0;

        // =========================================================
        // EXTRA TESTS: shft_reg_we = 0 Behavior (BIG ENDIAN INPUT)
        // =========================================================
        $display("\n=== STARTING shft_reg_we = 0 COMPREHENSIVE TESTS ===");

        // --- Setup Baseline ---
        // Reset and load a fresh cache line so the buffer has 16 bytes.
        @(negedge clk);
        rst_bar = 0; 
        @(negedge clk);
        rst_bar = 1;
        f_icache_valid = 1;
        shft_reg_we = 1; // Briefly enable to load the baseline
        
        // BIG ENDIAN: Byte 0 is '01' at [127:120], Byte 15 is '10' at [7:0]
        cache_line = 128'h0102030405060708_090A0B0C0D0E0F10; 
        @(posedge clk); @(posedge clk);
        f_icache_valid = 0;
        
        // ---------------------------------------------------------
        // INDIVIDUAL SIGNAL TESTS (shft_reg_we = 0)
        // ---------------------------------------------------------
        
        // 1. de_valid = 1, instr_len = 7
        @(negedge clk);
        shft_reg_we = 1; // LOCK THE GATE
        de_valid = 1; instr_len = 7; stall = 0;
        @(posedge clk); #2;
        // CORRECT BEHAVIOR: Buffer shifts out 7 bytes (Bytes 0-6: 01 through 07).
        // Remaining Bytes 7-15 (08 through 10) shift down to [71:0].
        // Byte 7 ('08') is now at [7:0].
        verify("Indiv: shft_we=0, consume 7", 5'd9, 128'h0000000000000010_0F0E0D0C0B0A0908);
        
        // 2. de_valid = 1, instr_len = 8 (to drain the rest minus 1 byte)
        @(negedge clk);
        shft_reg_we = 0; // LOCK THE GATE
        de_valid = 1; instr_len = 8; stall = 0;
        @(posedge clk); #2;
        // CORRECT BEHAVIOR: Buffer shifts out 8 more bytes. Tail pointer goes 9 -> 1.
        // Only Byte 15 ('10') is left at [7:0].
        verify("Indiv: shft_we=0, consume 8", 5'd1, 128'h0000000000000000_0000000000000010);

        // 3. f_icache_valid = 1 (Attempting to top-up when we=0)
        @(negedge clk);
        de_valid = 0; instr_len = 0;
        f_icache_valid = 1; // Try to load
        // Byte 0 is 'FF', the rest are '00'
        cache_line = 128'hFF00000000000000_0000000000000000;
        @(posedge clk); @(posedge clk); #2;
        // CORRECT BEHAVIOR: Since it had 1 byte, it loads 15 new bytes. 
        // The old byte ('10') stays at index 0 [7:0]. 
        // The new Byte 0 ('FF') goes to index 1 [15:8].
        verify("Indiv: shft_we=0, f_icache_valid=1", 5'd16, 128'h0000000000000000_000000000000FF10); 

        // 4. flush_wb = 1
        @(negedge clk);
        f_icache_valid = 0;
        flush_wb = 1;
        @(posedge clk); #2;
        // CORRECT BEHAVIOR: Buffer flushes instantly regardless of shft_reg_we
        verify("Indiv: shft_we=0, flush_wb=1", 5'd0, 128'h0);
        flush_wb = 0;

        // ---------------------------------------------------------
        // COMBINATIONAL TESTS (shft_reg_we = 0)
        // ---------------------------------------------------------

        // Setup Baseline again
        @(negedge clk);
        rst_bar = 0; @(negedge clk); rst_bar = 1;
        f_icache_valid = 1; shft_reg_we = 1;
        // Byte 0 = 11, Byte 1 = 22, ... Byte 15 = 00
        cache_line = 128'h1122334455667788_99AABBCCDDEEFF00; 
        @(posedge clk); @(posedge clk); f_icache_valid = 0;

        // 5. Consume (de_valid=1, len=4) + Stall = 1
        @(negedge clk);
        shft_reg_we = 0; // LOCK THE GATE
        de_valid = 1; instr_len = 4; stall = 1;
        @(posedge clk); #2;
        // CORRECT BEHAVIOR: Stall overrides valid. Buffer does NOT shift. 
        verify("Combo: shft_we=0, consume 4, stall=1", 5'd16, 128'h00FFEEDDCCBBAA99_8877665544332211);

        // 6. Consume (de_valid=1, len=4) + Load (f_icache_valid=1)
        @(negedge clk);
        stall = 0; 
        de_valid = 1; instr_len = 4; // Will consume Bytes 0-3 (11, 22, 33, 44)
        f_icache_valid = 1; 
        // New Byte 0,1,2,3 = FF. Rest = 00.
        cache_line = 128'hFFFFFFFF00000000_0000000000000000;
        @(posedge clk); @(posedge clk); #2;
        // CORRECT BEHAVIOR: Shifts out 4 bytes (indices 0-3). Old bytes 4-15 shift down to indices 0-11.
        // The 4 new 'FF' bytes drop into the newly opened indices 12-15 [127:96].
        verify("Combo: shft_we=0, consume 4 + load", 5'd28, 128'hFFFFFFFF00FFEEDD_CCBBAA9988776655);

        // 7. Consume (de_valid=1, len=7) + Redir/Flush (redir=1)
        @(negedge clk);
        de_valid = 1; instr_len = 7;
        redir = 1; // Decode branch taken
        @(posedge clk); #2;
        // CORRECT BEHAVIOR: Redir acts as a flush for the fetch buffer. It should clear.
        verify("Combo: shft_we=0, consume 7 + redir=1", 5'd0, 128'h0);

        // Cleanup
        @(negedge clk);
        de_valid = 0; instr_len = 0; redir = 0; f_icache_valid = 0; shft_reg_we = 1;

        $display("\n========================================");
        if (FAILURES == 0) $display("  ✅ SUCCESS: All Tests Passed");
        else $display("  ❌ FAILURE: %0d tests failed", FAILURES);
        $display("========================================\n");
        
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule