`timescale 1ns / 1ps

module tb_stage_decode_rigorous();

    // --------------------------------------------------------
    // 1. Inputs
    // --------------------------------------------------------
    reg [127:0] cache_line;
    reg [4:0]   tail_ptr;
    reg [31:0]  eip_target_ex;
    reg         flush_ex;
    reg         from_wb_flush;
    reg         stall_rr; 
    reg         clk;
    reg         rst_bar;
    reg         br_t_nt_ex_d;
    reg         br_valid_ex_d;
    reg [3:0]   pht_idx_ex_d;
    reg [15:0]  from_f_pf_expn_bytes_out; // NEW: Page fault vector

    // --------------------------------------------------------
    // 2. Outputs
    // --------------------------------------------------------
    wire [31:0] i_eip;
    wire [31:0] o_eip;          // NEW: Exposed out of EIP_LOGIC
    wire [31:0] bp_eip_target;
    wire        pr_de_rr_valid;
    wire        ld_eip;
    wire [31:0] eip_true;
    wire        to_f_take_branch;
    
    wire        prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0]  prefix_seg_ov_id, imm_size;
    wire [7:0]  opcode, modrm, sib;
    wire [1:0]  disp_size_mux, addressing_mode;
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0]  instr_length;

    wire        ld_pr_rr;        // NEW: Load Pipeline Reg signal
    wire [1:0]  exception_flags; // NEW: [1]=Prot, [0]=PF

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // --------------------------------------------------------
    // 3. Instantiate UUT
    // --------------------------------------------------------
    stage_decode uut (
        .cache_line(cache_line), 
        .tail_ptr(tail_ptr), 
        .eip_target_ex(eip_target_ex), 
        .flush_ex(flush_ex),       
        .from_wb_flush(from_wb_flush), 
        .stall_rr(stall_rr), 
        .clk(clk), 
        .rst_bar(rst_bar), 
        .br_t_nt_ex_d(br_t_nt_ex_d), 
        .br_valid_ex_d(br_valid_ex_d), 
        .pht_idx_ex_d(pht_idx_ex_d),
        .from_f_pf_expn_bytes_out(from_f_pf_expn_bytes_out),
        .i_eip(i_eip), 
        .o_eip(o_eip), 
        .bp_eip_target(bp_eip_target), 
        .pr_de_rr_valid(pr_de_rr_valid),
        .ld_eip(ld_eip), 
        .eip_true(eip_true), 
        .to_f_take_branch(to_f_take_branch), 
        .prefix_rep(prefix_rep), 
        .prefix_op_size(prefix_op_size), 
        .prefix_seg_ov_id(prefix_seg_ov_id), 
        .prefix_ext(prefix_ext), 
        .opcode(opcode), 
        .modrm(modrm), 
        .sib(sib),
        .disp_size_mux(disp_size_mux), 
        .disp(disp), 
        .imm_size(imm_size), 
        .imm(imm), 
        .addressing_mode(addressing_mode), 
        .instr_length(instr_length),
        .ld_pr_rr(ld_pr_rr), 
        .exception_flags(exception_flags) 
    );

    // --------------------------------------------------------
    // 4. Clock and Helpers
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            cache_line[(byte_idx*8) +: 8] = byte_val;
        end
    endtask

    // --------------------------------------------------------
    // 5. RIGOROUS CHECKING TASK
    // --------------------------------------------------------
    task check_rigorous;
        input [8*40:1] test_name; 
        input exp_valid;
        input exp_ld_pr_rr;
        input [1:0] exp_flags;
        input [3:0] exp_len; // Used to verify i_eip = o_eip + exp_len
        reg eip_math_ok;
        begin
            @(negedge clk); 
            #4; // Give complex decoder/MUX logic time to settle
            
            // i_eip should always be the base (o_eip) + the instruction length
            eip_math_ok = (i_eip === (o_eip + exp_len));

            if (pr_de_rr_valid === exp_valid && 
                ld_pr_rr === exp_ld_pr_rr && 
                exception_flags === exp_flags && 
                eip_math_ok) begin
                
                $display("  ✅ PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: Valid=%b | ld_pr_rr=%b | Flags=%b | i_eip=%h (o_eip+%0d)", 
                            exp_valid, exp_ld_pr_rr, exp_flags, (o_eip + exp_len), exp_len);
                $display("     ACTUAL  : Valid=%b | ld_pr_rr=%b | Flags=%b | i_eip=%h (o_eip=%h)", 
                            pr_de_rr_valid, ld_pr_rr, exception_flags, i_eip, o_eip);
                FAILURES = FAILURES + 1;
            end
            
            @(posedge clk);
            #1; // Align for next cycle
        end
    endtask

    // --------------------------------------------------------
    // 6. Stimulus
    // --------------------------------------------------------
    initial begin
        $dumpfile("stage_decode_rigorous_tb.vpd");
        $dumpvars(0, tb_stage_decode_rigorous);

        $display("=======================================");
        $display("   DECODE PIPELINE & EXCEPTION TESTS   ");
        $display("=======================================");

        // --- Init ---
        cache_line = 128'd0;
        tail_ptr = 5'd0; 
        eip_target_ex = 32'h0;
        flush_ex = 0; from_wb_flush = 0; stall_rr = 0;
        br_t_nt_ex_d = 0; br_valid_ex_d = 0; pht_idx_ex_d = 0;
        from_f_pf_expn_bytes_out = 16'd0;

        rst_bar = 0;
        #15;
        rst_bar = 1;

        // Baseline Instruction: ADD EAX, EBX (01 C3) -> Length 2
        load_cache_byte(0, 8'h01); 
        load_cache_byte(1, 8'hC3); 

        // --------------------------------------------------------
        // SCENARIO 1: instr_len > tail_ptr (Boundary Cross)
        // --------------------------------------------------------
        // Length is 2, but tail_ptr is 1 (only 1 byte arrived from cache)
        tail_ptr = 5'd1; 
        from_f_pf_expn_bytes_out = 16'b0000_0000_0000_0001; // PF on Byte 0
        // Expect: VALID = 0. Even with PF, if we don't have the full instruction, it's invalid.
        // ld_pr_rr = 1 (RR is not stalled)
        check_rigorous("Len > Tail (Cross Line)  ", 1'b0, 1'b1, 2'b01, 4'd2);

        // --------------------------------------------------------
        // SCENARIO 2: Valid Instruction + Page Fault inside it
        // --------------------------------------------------------
        tail_ptr = 5'd15; // Full buffer
        from_f_pf_expn_bytes_out = 16'b0000_0000_0000_0010; // PF on Byte 1
        // Expect: VALID = 1 (It fully fits). Flags = 01 (Page Fault).
        check_rigorous("Valid Inst + Internal PF ", 1'b1, 1'b1, 2'b01, 4'd2);

        // --------------------------------------------------------
        // SCENARIO 3: Page Fault OUTSIDE the current instruction
        // --------------------------------------------------------
        // Length is 2. Fault is on Byte 3.
        from_f_pf_expn_bytes_out = 16'b0000_0000_0000_1000; 
        // Expect: VALID = 1. Flags = 00. (The fault belongs to the NEXT instruction!)
        check_rigorous("PF Outside Instr Length  ", 1'b1, 1'b1, 2'b00, 4'd2);

        // --------------------------------------------------------
        // SCENARIO 4: ld_pr_rr Logic (Stall RR asserted)
        // --------------------------------------------------------
        from_f_pf_expn_bytes_out = 16'd0; // Clean cache
        stall_rr = 1'b1;
        // Expect: VALID = 1 (instruction is perfectly fine). ld_pr_rr = 0 (RR says STOP).
        check_rigorous("Stall RR Freezes ld_pr_rr", 1'b1, 1'b0, 2'b00, 4'd2);
        stall_rr = 1'b0; // Release

        // --------------------------------------------------------
        // SCENARIO 5: Flush Logic
        // --------------------------------------------------------
        flush_ex = 1'b1;
        // Expect: VALID = 0 (Flushed). ld_pr_rr = 1 (Pipeline can move).
        check_rigorous("Flush Forces Invalid     ", 1'b0, 1'b1, 2'b00, 4'd2);
        flush_ex = 1'b0;

        // --------------------------------------------------------
        // SCENARIO 6: Multi-Byte PF Test (5 Byte CALL)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hE8); // CALL rel32
        load_cache_byte(1, 8'h44); 
        load_cache_byte(2, 8'h33); 
        load_cache_byte(3, 8'h22); 
        load_cache_byte(4, 8'h11);
        
        from_f_pf_expn_bytes_out = 16'b0000_0000_0001_0000; // Fault on the very last byte (Byte 4)
        // Expect: VALID = 1. Flags = 01.
        check_rigorous("5-Byte Inst + PF at End  ", 1'b1, 1'b1, 2'b01, 4'd5);

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule