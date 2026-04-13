`timescale 1ns / 1ps

module intgr_fshifter_decode_tb2();

    // ---------------------------------------------------------
    // 0. Parameters & Inputs
    // ---------------------------------------------------------
    localparam CYCLE_TIME = 200; 

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
    // Outputs & Instantiation
    // ---------------------------------------------------------
    wire [1:0] to_rr_exception_flags;
    wire [31:0] to_rr_i_eip, to_rr_o_eip, to_rr_bp_target;
    wire to_rr_pr_valid; 
    wire [6:0] to_rr_prefixes; 
    wire [7:0] to_rr_opcode, to_rr_modrm, to_rr_sib;
    wire [1:0] to_rr_disp_size_mux, to_rr_addressing_mode;
    wire [31:0] to_rr_disp; 
    wire [2:0] to_rr_imm_size;
    wire [47:0] to_rr_imm;
    wire [3:0] to_rr_instr_length;

    integer FAILURES = 0;
    integer SUCCESSES = 0;

    intgr_fshifter_decode uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .from_f_cache_line(from_f_cache_line),
        .ICACHE_VALID(from_f_icache_valid), 
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
        .to_rr_instr_length(to_rr_instr_length),
        .from_de_eip_redirection(), //unused
        .to_pr_bp_target() //unused
    );
    
    // ---------------------------------------------------------
    // Clock and Tasks
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CYCLE_TIME / 2) clk = ~clk; 
    end

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            // CORRECTED: Byte 0 goes to [7:0], Byte 1 to [15:8], etc.
            from_f_cache_line[(byte_idx * 8) +: 8] <= byte_val; 
        end
    endtask

    // Check ONLY the Latched Outputs
    task check_rr_stage;
        input [8*35:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
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
    // ---------------------------------------------------------
    // 5. Stimulus Sequence (Deterministic Time-Based)
    // ---------------------------------------------------------
    initial begin
        // $vcdplusfile("intgr_comprehensive.vpd");
        // $vcdpluson(0, intgr_fshifter_decode_tb2);

        $display("=================================================");
        $display("   COMPREHENSIVE FRONT-END INTEGRATION TEST      ");
        $display("=================================================");

        // TIME 0: Initialization 
        rst_bar = 0;
        from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 0;
        from_f_cache_line = 128'h0;

        #(CYCLE_TIME);       // 200ns: Lands on Falling Edge
        rst_bar = 1;

        #(1.5 * CYCLE_TIME); // 300ns: We are now at 500ns (Rising Edge)
        #1;                  // Safety buffer (501ns)

        // =========================================================
        // SCENARIO 1: BASIC SEQUENTIAL EXECUTION
        // =========================================================
        $display("\n--- SCENARIO 1: Basic Sequential Fetch & Decode ---");
        
        load_cache_byte(0, 8'h01); // ADD
        load_cache_byte(1, 8'hC3); // EAX, EBX
        load_cache_byte(2, 8'h89); // MOV 
        load_cache_byte(3, 8'hC8); // EAX, ECX
        from_f_icache_valid = 1; 
        
        #(CYCLE_TIME); // 701ns: Clock Ticked. Buffer loads.
        from_f_icache_valid = 0; 

        #(CYCLE_TIME); // 901ns: Clock Ticked. Pipeline Latches ADD.
        check_rr_stage("Decode Instr 1 (ADD)       ", 1'b1, 8'h01, 8'hC3);
        
        #(CYCLE_TIME); // 1101ns: Clock Ticked. Pipeline Latches MOV.
        check_rr_stage("Decode Instr 2 (MOV)       ", 1'b1, 8'h89, 8'hC8);

        // =========================================================
        // SCENARIO 2: PIPELINE STALL (BACKPRESSURE)
        // =========================================================
        $display("\n--- SCENARIO 2: Pipeline Stall & Recovery ---");
        
        from_rr_stall = 1; // Assert stall NOW (at 1101ns)
        
        #(CYCLE_TIME); // 1301ns: Clock Ticked. Stall held the pipeline register!
        check_rr_stage("Stall Cycle 1 (Hold MOV)   ", 1'b1, 8'h89, 8'hC8);
        
        #(CYCLE_TIME); // 1501ns: Clock Ticked.
        check_rr_stage("Stall Cycle 2 (Hold MOV)   ", 1'b1, 8'h89, 8'hC8);
        from_rr_stall = 0; // Release Stall
        
        #(CYCLE_TIME); // 1701ns: Clock ticks. Recovery.
        check_rr_stage("Post-Stall Recovery (ADD)  ", 1'b1, 8'h00, 8'h00); 

        // =========================================================
        // SCENARIO 3: EXECUTE MISPREDICT FLUSH & MULTI-BYTE LOAD
        // =========================================================
        $display("\n--- SCENARIO 3: Mispredict Flush & Refetch ---");
        from_ex_flush = 1;
        
        #(CYCLE_TIME); // 1901ns: Clock Ticked. Pipeline invalidates.
        check_rr_stage("Pipeline Invalidated       ", 1'b0, 8'h00, 8'h00);
        
        from_ex_flush = 0;
        from_f_cache_line = 128'h0;
        
        // Instruction 1: MOV (2 bytes)
        load_cache_byte(0, 8'h8B); 
        load_cache_byte(1, 8'h11); 
        // Instruction 2: ADD EAX, imm32 (5 bytes)
        load_cache_byte(2, 8'h05); 
        load_cache_byte(3, 8'h11); 
        load_cache_byte(4, 8'h22); 
        load_cache_byte(5, 8'h33); 
        load_cache_byte(6, 8'h44); 
        
        from_f_icache_valid = 1;
        
        #(CYCLE_TIME); // 2101ns: Clock Ticked. Buffer loads.
        from_f_icache_valid = 0;
        
        #(CYCLE_TIME); // 2301ns: Clock Ticked. Pipeline Latches MOV.
        check_rr_stage("Post-Flush Fetch (MOV)     ", 1'b1, 8'h8B, 8'h11);

        // =========================================================
        // SCENARIO 4: MULTI-BYTE INSTRUCTION DECODE
        // =========================================================
        $display("\n--- SCENARIO 4: Multi-Byte Instruction Flow ---");

        #(CYCLE_TIME); // 2501ns: Clock Ticked. Buffer shifted past MOV.
        check_rr_stage("Decode 5-Byte ADD EAX      ", 1'b1, 8'h05, 8'h11); 

        // =========================================================
        // SCENARIO 5: PAGE FAULT HANDLING
        // =========================================================
        $display("\n--- SCENARIO 5: Page Fault Exception ---");
        
        from_ex_flush = 1; 
        #(CYCLE_TIME); // 2701ns: Pipeline Flushed
        from_ex_flush = 0;

        from_f_cache_line = 128'h0;
        load_cache_byte(0, 8'h90); // NOP
        from_f_cl_pf = 1; 
        from_f_icache_valid = 1;

        #(CYCLE_TIME); // 2901ns: Clock Ticked. Buffer Loads.
        from_f_icache_valid = 0;
        from_f_cl_pf = 0;

        #(CYCLE_TIME); // 3101ns: Clock Ticked. Latches NOP + Fault.
        check_rr_stage("Latched NOP with Page Fault", 1'b1, 8'h90, 8'h00);
        
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