`timescale 1ns / 1ps

module tb_intgr_fshifter_decode_rigorous();

    // ---------------------------------------------------------
    // 0. Parameters & Signals
    // ---------------------------------------------------------
    localparam CYCLE_TIME = 200; // Aligned with your working TB

    reg clk;
    reg rst_bar;

    // Fetch/Buffer Signals
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
    // 2. Clock & Tasks
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CYCLE_TIME / 2) clk = ~clk;
    end

    task clear_cache_line;
        integer b;
        begin
            for (b = 0; b < 16; b = b + 1) begin
                from_f_cache_line[((15 - b)*8) +: 8] = 8'h90;
            end
        end
    endtask

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            from_f_cache_line[((15 - byte_idx)*8) +: 8] = byte_val;
        end
    endtask

    task check_rr_stage;
        input [8*40:1] test_name;
        input exp_valid;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        begin
            if (to_rr_pr_valid === exp_valid &&
               (exp_valid == 0 || (to_rr_opcode === exp_opcode && (to_rr_modrm === exp_modrm || to_rr_addressing_mode === 2'b00)))) begin
                $display("  PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  FAIL | %0s", test_name);
                $display("     EXPECTED: Valid=%b | Opcode=%h | ModRM=%h", exp_valid, exp_opcode, exp_modrm);
                $display("     ACTUAL  : Valid=%b | Opcode=%h | ModRM=%h", to_rr_pr_valid, to_rr_opcode, to_rr_modrm);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // ---------------------------------------------------------
    // 3. Stimulus Sequence (Deterministic Time-Based)
    // ---------------------------------------------------------
    initial begin
        $vcdplusfile("intgr_fshifter_decode.vpd");
        $vcdpluson(0, tb_intgr_fshifter_decode_rigorous);

        $display("=================================================");
        $display("   RIGOROUS FRONT-END EDGE CASE STRESS TEST      ");
        $display("=================================================");

        // TIME 0
        rst_bar = 0;
        from_f_icache_valid = 0; from_wb_flush = 0; from_ex_flush = 0;
        from_rr_stall = 0; from_f_cl_pf = 0;
        from_ex_eip_target = 32'h0; from_ex_br_t_nt = 0; from_ex_br_valid = 0; from_ex_pht_idx = 4'h0;
        from_f_cache_line = {16{8'h90}};

        #(CYCLE_TIME);     // 200ns: Falling Edge
        rst_bar = 1;

        #(1.5 * CYCLE_TIME); // 300ns: Now at 500ns (Rising Edge)
        #1;                  // 501ns

        // =========================================================
        // SCENARIO 1: LONG DECODE & BOUNDARY CROSSING
        // =========================================================
        $display("\n--- SCENARIO 1: Incomplete Instruction at Boundary ---");
        clear_cache_line();
        load_cache_byte(13, 8'h05); // ADD EAX, imm32
        load_cache_byte(14, 8'hAA); // imm byte 0
        load_cache_byte(15, 8'hBB); // imm byte 1

        from_f_icache_valid = 1;

        #(CYCLE_TIME); // 701ns: Clock Ticked. Fetch Buffer latches.
        from_f_icache_valid = 0;

        #(CYCLE_TIME); // 901ns: Latch de_to_rr (Buffer settling)
        
        // Decode 13 NOPs
        for (i = 0; i < 13; i = i + 1) begin
            check_rr_stage("Decoding NOP", 1'b1, 8'h90, 8'h00);
            #(CYCLE_TIME);
        end

        // tail_ptr should be 3 now. ADD needs 5 bytes. Should be invalid.
        check_rr_stage("Incomplete ADD (Wait)", 1'b0, 8'h00, 8'h00);

        // =========================================================
        // SCENARIO 2: LOAD 2ND CACHE LINE & JUMP GAUNTLET
        // =========================================================
        $display("\n--- SCENARIO 2: Line Merge & Jump Gauntlet ---");
        clear_cache_line();
        load_cache_byte(0, 8'hCC); // imm byte 2
        load_cache_byte(1, 8'hDD); // imm byte 3 (ADD complete)
        load_cache_byte(2, 8'hEB); // JMP rel8
        load_cache_byte(3, 8'h05); // JMP displacement
        load_cache_byte(4, 8'h75); // JNE rel8
        load_cache_byte(5, 8'h02); // JNE displacement

        from_f_icache_valid = 1;

        #(CYCLE_TIME); // Latch new line into Buffer
        from_f_icache_valid = 0;

        #(CYCLE_TIME); // Pipeline latches ADD
        check_rr_stage("Completed ADD EAX", 1'b1, 8'h05, 8'h00);

        #(CYCLE_TIME); // Pipeline latches JMP
        check_rr_stage("Decoded JMP", 1'b1, 8'hEB, 8'h00);

        #(CYCLE_TIME); // Pipeline latches JNE
        check_rr_stage("Decoded JNE", 1'b1, 8'h75, 8'h00);

        // =========================================================
        // SCENARIO 3: FLUSH AND TARGETED LOAD
        // =========================================================
        $display("\n--- SCENARIO 3: Targeted Flush ---");
        from_ex_flush = 1;
        #(CYCLE_TIME);
        from_ex_flush = 0;

        #(CYCLE_TIME); // Pipeline empty
        check_rr_stage("Post-Flush Empty", 1'b0, 8'h00, 8'h00);

        clear_cache_line();
        load_cache_byte(0, 8'hEB); 
        load_cache_byte(1, 8'h05); 
        from_f_icache_valid = 1;

        #(CYCLE_TIME);
        from_f_icache_valid = 0;

        #(CYCLE_TIME);
        check_rr_stage("Targeted Load (JMP)", 1'b1, 8'hEB, 8'h00);

        // =========================================================
        // SCENARIO 4: Stall & Flush Override
        // =========================================================
        $display("\n--- SCENARIO 4: Stall & Flush Override ---");
        from_rr_stall = 1;
        #(CYCLE_TIME);
        check_rr_stage("Stalled (Holding JMP)", 1'b1, 8'hEB, 8'h00);

        from_ex_flush = 1;
        #(CYCLE_TIME);
        from_ex_flush = 0;
        from_rr_stall = 0;

        #(CYCLE_TIME);
        check_rr_stage("Flush Overrode Stall", 1'b0, 8'h00, 8'h00);

        // =========================================================
        // SCENARIO 5: PAGE FAULT EXCEPTION TEST
        // =========================================================
        $display("\n--- SCENARIO 5: Page Fault Exception ---");
        clear_cache_line();
        load_cache_byte(0, 8'h90);
        from_f_cl_pf = 1;
        from_f_icache_valid = 1;

        #(CYCLE_TIME);
        from_f_cl_pf = 0;
        from_f_icache_valid = 0;

        #(CYCLE_TIME);
        check_rr_stage("Decode PF Instruction", 1'b1, 8'h90, 8'h00);

        if (to_rr_exception_flags[0] === 1'b1) begin
            $display("  PASS | Page Fault Propagated");
            SUCCESSES = SUCCESSES + 1;
        end else begin
            $display("  FAIL | Page Fault Missing");
            FAILURES = FAILURES + 1;
        end

        $display("\n=================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule