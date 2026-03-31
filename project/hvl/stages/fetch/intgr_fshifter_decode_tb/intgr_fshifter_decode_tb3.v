`timescale 1ns / 1ps

module tb_intgr_fshifter_decode_rigorous();

    // ---------------------------------------------------------
    // 0. Parameters & Signals
    // ---------------------------------------------------------
    localparam CYCLE_TIME = 500;

    reg clk;
    reg rst_bar;

    // Fetch/Buffer Signals
    reg shft_reg_we;
    reg [127:0] from_f_cache_line;
    reg from_f_icache_valid;
    reg from_wb_flush;

    // Decode Signals
    reg [31:0] from_ex_eip_target;
    reg from_rr_stall;
    reg from_ex_br_t_nt;
    reg from_ex_br_valid;
    reg from_ex_flush;
    reg [3:0] from_ex_pht_idx;
    reg from_f_cl_pf;

    // Outputs
    wire [1:0] to_rr_exception_flags;
    wire [31:0] to_rr_i_eip, to_rr_o_eip, to_rr_bp_target;
    wire to_rr_pr_valid;
    wire [5:0] to_rr_prefixes;
    wire [7:0] to_rr_opcode, to_rr_modrm, to_rr_sib;
    wire [1:0] to_rr_disp_size_mux, to_rr_addressing_mode;
    wire [31:0] to_rr_disp;
    wire [2:0] to_rr_imm_size;
    wire [47:0] to_rr_imm;
    wire [3:0] to_rr_instr_length;

    integer FAILURES = 0;
    integer SUCCESSES = 0;
    integer i;

    // ---------------------------------------------------------
    // 1. Instantiation
    // ---------------------------------------------------------
    intgr_fshifter_decode uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .shft_reg_we(shft_reg_we),
        .from_f_cache_line(from_f_cache_line),
        .from_f_icache_valid(from_f_icache_valid),
        .from_wb_flush(from_wb_flush),
        .from_ex_eip_target(from_ex_eip_target),
        .from_rr_stall(from_rr_stall),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_flush(from_ex_flush),
        .from_ex_pht_idx(from_ex_pht_idx),
        .from_f_cl_pf(from_f_cl_pf),

        .to_rr_exception_flags(to_rr_exception_flags),
        .to_rr_i_eip(to_rr_i_eip),
        .to_rr_o_eip(to_rr_o_eip),
        .to_rr_bp_target(to_rr_bp_target),
        .to_rr_pr_valid(to_rr_pr_valid),
        .to_rr_prefixes(to_rr_prefixes),
        .to_rr_opcode(to_rr_opcode),
        .to_rr_modrm(to_rr_modrm),
        .to_rr_sib(to_rr_sib),
        .to_rr_disp_size_mux(to_rr_disp_size_mux),
        .to_rr_disp(to_rr_disp),
        .to_rr_imm_size(to_rr_imm_size),
        .to_rr_imm(to_rr_imm),
        .to_rr_addressing_mode(to_rr_addressing_mode),
        .to_rr_instr_length(to_rr_instr_length)
    );

    // ---------------------------------------------------------
    // 2. Clock & Tasks
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CYCLE_TIME / 2) clk = ~clk;
    end

    // Wipe the cache line clean with NOPs (blocking assigns)
    task clear_cache_line;
        integer b;
        begin
            for (b = 0; b < 16; b = b + 1) begin
                from_f_cache_line[b*8 +: 8] = 8'h90;
            end
        end
    endtask

    // Set a single byte in the cache line (blocking assign)
    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            from_f_cache_line[byte_idx*8 +: 8] = byte_val;
        end
    endtask

    task check_rr_stage;
        input [8*40:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
            if (to_rr_pr_valid === exp_valid &&
               (exp_valid == 0 ||
                (to_rr_opcode === exp_opcode &&
                 (to_rr_modrm === exp_modrm || to_rr_addressing_mode === 2'b00)
                )
               )) begin
                $display("  PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  FAIL | %0s", test_name);
                $display("     EXPECTED: Valid=%b | Opcode=%h | ModRM=%h", exp_valid, exp_opcode, exp_modrm);
                $display("     ACTUAL  : Valid=%b | Opcode=%h | ModRM=%h | AddrMode=%b", to_rr_pr_valid, to_rr_opcode, to_rr_modrm, to_rr_addressing_mode);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // Helper: print first N bytes of shifter output
    task print_shifter_bytes;
        input integer num_bytes;
        integer idx;
        begin
            $write("DEBUG -> Shifter Bytes: ");
            for (idx = 0; idx < num_bytes; idx = idx + 1) begin
                $write("[%0d]:%h ", idx, uut.to_de_outbytes[idx*8 +: 8]);
            end
            $display("");
        end
    endtask

    // ---------------------------------------------------------
    // 3. Stimulus Sequence
    // ---------------------------------------------------------
    initial begin
        $vcdplusfile("intgr_fshifter_decode.vpd");
        $vcdpluson(0, tb_intgr_fshifter_decode_rigorous);

        $display("=================================================");
        $display("   RIGOROUS FRONT-END EDGE CASE STRESS TEST      ");
        $display("=================================================");

        // ---- Time 0 Initialization (blocking for instant setup) ----
        rst_bar = 0;
        shft_reg_we = 0;
        from_f_icache_valid = 0;
        from_wb_flush = 0;
        from_ex_flush = 0;
        from_rr_stall = 0;
        from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0;
        from_ex_br_t_nt = 0;
        from_ex_br_valid = 0;
        from_ex_pht_idx = 4'h0;
        from_f_cache_line = {16{8'h90}};

        // Hold reset for 1 cycle
        #(CYCLE_TIME);

        // Release reset at negedge
        @(negedge clk);
        rst_bar <= 1;

        // Wait 1 cycle for fb_req_cl_stable DFF to propagate
        // (needs one posedge after reset deasserts to latch gated_load_request=1)
        @(negedge clk);

        // =========================================================
        // SCENARIO 1: LONG DECODE & BOUNDARY CROSSING
        // =========================================================
        // Cache line layout (byte 0 = first instruction byte):
        //   Bytes 0-12: NOP (0x90)  -- 13 single-byte NOPs
        //   Byte 13:    0x05       -- ADD EAX, imm32 opcode
        //   Byte 14:    0xAA       -- imm32 byte 0
        //   Byte 15:    0xBB       -- imm32 byte 1  (incomplete: needs 5 bytes, has 3)
        // =========================================================
        $display("\n--- SCENARIO 1: Incomplete Instruction at Boundary ---");

        // Build cache line (all blocking assigns - no race conditions)
        clear_cache_line();
        load_cache_byte(13, 8'h05); // ADD EAX, imm32
        load_cache_byte(14, 8'hAA); // imm byte 0
        load_cache_byte(15, 8'hBB); // imm byte 1

        $write("DEBUG -> LOADING CACHE LINE: ");
        for (i = 0; i < 16; i = i + 1) begin
            $write("%h ", from_f_cache_line[i*8 +: 8]);
        end
        $display("");

        // Assert cache line valid and enable shift register
        // shft_reg_we MUST stay 1 throughout normal decode operation!
        // It gates ALL shift register operations (load AND shift).
        from_f_icache_valid <= 1;
        shft_reg_we <= 1;

        @(negedge clk);
        // Deassert icache_valid (cache line consumed), but keep shft_reg_we=1!
        from_f_icache_valid <= 0;
        // shft_reg_we stays 1 -- this is critical for shift register to advance

        @(negedge clk); // Pipeline latency: posedge loads shift_reg, next posedge latches de_to_rr

        // Decode 13 NOPs (shift register advances by 1 byte each cycle)
        for (i = 0; i < 13; i = i + 1) begin
            $display("Cycle %0d | Tail Ptr: %0d | Instr Length: %0d",
                     i+1, uut.FETCH_BUFF.tail_ptr, to_rr_instr_length);

            check_rr_stage("Decoding NOP", 1'b1, 8'h90, 8'h00);
            @(negedge clk);
        end

        // After 13 NOPs consumed: tail_ptr = 16-13 = 3
        // Shift register now has {05, AA, BB} at front
        // ADD EAX,imm32 needs 5 bytes but only 3 available -> invalid
        $display("---------------------------------------------------------");
        $display("DEBUG: Boundary Hit!");
        $display("       -> Tail Ptr: %0d", uut.FETCH_BUFF.tail_ptr);
        $display("       -> Instr Length Needed: %0d", to_rr_instr_length);
        print_shifter_bytes(6);
        $display("---------------------------------------------------------");

        check_rr_stage("Incomplete ADD (Wait)", 1'b0, 8'h00, 8'h00);


        // =========================================================
        // SCENARIO 2: LOAD 2ND CACHE LINE & JUMP GAUNTLET
        // =========================================================
        // The hardware left-shifts the new cache line by tail_ptr (=3),
        // so cache byte 0 lands at shift_reg[3], byte 1 at shift_reg[4], etc.
        // Therefore: put continuation bytes starting at BYTE 0 of the new line.
        //
        // Cache line layout:
        //   Byte 0: 0xCC  -- imm32 byte 2 (continuation of ADD)
        //   Byte 1: 0xDD  -- imm32 byte 3 (ADD complete!)
        //   Byte 2: 0xEB  -- JMP rel8
        //   Byte 3: 0x05  -- JMP displacement (+5)
        //   Byte 4: 0x74  -- JE rel8
        //   Byte 5: 0x02  -- JE displacement (+2)
        //   Bytes 6-15: NOP
        //
        // After merge, shift_reg = {05, AA, BB, CC, DD, EB, 05, 74, 02, 90...}
        // =========================================================
        $display("\n--- SCENARIO 2: Line Merge & Jump Gauntlet ---");

        @(negedge clk);
        clear_cache_line();
        load_cache_byte(0, 8'hCC); // imm byte 2
        load_cache_byte(1, 8'hDD); // imm byte 3 (ADD complete!)
        load_cache_byte(2, 8'hEB); // JMP rel8
        load_cache_byte(3, 8'h05); // JMP displacement
        load_cache_byte(4, 8'h74); // JE rel8
        load_cache_byte(5, 8'h02); // JE displacement

        from_f_icache_valid <= 1;
        // shft_reg_we already 1

        @(negedge clk);
        from_f_icache_valid <= 0;

        @(negedge clk); // Pipeline propagate

        $display("---------------------------------------------------------");
        print_shifter_bytes(8);
        $display("       -> EXPECTING first 8: 05 aa bb cc dd eb 05 74");
        $display("---------------------------------------------------------");

        check_rr_stage("Completed ADD EAX", 1'b1, 8'h05, 8'h00);

        @(negedge clk);
        check_rr_stage("Decoded JMP", 1'b1, 8'hEB, 8'h00);

        @(negedge clk);
        check_rr_stage("Decoded JE", 1'b1, 8'h74, 8'h00);


        // =========================================================
        // SCENARIO 3: FLUSH AND TARGETED LOAD
        // =========================================================
        // After flush, tail_ptr resets to 0 and shift_reg is cleared.
        // The upstream fetch stage (not part of this integration) handles
        // EIP-to-cache-line offset. We always provide the target instruction
        // starting at BYTE 0 of the cache line.
        // =========================================================
        $display("\n--- SCENARIO 3: Targeted Flush ---");

        from_ex_flush <= 1;
        from_ex_eip_target <= 32'h2;

        @(negedge clk);
        from_ex_flush <= 0;

        @(negedge clk);
        check_rr_stage("Post-Flush Empty", 1'b0, 8'h00, 8'h00);

        // Load cache line with JMP at byte 0 (not at EIP offset!)
        clear_cache_line();
        load_cache_byte(0, 8'hEB); // JMP rel8
        load_cache_byte(1, 8'h05); // displacement

        from_f_icache_valid <= 1;
        // shft_reg_we already 1

        @(negedge clk);
        from_f_icache_valid <= 0;

        @(negedge clk); // Pipeline propagate
        check_rr_stage("Targeted Load (Starts at JMP)", 1'b1, 8'hEB, 8'h00);


        // =========================================================
        // SCENARIO 4: THE "EVERYTHING EVERYWHERE" COMBO TEST
        // =========================================================
        $display("\n--- SCENARIO 4: Stall & Flush Override ---");

        // Stall: shft_reg_we must go to 0 during stall to prevent
        // the shift register from shifting while tail_ptr is held
        from_rr_stall <= 1;
        shft_reg_we <= 0;

        @(negedge clk);
        check_rr_stage("Stalled (Holding JMP)", 1'b1, 8'hEB, 8'h00);

        // Flush while stalled
        from_ex_flush <= 1;
        from_ex_eip_target <= 32'h4;

        @(negedge clk);
        from_ex_flush <= 0;
        from_rr_stall <= 0;
        shft_reg_we <= 1; // Re-enable shift register after stall

        @(negedge clk);
        check_rr_stage("Flush Overrode Stall", 1'b0, 8'h00, 8'h00);

        // Reload with JE at byte 0
        clear_cache_line();
        load_cache_byte(0, 8'h74); // JE rel8
        load_cache_byte(1, 8'h02); // displacement

        from_f_icache_valid <= 1;

        @(negedge clk);
        from_f_icache_valid <= 0;

        @(negedge clk); // Pipeline propagate
        check_rr_stage("Recovered to JE", 1'b1, 8'h74, 8'h00);


        // =========================================================
        // SCENARIO 5: PAGE FAULT EXCEPTION TEST
        // =========================================================
        $display("\n--- SCENARIO 5: Page Fault Exception ---");

        // Flush first to get clean state
        from_ex_eip_target <= 32'h0;
        from_ex_flush <= 1;

        @(negedge clk);
        from_ex_flush <= 0;

        @(negedge clk);
        // Load a NOP with page fault flag
        clear_cache_line();
        load_cache_byte(0, 8'h90); // NOP at byte 0
        from_f_cl_pf <= 1;
        from_f_icache_valid <= 1;

        @(negedge clk);
        from_f_cl_pf <= 0;
        from_f_icache_valid <= 0;

        @(negedge clk); // Pipeline propagate
        check_rr_stage("Decode PF Instruction", 1'b1, 8'h90, 8'h00);

        if (to_rr_exception_flags[0] === 1'b1) begin
            $display("  PASS | Page Fault Propagated");
            SUCCESSES = SUCCESSES + 1;
        end else begin
            $display("  FAIL | Page Fault Missing (flags=%b)", to_rr_exception_flags);
            FAILURES = FAILURES + 1;
        end

        // ---------------------------------------------------------
        // FINAL SUMMARY
        // ---------------------------------------------------------
        $display("\n=================================================");
        if (FAILURES == 0) begin
            $display("  ALL TESTS PASSED! Rigorous Verification Complete.");
        end else begin
            $display("  %0d TESTS FAILED! Check waveforms.", FAILURES);
        end
        $display("=================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule
