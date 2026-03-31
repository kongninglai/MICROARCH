`timescale 1ns / 1ps

module tb_intgr_fshifter_decode_comprehensive();

    // ---------------------------------------------------------
    // 0. Parameters 
    // ---------------------------------------------------------
    localparam CYCLE_TIME = 100; 

    // ---------------------------------------------------------
    // 1. Inputs (Regs)
    // ---------------------------------------------------------
    reg clk;
    reg rst_bar;

    reg shft_reg_we; 
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
            from_f_cache_line[(byte_idx*8) +: 8] = byte_val;
        end
    endtask

    task check_rr_stage;
        input [8*35:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
            if (to_rr_pr_valid === exp_valid && 
               (exp_valid == 0 || (to_rr_opcode === exp_opcode && to_rr_modrm === exp_modrm))) begin
                $display("  ✅ PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
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
        $vcdplusfile("intgr_comprehensive.vpd");
        $vcdpluson(0, tb_intgr_fshifter_decode_comprehensive);

        $display("=================================================");
        $display("   COMPREHENSIVE FRONT-END INTEGRATION TEST      ");
        $display("=================================================");

        // Initialization 
        rst_bar = 0;
        shft_reg_we = 0; from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 0;
        from_f_cache_line = 128'h0;

        #(CYCLE_TIME);
        rst_bar = 1;

        // Align to just before the posedge 
        #(1.4 * CYCLE_TIME); 

        // =========================================================
        // SCENARIO 1: BASIC SEQUENTIAL EXECUTION
        // =========================================================
        $display("\n--- SCENARIO 1: Basic Sequential Fetch & Decode ---");
        
        load_cache_byte(0, 8'h01); // ADD
        load_cache_byte(1, 8'hC3); // EAX, EBX
        load_cache_byte(2, 8'h89); // MOV 
        load_cache_byte(3, 8'hC8); // EAX, ECX

        from_f_icache_valid = 1; 
        shft_reg_we = 1;
        
        #(CYCLE_TIME); // Latch Cache Line
        from_f_icache_valid = 0; 

        #(CYCLE_TIME); // Propagate Decoder
        check_rr_stage("Decode Instr 1 (ADD)       ", 1'b1, 8'h01, 8'hC3);
        
        #(CYCLE_TIME); // Shift buffer naturally handles MOV
        check_rr_stage("Decode Instr 2 (MOV)       ", 1'b1, 8'h89, 8'hC8);


        // =========================================================
        // SCENARIO 2: PIPELINE STALL (BACKPRESSURE)
        // =========================================================
        $display("\n--- SCENARIO 2: Pipeline Stall & Recovery ---");
        from_rr_stall = 1;
        shft_reg_we = 0; 
        
        #(CYCLE_TIME);
        check_rr_stage("Stall Cycle 1 (Hold MOV)   ", 1'b1, 8'h89, 8'hC8);
        
        #(CYCLE_TIME);
        check_rr_stage("Stall Cycle 2 (Hold MOV)   ", 1'b1, 8'h89, 8'hC8);
        
        from_rr_stall = 0; 
        shft_reg_we = 1; 

        #(CYCLE_TIME);
        check_rr_stage("Post-Stall Recovery (ADD)  ", 1'b1, 8'h00, 8'h00); // 00 00 is ADD


        // =========================================================
        // SCENARIO 3: EXECUTE MISPREDICT FLUSH & MULTI-BYTE LOAD
        // =========================================================
        $display("\n--- SCENARIO 3: Mispredict Flush & Refetch ---");
        from_ex_flush = 1;
        
        #(CYCLE_TIME);
        check_rr_stage("Pipeline Invalidated       ", 1'b0, 8'h00, 8'h00);
        
        // Setup the Refetch
        from_ex_flush = 0;
        from_f_cache_line = 128'h0;
        
        // Instruction 1: MOV (2 bytes)
        load_cache_byte(0, 8'h8B); // MOV r32, r/m32
        load_cache_byte(1, 8'h11); // EDX, [ECX]
        
        // Instruction 2: ADD EAX, imm32 (5 bytes)
        load_cache_byte(2, 8'h05); // Opcode
        load_cache_byte(3, 8'h11); // Imm Byte 1
        load_cache_byte(4, 8'h22); // Imm Byte 2
        load_cache_byte(5, 8'h33); // Imm Byte 3
        load_cache_byte(6, 8'h44); // Imm Byte 4
        
        from_f_icache_valid = 1;
        
        #(CYCLE_TIME); // Latch new Cache Line
        from_f_icache_valid = 0;
        
        #(CYCLE_TIME); // Propagate Decoder
        check_rr_stage("Post-Flush Fetch (MOV)     ", 1'b1, 8'h8B, 8'h11);


        // =========================================================
        // SCENARIO 4: MULTI-BYTE INSTRUCTION DECODE
        // =========================================================
        $display("\n--- SCENARIO 4: Multi-Byte Instruction Flow ---");
        
        #(CYCLE_TIME); // Fetch Buffer naturally shifts past the MOV!
        
        // The hardware blindly routes the byte following the opcode to the ModRM wire.
        // For '05 11 22 33 44', the next byte is '11', so we expect ModRM to equal '11'.
        check_rr_stage("Decode 5-Byte ADD EAX      ", 1'b1, 8'h05, 8'h11); 


        // =========================================================
        // SCENARIO 5: PAGE FAULT HANDLING
        // =========================================================
        $display("\n--- SCENARIO 5: Page Fault Exception ---");
        
        // Flush the pipeline to clear the system
        from_ex_flush = 1;
        #(CYCLE_TIME);
        from_ex_flush = 0;

        // Run the Page Fault Test
        from_f_cache_line = 128'h0;
        load_cache_byte(0, 8'h90); // NOP
        from_f_cl_pf = 1; 
        from_f_icache_valid = 1;

        #(CYCLE_TIME); // Latch
        from_f_icache_valid = 0;
        from_f_cl_pf = 0;

        #(CYCLE_TIME); // Propagate
        
        if (to_rr_exception_flags[0] === 1'b1) begin
            $display("  ✅ PASS | Page Fault Flag Logged");
            SUCCESSES = SUCCESSES + 1;
        end else begin
            $display("  ❌ FAIL | Page Fault Flag Not Set!");
            FAILURES = FAILURES + 1;
        end

        // ---------------------------------------------------------
        // FINAL SUMMARY
        // ---------------------------------------------------------
        $display("\n=================================================");
        if (FAILURES == 0) begin
            $display("  🎉 ALL COMPREHENSIVE TESTS PASSED! ");
        end else begin
            $display("  💥 %0d TESTS FAILED! Check waveforms.", FAILURES);
        end
        $display("=================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule