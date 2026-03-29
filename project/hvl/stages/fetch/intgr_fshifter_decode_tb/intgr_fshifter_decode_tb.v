`timescale 1ns / 1ps

module tb_intgr_fshifter_decode();

    // ---------------------------------------------------------
    // 1. Inputs (Regs)
    // ---------------------------------------------------------
    reg clk;
    reg rst_bar;

    // Fetch Inputs
    reg shft_reg_we; 
    reg [127:0] from_f_cache_line;
    reg from_f_icache_valid; 
    reg from_wb_flush;

    // Decode/Execute Inputs
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
    wire [31:0] to_rr_i_eip;
    wire [31:0] to_rr_o_eip;
    wire [31:0] to_rr_bp_target;
    wire to_rr_pr_valid; 
    wire [5:0] to_rr_prefixes; 
    wire [7:0] to_rr_opcode;
    wire [7:0] to_rr_modrm;
    wire [7:0] to_rr_sib; 
    wire [1:0] to_rr_disp_size_mux;
    wire [31:0] to_rr_disp; 
    wire [2:0] to_rr_imm_size;
    wire [47:0] to_rr_imm;
    wire [1:0] to_rr_addressing_mode;
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
        forever #5 clk = ~clk; // 10ns period
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
            // 1. Wait for the clock to rise so the Pipeline Register latches
            @(posedge clk); 
            // 2. Wait 1ns for the physical flip-flops to update their outputs
            #1; 
            
            // 3. Now check the stable outputs!
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
        // --- DVE Dump Commands ---
        $vcdplusfile("intgr_fshifter_decode.vpd");
        $vcdpluson(0, tb_intgr_fshifter_decode);
        // -------------------------

        $display("=================================================");
        $display("   FRONT-END INTEGRATION TEST (Fetch -> Decode)  ");
        $display("=================================================");

        // 1. Initial Reset State
        rst_bar = 0;
        shft_reg_we = 0; from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 0;
        from_f_cache_line = 128'h0; // Fill with NOPs initially

        #15;
        rst_bar = 1;

        // ---------------------------------------------------------
        // TEST 1: Load First Cache Line (ADD EAX, EBX -> 01 C3)
        // ---------------------------------------------------------
        // Align to a posedge, wait 1ns so we don't cause a race condition
        @(posedge clk); #1; 
        load_cache_byte(0, 8'h01); // ADD
        load_cache_byte(1, 8'hC3); // EAX, EBX
        load_cache_byte(2, 8'h89); // MOV (Next instruction)
        load_cache_byte(3, 8'hC8); // EAX, ECX

        // CLOCK 1: Trigger Fetch Buffer write
        from_f_icache_valid = 1;
        shft_reg_we = 1;
        
        @(posedge clk); #1; 
        from_f_icache_valid = 0;
        // Keep shft_reg_we = 1 so the shift register remains enabled for shifting!

        // CLOCK 2: Pipeline Reg latches ADD. 
        check_rr_stage("Fetch/Decode ADD EAX, EBX  ", 1'b1, 8'h01, 8'hC3);

        // ---------------------------------------------------------
        // TEST 2: Normal Sequential Flow (MOV EAX, ECX -> 89 C8)
        // ---------------------------------------------------------
        // CLOCK 3: Fetch buffer already shifted on Clock 2. Pipeline Reg latches MOV.
        check_rr_stage("Decode Next Inst (MOV)     ", 1'b1, 8'h89, 8'hC8);

        // ---------------------------------------------------------
        // TEST 3: Register Read Stall (Backpressure)
        // ---------------------------------------------------------
        from_rr_stall = 1;
        // Turn off shift enable so we don't accidentally lose the next instruction while stalled
        shft_reg_we = 0; 
        
        // CLOCK 4: Pipeline Reg sees stall, holds the MOV instruction.
        check_rr_stage("Pipeline Stall (Hold MOV)  ", 1'b1, 8'h89, 8'hC8);
        
        from_rr_stall = 0; // Release Stall
        shft_reg_we = 1;   // Re-enable shifting

        // ---------------------------------------------------------
        // TEST 4: Execute Flush (Misprediction)
        // ---------------------------------------------------------
        from_ex_flush = 1;
        
        // CLOCK 5: Pipeline Reg sees flush, drops Valid to 0.
        check_rr_stage("Execute Flush (Invalidate) ", 1'b0, 8'h00, 8'h00);
        
        from_ex_flush = 0;

        // ---------------------------------------------------------
        // FINAL SUMMARY
        // ---------------------------------------------------------
        $display("=================================================");
        if (FAILURES == 0) begin
            $display("  🎉 ALL TESTS PASSED! Integration is solid.");
        end else begin
            $display("  💥 %0d TESTS FAILED! Check waveforms.", FAILURES);
        end
        $display("=================================================");
        $display("FAILURES = %0d\n", FAILURES);
        $display("SUCCESSES = %0d\n", SUCCESSES);
        $finish;
    end
endmodule