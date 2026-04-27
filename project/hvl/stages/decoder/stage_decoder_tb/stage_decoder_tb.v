`timescale 1ns / 1ps

module tb_stage_decode();

    // --------------------------------------------------------
    // 1. Inputs
    // --------------------------------------------------------
    reg [127:0] cache_line;
    reg [4:0] tail_ptr;
    reg [31:0] eip_target_ex;
    reg mispredict_src_ex;
    reg from_wb_flush;
    reg v_ld_cs_src_ex; 
    reg stall_ex, stall_rr, stall_mem, stall_wb;
    
    reg clk;
    reg rst_bar;
    reg br_t_nt_ex_d;
    reg br_valid_ex_d;
    reg [3:0] pht_idx_ex_d;

    // TB Shadow Tracker (Used for math, no longer passed to UUT)
    reg [31:0] o_eip; 

    // --------------------------------------------------------
    // 2. Outputs
    // --------------------------------------------------------
    wire exptn_prot;
    wire [31:0] i_eip;
    wire pr_de_rr_valid;
    wire ld_eip;
    wire [31:0] eip_true;
    
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0] prefix_seg_ov_id, imm_size;
    wire [7:0] opcode, modrm, sib;
    wire [1:0] disp_size_mux, addressing_mode;
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0] instr_length;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // --------------------------------------------------------
    // 3. Instantiate UUT (o_eip removed)
    // --------------------------------------------------------
    stage_decode uut (
        .cache_line(cache_line), .tail_ptr(tail_ptr), 
        .eip_target_ex(eip_target_ex), 
        .flush_ex(mispredict_src_ex),       
        .from_wb_flush(from_wb_flush), 
        .stall_rr(stall_rr), 
        .clk(clk), .rst_bar(rst_bar), .br_t_nt_ex_d(br_t_nt_ex_d), 
        .br_valid_ex_d(br_valid_ex_d), .pht_idx_ex_d(pht_idx_ex_d),
        .from_f_pf_expn_bytes_out(), .i_eip(i_eip), 
        .o_eip(), .bp_eip_target(), //unused
        .pr_de_rr_valid(pr_de_rr_valid),
        .ld_eip(ld_eip), .eip_true(eip_true), 
        .to_f_take_branch(), //unused
        .prefix_rep(prefix_rep), 
        .prefix_op_size(prefix_op_size), .prefix_seg_ov_id(prefix_seg_ov_id), .prefix_seg(),
        .prefix_ext(prefix_ext), .opcode(opcode), .modrm(modrm), .sib(sib),
        .disp_size_mux(disp_size_mux), .disp(disp), .imm_size(imm_size), 
        .imm(imm), .addressing_mode(addressing_mode), .instr_length(instr_length),
        .ld_pr_rr(), .exception_flags(), .ucode_sigs() //unused
    );

    // --------------------------------------------------------
    // 4. Clock and Helpers
    // --------------------------------------------------------
    initial begin
        clk = 1;
        forever #10 clk = ~clk;
    end

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            cache_line[(byte_idx*8) +: 8] = byte_val;
        end
    endtask

    // SEQUENTIAL CHECK TASK (Fixed for Structural Gate Delays)
    task check_result;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_eip_true;
        input exp_valid;
        reg eip_target_ok;
        begin
            // 1. Wait until the clock falls (Halfway through the cycle)
            @(negedge clk); 
            
            // 2. Wait almost until the NEXT rising edge. 
            // This gives your structural gates the maximum possible time (~9ns) to finish 
            // their complex prefix and MUX routing math before we take the picture.
            #4; 
            
            eip_target_ok = (ld_eip === 1'b0) || (eip_true === exp_eip_true);

            if (ld_eip === exp_ld_eip && eip_target_ok && pr_de_rr_valid === exp_valid) begin
                $display("  ✅ PASS | %0s | ld_eip: %b | eip_true: %h | valid: %b", test_name, ld_eip, eip_true, pr_de_rr_valid);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: ld_eip=%b | eip_true=%h (or ignored) | valid=%b", exp_ld_eip, exp_eip_true, exp_valid);
                $display("     ACTUAL  : ld_eip=%b | eip_true=%h              | valid=%b", ld_eip, eip_true, pr_de_rr_valid);
                
                // DEEP DIVE PROBES
                $display("     --- INTERNAL SIGNAL PROBES ---");
                $display("     1. DECODER : opcode=%h | instr_length=%b (Hex: %h)", uut.opcode, uut.instr_length, uut.instr_length);
                $display("     2. EIP MATH: o_eip=%h | i_eip (o_eip+len)=%h", o_eip, uut.i_eip);
                $display("     3. BRANCH  : is_branch=%b | branch_type=%b", uut.is_branch, uut.branch_type);
                $display("     4. PREDICT : cur_instr_pred=%b | hit=%b", uut.cur_instr_prediction, uut.hit);
                $display("     5. MUX CTRL: take_branch=%b", uut.EIP_LOGIC.take_branch);
                $display("     ------------------------------");
                
                FAILURES = FAILURES + 1;
            end
            
            // 3. Wait the final 1ns for the clock edge to strike and latch the data!
            @(posedge clk);
            #1; // 1ns settling time for the flip-flop to update
            
            // 4. THE MAGIC SYNC
            o_eip = uut.EIP_LOGIC.o_eip; 
        end
    endtask

    // --------------------------------------------------------
    // 5. Stimulus
    // --------------------------------------------------------
    initial begin
        $dumpfile("stage_decode_tb.vpd");
        $dumpvars(0, tb_stage_decode);

        $display("=======================================");
        $display("       STAGE DECODE TOP-LEVEL TEST     ");
        $display("=======================================");

        // --- Init (Keep tail_ptr=0 to prevent "Phantom" increments during reset) ---
        cache_line = 128'd0;
        o_eip = 32'h0000_0000;
        tail_ptr = 5'd0; 
        eip_target_ex = 32'h0000_0000;
        mispredict_src_ex = 0; from_wb_flush = 0; v_ld_cs_src_ex = 0;
        stall_ex = 0; stall_rr = 0; stall_mem = 0; stall_wb = 0;
        br_t_nt_ex_d = 0; br_valid_ex_d = 0; pht_idx_ex_d = 0;

        rst_bar = 0;
        #20;
        rst_bar = 1;

        // --------------------------------------------------------
        // TEST 1: Normal Sequential Instruction (MOV r/m32, r32 -> 89 C8)
        // --------------------------------------------------------
        tail_ptr = 5'd4; // Wake up the pipeline!
        cache_line = 128'd0;
        load_cache_byte(0, 8'h89); load_cache_byte(1, 8'hC8); 
        check_result("Normal Sequential Inst ", 1'b1, o_eip + 2, 1'b1);

        // --------------------------------------------------------
        // TEST 2: Stall from Register Read Stage
        // --------------------------------------------------------
        stall_rr = 1; 
        check_result("Stall Condition (RR)   ", 1'b0, o_eip, 1'b1); 
        stall_rr = 0; // Release stall

        // --------------------------------------------------------
        // TEST 3: Mispredict Flush from Execute Stage
        // --------------------------------------------------------
        mispredict_src_ex = 1;
        eip_target_ex = 32'h0000_BEEF;
        check_result("EX Mispredict Flush    ", 1'b1, eip_target_ex, 1'b0); 
        mispredict_src_ex = 0;

        // --------------------------------------------------------
        // TEST 4: Branch Instruction (JMP rel8 -> EB 05)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hEB); load_cache_byte(1, 8'h05); 
        check_result("JMP rel8 (No BTB Hit)  ", 1'b1, o_eip + 2 + 8'h05, 1'b1);

        tail_ptr = 5'd15; // Ensure high enough for rest of tests

        // --------------------------------------------------------
        // TEST 5: Length = 1 Byte Branch (RET -> C3)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hC3); 
        check_result("1-Byte Inst (RET)      ", 1'b1, o_eip + 1, 1'b1);

        // --------------------------------------------------------
        // TEST 6: Length = 3 Bytes: o16 JNE rel8 (66 75 05)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h75); load_cache_byte(2, 8'h05);
        check_result("3-Byte Br (o16 JNE)    ", 1'b1, o_eip + 3, 1'b1);

        // --------------------------------------------------------
        // TEST 7: Length = 5 Bytes: CALL rel32 (E8 44 33 22 11)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hE8); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        check_result("5-Byte Br (CALL rel32) ", 1'b1, o_eip + 5 + 32'h11223344, 1'b1);

        // --------------------------------------------------------
        // TEST 8: Length = 6 Bytes: JNE rel32 (0F 85 44 33 22 11)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'h0F); load_cache_byte(1, 8'h85); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33); load_cache_byte(4, 8'h22); load_cache_byte(5, 8'h11);
        check_result("6-Byte Br (JNE rel32)  ", 1'b1, o_eip + 6, 1'b1);

        // --------------------------------------------------------
        // TEST 9: INVALID INSTRUCTION (Insufficient Bytes in Buffer)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hE9); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        
        tail_ptr = 5'd2; // Force an invalid state
        check_result("Invalid (Len > tail)   ", 1'b0, o_eip, 1'b0);

        // --------------------------------------------------------
        // TEST 10: Valid Instruction Restored
        // --------------------------------------------------------
        tail_ptr = 5'd15;
        check_result("Valid Inst Restored    ", 1'b1, o_eip + 5 + 32'h11223344, 1'b1);

        // --------------------------------------------------------
        // TEST 11: CS Segment Override + REP Prefix + ADD EAX, EBX
        // --------------------------------------------------------
        $display("=======================================");
        $display(" TEST 11: CS + REP + ADD (2E F3 01 C3) ");
        $display("=======================================");
        
        cache_line = 128'd0;
        load_cache_byte(0, 8'h2E); 
        load_cache_byte(1, 8'hF3); 
        load_cache_byte(2, 8'h01); 
        load_cache_byte(3, 8'hC3); 
        
        check_result("Prefix Chain Test      ", 1'b1, o_eip + 4, 1'b1);
        
        // Minor tweak: we wait 1ns AFTER check_result finishes (and triggers the clock)
        // just to ensure combinational wires have settled before this manual check.
        #1; 
        if (opcode !== 8'h01 || modrm !== 8'hC3 || prefix_rep !== 1'b1 || prefix_seg_ov_id !== 3'b001) begin
            $display("  ❌ FAIL: Decoder Logic Incorrect");
            $display("     Got Op: %h | Mod: %h | Rep: %b | SegID: %b", opcode, modrm, prefix_rep, prefix_seg_ov_id);
            FAILURES = FAILURES + 1;
        end else begin
            $display("  ✅ PASS: Decoder correctly parsed prefix chain");
            SUCCESSES = SUCCESSES + 1;
        end

        // --------------------------------------------------------
        // TEST 12: Stall during Prefix Chain
        // --------------------------------------------------------
        stall_rr = 1;
        check_result("Stall during Prefix    ", 1'b0, o_eip, 1'b1);
        stall_rr = 0;

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule