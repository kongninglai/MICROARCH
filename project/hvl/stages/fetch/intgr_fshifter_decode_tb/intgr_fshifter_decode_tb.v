`timescale 1ns / 1ps

module intgr_fshifter_decode_tb();

    // ---------------------------------------------------------
    // 0. Parameters 
    // ---------------------------------------------------------
    localparam CYCLE_TIME = 200; 

    // ---------------------------------------------------------
    // 1. Inputs (Regs)
    // ---------------------------------------------------------
    reg clk;
    reg rst_bar;

    reg [127:0] from_f_cache_line;
    reg from_f_icache_valid; 
    reg from_wb_flush;

    reg [31:0] from_ex_eip_target;
    reg from_rr_stall;
    reg from_ex_br_t_nt;
    reg from_ex_br_valid;
    reg from_ex_flush;
    reg [3:0] from_ex_pht_idx;
    reg from_f_cl_pf; 

    // ---------------------------------------------------------
    // 2. Outputs (Wires)
    // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // 3. Instantiation
    // ---------------------------------------------------------
    intgr_fshifter_decode uut (
        .clk(clk),
        .rst_bar(rst_bar),

        // --- Fetch Buffer Inputs ---
        .from_f_cache_line(from_f_cache_line),
        .ICACHE_VALID(from_f_icache_valid), 
        .from_wb_flush(from_wb_flush),

        // --- Decode Inputs ---
        .from_ex_eip_target(from_ex_eip_target),
        .from_rr_stall(from_rr_stall),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_flush(from_ex_flush),
        .from_ex_pht_idx(from_ex_pht_idx),
        .from_f_cl_pf(from_f_cl_pf),

        // --- Outputs ---
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
    // 4. Clock and Tasks
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CYCLE_TIME / 2) clk = ~clk; 
    end

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            from_f_cache_line[((15 - byte_idx)*8) +: 8] <= byte_val; 
        end
    endtask

    // NEW TASK: Checks Combinational logic BEFORE the PR_DE_RR register
    task check_pr_stage;
        input [8*35:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
            #1; // Tiny delay to let combinational logic settle
            // We use `uut.to_pr_*` to peek at the internal wires inside the module
            if (uut.to_pr_pr_valid === exp_valid && 
               (exp_valid == 0 || (uut.to_pr_opcode === exp_opcode && uut.to_pr_modrm === exp_modrm))) begin
                $display("  ✅ [PR COMB ] PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ [PR COMB ] FAIL | %0s", test_name);
                $display("     EXPECTED: Valid=%b | Opcode=%h | ModRM=%h", exp_valid, exp_opcode, exp_modrm);
                $display("     ACTUAL  : Valid=%b | Opcode=%h | ModRM=%h", uut.to_pr_pr_valid, uut.to_pr_opcode, uut.to_pr_modrm);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // UPDATED TASK: Checks Latched logic AFTER the PR_DE_RR register
    task check_rr_stage;
        input [8*35:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
            #1; // Tiny delay to align checking 
            if (to_rr_pr_valid === exp_valid && 
               (exp_valid == 0 || (to_rr_opcode === exp_opcode && to_rr_modrm === exp_modrm))) begin
                $display("  ✅ [RR LATCH] PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ [RR LATCH] FAIL | %0s", test_name);
                $display("     EXPECTED: Valid=%b | Opcode=%h | ModRM=%h", exp_valid, exp_opcode, exp_modrm);
                $display("     ACTUAL  : Valid=%b | Opcode=%h | ModRM=%h", to_rr_pr_valid, to_rr_opcode, to_rr_modrm);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // ---------------------------------------------------------
    // 5. Stimulus Sequence
    // ---------------------------------------------------------
    initial begin
        $vcdplusfile("intgr_fshifter_decode.vpd");
        $vcdpluson(0, intgr_fshifter_decode_tb);

        $display("=================================================");
        $display("   FRONT-END INTEGRATION TEST (Fetch -> Decode)  ");
        $display("=================================================");

        rst_bar = 0;
        from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 0;
        from_f_cache_line = 128'h0;
        
        @(negedge clk);
        rst_bar <= 1; // Release reset 

        @(negedge clk); 
        // ==========================================
        // CYCLE 2: Setup Cache Load
        // ==========================================
        load_cache_byte(0, 8'h01); // ADD
        load_cache_byte(1, 8'hC3); // EAX, EBX
        load_cache_byte(2, 8'h89); // MOV 
        load_cache_byte(3, 8'hC8); 

        from_f_icache_valid <= 1;
    
        @(negedge clk); 
        // ==========================================
        // CYCLE 3: Fetch loads cache line
        // ==========================================
        from_f_icache_valid <= 0; 
        
        check_pr_stage("Comb Decode ADD EAX, EBX   ", 1'b1, 8'h01, 8'hC3); 
        
        @(negedge clk); 
        // ==========================================
        // CYCLE 4: RR latches 'ADD'.
        // Combinational decoder shifts to see 'MOV'.
        // ==========================================
        check_rr_stage("Latched RR ADD EAX, EBX    ", 1'b1, 8'h01, 8'hC3); 
        check_pr_stage("Comb Decode MOV            ", 1'b1, 8'h89, 8'hC8);
        
        // DO NOT STALL YET! Let MOV flow into the pipeline register naturally
        
        @(negedge clk); 
        // ==========================================
        // CYCLE 5: RR latches 'MOV'. NOW we lock it down!
        // ==========================================
        check_rr_stage("Latched RR MOV             ", 1'b1, 8'h89, 8'hC8);
        
        from_rr_stall <= 1; // Assert stall so it freezes here!
        
        @(negedge clk); 
        // ==========================================
        // CYCLE 6: Check that RR successfully held 'MOV'
        // ==========================================
        check_rr_stage("Pipeline Stall (Hold MOV)  ", 1'b1, 8'h89, 8'hC8);
        
        from_rr_stall <= 0; // Release stall
        from_ex_flush <= 1; // Send Flush command!
        
        @(negedge clk); 
        // ==========================================
        // CYCLE 7: Check FLUSH
        // ==========================================
        check_rr_stage("Execute Flush (Invalidate) ", 1'b0, 8'h00, 8'h00);
        check_pr_stage("Comb Flush (Invalidate)    ", 1'b0, 8'h00, 8'h00);

        $display("=================================================");
        if (FAILURES == 0) begin
            $display("  🎉 ALL TESTS PASSED! Integration is solid.");
        end else begin
            $display("  💥 %0d TESTS FAILED! Check waveforms.", FAILURES);
        end
        $display("=================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
    
endmodule