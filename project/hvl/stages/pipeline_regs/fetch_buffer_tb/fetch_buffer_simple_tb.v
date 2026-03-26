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
    integer total_fails = 0;

    // DUT Instantiation
    fetch_buffer uut (
        .clk(clk), .rst_bar(rst_bar),
        .from_de_instr_len(instr_len), .from_de_valid(de_valid),
        .from_f_icache_valid(f_icache_valid),
        .from_wb_flush(flush_wb), .from_ex_flush(flush_ex),
        .from_de_stall(stall), .from_f_cl_pf(cl_pf),
        .from_f_cache_line(cache_line), .i_eip(32'h0),
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
            $display("MASTER EN (shift_reg_en): %b | WE MASK (gated): %b", uut.shift_reg_en, uut.wr_en);
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
                total_fails = total_fails + 1;
            end 
            else if (outbytes[63:0] !== exp_data[63:0]) begin
                $display("[%t] ❌ FAIL: %0s | Data Mismatch!", $time, test_name);
                $display("      Exp: %h", exp_data[63:0]);
                $display("      Got: %h", outbytes[63:0]);
                total_fails = total_fails + 1;
            end
            else begin
                $display("[%t] ✅ PASS: %0s", $time, test_name);
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
        cache_line = 128'h0807060504030201; 

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
        cache_line = 128'h0B0A000000000000; 
        
        @(posedge clk); 
        #2 verify("Buffer Topped Up", 5'd29, 128'h0000000807060504);

        // 6. FLUSH TEST
        @(negedge clk);
        flush_wb = 1;
        
        @(posedge clk); 
        #2 verify("Flush Logic", 5'd0, 128'h0);
        flush_wb = 0;

        $display("\n========================================");
        if (total_fails == 0) $display("  ✅ SUCCESS: All Tests Passed");
        else $display("  ❌ FAILURE: %0d tests failed", total_fails);
        $display("========================================\n");
        $finish;
    end

endmodule