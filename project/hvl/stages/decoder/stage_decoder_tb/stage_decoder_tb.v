`timescale 1ns / 1ps

module tb_stage_decode();

    // --------------------------------------------------------
    // 1. Inputs
    // --------------------------------------------------------
    reg [127:0] cache_line;
    reg [31:0] o_eip;
    reg [3:0] tail_ptr;
    reg [19:0] cs_limit_reg;
    reg [31:0] eip_target_ex;
    reg mispredict_src_ex;
    reg v_excptn_src_wb;
    reg v_ld_cs_src_ex; // Kept in TB to prevent breaking older test stimulus
    reg stall_ex, stall_rr, stall_mem, stall_wb;
    
    reg clk;
    reg rst_bar;
    reg br_t_nt_ex_d;
    reg br_valid_ex_d;
    reg [3:0] pht_idx_ex_d;

    // --------------------------------------------------------
    // 2. Outputs
    // --------------------------------------------------------
    wire exptn_prot;
    wire [31:0] i_eip;
    wire pr_de_rr_valid;
    wire ld_eip;
    wire [31:0] eip_true;
    
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0] prefix_seg_ov_id;
    wire [7:0] opcode, modrm, sib;
    wire [1:0] disp_size_mux, imm_size, addressing_mode;
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0] instr_length;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // --------------------------------------------------------
    // 3. Instantiate UUT (Updated port mapping)
    // --------------------------------------------------------
    stage_decode uut (
        .cache_line(cache_line), .o_eip(o_eip), .tail_ptr(tail_ptr), .cs_limit_reg(cs_limit_reg),
        .eip_target_ex(eip_target_ex), 
        .flush_ex(mispredict_src_ex),       // FIXED: Mapped mispredict stimulus to flush_ex port
        .v_excptn_src_wb(v_excptn_src_wb), 
        // REMOVED: .v_ld_cs_src_ex(v_ld_cs_src_ex)
        .stall_rr(stall_rr), // Removed extra stalls here to match module
        .clk(clk), .rst_bar(rst_bar), .br_t_nt_ex_d(br_t_nt_ex_d), 
        .br_valid_ex_d(br_valid_ex_d), .pht_idx_ex_d(pht_idx_ex_d),
        .exptn_prot(exptn_prot), .i_eip(i_eip), .pr_de_rr_valid(pr_de_rr_valid),
        .ld_eip(ld_eip), .eip_true(eip_true), .prefix_rep(prefix_rep), 
        .prefix_op_size(prefix_op_size), .prefix_seg_ov_id(prefix_seg_ov_id), 
        .prefix_ext(prefix_ext), .opcode(opcode), .modrm(modrm), .sib(sib),
        .disp_size_mux(disp_size_mux), .disp(disp), .imm_size(imm_size), 
        .imm(imm), .addressing_mode(addressing_mode), .instr_length(instr_length)
    );

    // --------------------------------------------------------
    // 4. Clock and Helpers
    // --------------------------------------------------------
    always #5 clk = ~clk;

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] byte_val;
        begin
            cache_line[(byte_idx*8) +: 8] = byte_val;
        end
    endtask

    task check_result;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_eip_true;
        input exp_valid;
        reg eip_target_ok;
        begin
            @(negedge clk); // Check outputs after combinational logic settles
            
            // If ld_eip is 0, the CPU ignores eip_true, so we can pass the check automatically.
            // Otherwise, we strictly compare eip_true to the expected value.
            eip_target_ok = (ld_eip === 1'b0) || (eip_true === exp_eip_true);

            if (ld_eip === exp_ld_eip && eip_target_ok && pr_de_rr_valid === exp_valid) begin
                $display("  ✅ PASS | %0s | ld_eip: %b | eip_true: %h | valid: %b", test_name, ld_eip, eip_true, pr_de_rr_valid);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: ld_eip=%b | eip_true=%h (or ignored) | valid=%b", exp_ld_eip, exp_eip_true, exp_valid);
                $display("     ACTUAL  : ld_eip=%b | eip_true=%h              | valid=%b", ld_eip, eip_true, pr_de_rr_valid);
                FAILURES = FAILURES + 1;
            end
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

        // Init
        clk = 0; rst_bar = 0;
        cache_line = 128'd0;
        o_eip = 32'h0000_1000;
        tail_ptr = 4'd4; // Assume plenty of bytes valid
        cs_limit_reg = 20'hFFFFF;
        eip_target_ex = 32'h0000_0000;
        mispredict_src_ex = 0; v_excptn_src_wb = 0; v_ld_cs_src_ex = 0;
        stall_ex = 0; stall_rr = 0; stall_mem = 0; stall_wb = 0;
        br_t_nt_ex_d = 0; br_valid_ex_d = 0; pht_idx_ex_d = 0;

        @(negedge clk);
        rst_bar = 1;

        // --------------------------------------------------------
        // TEST 1: Normal Sequential Instruction (MOV r/m32, r32 -> 89 C8)
        // 2 bytes long. Expected: PC advances by 2, pipeline valid.
        // --------------------------------------------------------
        #10
        cache_line = 128'd0;
        load_cache_byte(0, 8'h89); load_cache_byte(1, 8'hC8); 
        o_eip = 32'h0000_1000;
        check_result("Normal Sequential Inst ", 1'b1, 32'h0000_1002, 1'b1);

        // --------------------------------------------------------
        // TEST 2: Stall from Register Read Stage
        // Pipeline should pause. ld_eip=0, valid=1 (instruction is still valid, just waiting).
        // --------------------------------------------------------
        stall_rr = 1; 
        check_result("Stall Condition (RR)   ", 1'b0, 32'h0000_1000, 1'b1); 
        stall_rr = 0; // Release stall

        // --------------------------------------------------------
        // TEST 3: Mispredict Flush from Execute Stage
        // Should override everything and jump to EX target.
        // --------------------------------------------------------
        mispredict_src_ex = 1;
        eip_target_ex = 32'h0000_BEEF;
        // Even though instruction is valid, the flush overrides the EIP logic.
        check_result("EX Mispredict Flush    ", 1'b1, 32'h0000_BEEF, 1'b0); 
        mispredict_src_ex = 0;

        // --------------------------------------------------------
        // TEST 4: Branch Instruction (JMP rel8 -> EB 05)
        // Since BTB 'hit' is currently hardcoded to 0 in your design,
        // it acts as an unresolvable branch and just increments PC sequentially.
        // Length = 2 bytes. 
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hEB); load_cache_byte(1, 8'h05); 
        o_eip = 32'h0000_2000;
        check_result("JMP rel8 (No BTB Hit)  ", 1'b1, 32'h0000_2002, 1'b1);

        // Ensure tail_ptr is high enough for all normal instructions
        tail_ptr = 4'd15;

        // --------------------------------------------------------
        // TEST 5: Length = 1 Byte Branch (RET -> C3)
        // BP defaults to 0 (Not Taken), so it increments sequentially.
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hC3); 
        o_eip = 32'h0000_1000;
        check_result("1-Byte Inst (RET)      ", 1'b1, 32'h0000_1001, 1'b1);

        // --------------------------------------------------------
        // TEST 6: Length = 3 Bytes: o16 JNE rel8 (66 75 05)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h75); load_cache_byte(2, 8'h05);
        o_eip = 32'h0000_1003; 
        check_result("3-Byte Br (o16 JNE)    ", 1'b1, 32'h0000_1006, 1'b1);

        // --------------------------------------------------------
        // TEST 7: Length = 5 Bytes: CALL rel32 (E8 44 33 22 11)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hE8); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        o_eip = 32'h0000_1006; 
        check_result("5-Byte Br (CALL rel32) ", 1'b1, 32'h0000_100B, 1'b1);

        // --------------------------------------------------------
        // TEST 8: Length = 6 Bytes: JNE rel32 (0F 85 44 33 22 11)
        // --------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'h0F); load_cache_byte(1, 8'h85); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33); load_cache_byte(4, 8'h22); load_cache_byte(5, 8'h11);
        o_eip = 32'h0000_100B; 
        check_result("6-Byte Br (JNE rel32)  ", 1'b1, 32'h0000_1011, 1'b1);

        // --------------------------------------------------------
        // TEST 9: INVALID INSTRUCTION (Insufficient Bytes in Buffer)
        // --------------------------------------------------------
        // Let's use the 5-byte JMP rel32 (E9 44 33 22 11)
        cache_line = 128'd0;
        load_cache_byte(0, 8'hE9); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        o_eip = 32'h0000_1011; 
        
        // BUT, we tell the Decode stage it only has 2 valid bytes left
        tail_ptr = 4'd2; 
        
        // Expected: The decoder figures out it's 5 bytes long, but tail_ptr is 2.
        // Therefore, logic_stall_flush must mark this as INVALID. 
        // ld_eip = 0 (don't increment PC), pr_de_rr_valid = 0 (bubble).
        check_result("Invalid (Len > tail)   ", 1'b0, 32'h0000_1011, 1'b0);

        // --------------------------------------------------------
        // TEST 10: Valid Instruction Restored
        // Provide enough bytes to successfully decode the previous inst.
        // --------------------------------------------------------
        tail_ptr = 4'd15;
        check_result("Valid Inst Restored    ", 1'b1, 32'h0000_1016, 1'b1);

        // --------------------------------------------------------
        // TEST 11: CS Segment Override + REP Prefix + ADD EAX, EBX
        // Instruction: 2E F3 01 C3
        // This is the case that failed in the de_to_rr pipeline test.
        // Expected: 
        //   - prefix_rep = 1, prefix_seg_ov_id = 1 (CS)
        //   - opcode = 01, modrm = C3
        //   - instr_length = 4
        //   - PC advances to 1011 + 4 = 1015
        // --------------------------------------------------------
        $display("=======================================");
        $display(" TEST 11: CS + REP + ADD (2E F3 01 C3) ");
        $display("=======================================");
        
        cache_line = 128'd0;
        load_cache_byte(0, 8'h2E); // CS Override
        load_cache_byte(1, 8'hF3); // REP
        load_cache_byte(2, 8'h01); // Opcode (ADD)
        load_cache_byte(3, 8'hC3); // ModRM (EAX, EBX)
        
        o_eip = 32'h0000_1011; 
        tail_ptr = 4'd10; // Plenty of bytes
        
        // This helper checks ld_eip and valid, but let's also manually check the decoder outputs
        check_result("Prefix Chain Test      ", 1'b1, 32'h0000_1015, 1'b1);
        
        #1; // Wait for combinational settle
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
        // Verifies that if stall_rr is high, we don't drop the prefixes.
        // --------------------------------------------------------
        stall_rr = 1;
        check_result("Stall during Prefix    ", 1'b0, 32'h0000_1011, 1'b1);
        stall_rr = 0;

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule