`timescale 1ns / 1ps

module intgr_fshifter_decode_tb();

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
            // MODIFIED FOR BIG ENDIAN:
            // Byte 0 goes to [127:120], Byte 1 goes to [119:112], etc.
            from_f_cache_line[((15 - byte_idx)*8) +: 8] <= byte_val; // Non-blocking!
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
        $vcdplusfile("intgr_fshifter_decode.vpd");
        $vcdpluson(0, intgr_fshifter_decode_tb);

        $display("=================================================");
        $display("   FRONT-END INTEGRATION TEST (Fetch -> Decode)  ");
        $display("=================================================");

        // Time 0 initialization remains blocking (=) to instantly set the wires
        rst_bar = 0;
        shft_reg_we = 0; from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 0;
        from_f_cache_line = 128'h0;

        #(CYCLE_TIME/2); //at first posedge; let reset hold for a half a cycle to propgate (asynconous reset doesnt necessarily need a clock edge)
        // ==========================================
        // DURING CYCLE 1 (Setup Cache Load)
        // ==========================================

        /*
        1. rst_bar = 0 at 0ns and has a 0.35ns delay (asynchronous). This will go through starting from 1st low half 
        because clock starts low. Then we wait half a cycle time for this reset to propogate and can start latching the 
        first values at the first posedge. 
        2. Latch first cl values at first posedge
        _____ ------_______------_______------_______------
        0ns  50ns  100ns  150ns 200ns  
        */
        rst_bar <= 1; // turn off reset during first cycle
        #(CYCLE_TIME); //at 2nd posedge; wait full a cycle for rst_bar to propogate and align to posedge

        // ---------------------------------------------------------
        // THE FIX: Set the -2 offset right here!
        // We are currently at T=150ns. We wait 98ns. 
        // We are now at T=248ns, forever locked 2ns before every clock edge!
        // ---------------------------------------------------------
        #(CYCLE_TIME - 2); 

        // ==========================================
        // DURING CYCLE 2 (Setup Cache Load)
        // ==========================================
        load_cache_byte(0, 8'h01); // ADD
        load_cache_byte(1, 8'hC3); // EAX, EBX
        load_cache_byte(2, 8'h89); // MOV 
        load_cache_byte(3, 8'hC8); 

        from_f_icache_valid <= 1;
        shft_reg_we <= 1;
    
        #(CYCLE_TIME); // start of cycle 3 (Fetch loads cache line)

        // ==========================================
        // DURING CYCLE 3 allow decode to run and latch values at end of cycle
        // ==========================================
        from_f_icache_valid <= 0; 
        
        // NO MORE WEIRD OFFSETS HERE! Just a normal cycle jump!
        #(CYCLE_TIME); 

        // ==========================================
        // CYCLE 4 (Check ADD, Setup MOV)
        // ==========================================
        check_rr_stage("Fetch/Decode ADD EAX, EBX  ", 1'b1, 8'h01, 8'hC3); // check values right before cycle 4
        // (No input changes needed, Fetch buffer shifts naturally)
        
        #(CYCLE_TIME); // CLOCK STRIKES! (Pipeline Reg latches MOV)

        // ==========================================
        // CYCLE 4 (Check MOV, Setup STALL)
        // ==========================================
        check_rr_stage("Decode Next Inst (MOV)     ", 1'b1, 8'h89, 8'hC8);
        from_rr_stall <= 1; // Set stall NOW, before the clock strikes again!
        shft_reg_we <= 0; 
        
        #(CYCLE_TIME); // CLOCK STRIKES! (Pipeline Reg is Stalled, holds MOV)

        // ==========================================
        // CYCLE 5 (Check STALL, Setup FLUSH)
        // ==========================================
        check_rr_stage("Pipeline Stall (Hold MOV)  ", 1'b1, 8'h89, 8'hC8);
        from_rr_stall <= 0; 
        shft_reg_we <= 1;   
        from_ex_flush <= 1; // Send Flush command!
        
        #(CYCLE_TIME); // CLOCK STRIKES! (Pipeline Reg clears)

        // ==========================================
        // CYCLE 6 (Check FLUSH)
        // ==========================================
        check_rr_stage("Execute Flush (Invalidate) ", 1'b0, 8'h00, 8'h00);
        from_ex_flush <= 0;

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