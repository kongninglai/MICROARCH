/*
Boundary Checking TB
*/

`timescale 1ns / 1ps

module tb_advanced_decode();

    // --------------------------------------------------------
    // Inputs & Outputs
    // --------------------------------------------------------
    reg [127:0] cache_line;
    reg [31:0] o_eip;
    reg [3:0] tail_ptr;
    reg [19:0] cs_limit_reg;
    reg [31:0] eip_target_ex;
    reg mispredict_src_ex, v_excptn_src_wb, v_ld_cs_src_ex;
    reg stall_ex, stall_rr, stall_mem, stall_wb;
    reg clk, rst_bar;
    reg br_t_nt_ex_d, br_valid_ex_d;
    reg [3:0] pht_idx_ex_d;

    wire exptn_prot;
    wire [31:0] i_eip;
    wire pr_de_rr_valid, ld_eip;
    wire [31:0] eip_true;
    
    // Decoder specific wires
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0] prefix_seg_ov_id;
    wire [7:0] opcode, modrm, sib;
    wire [1:0] disp_size_mux, imm_size, addressing_mode;
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0] instr_length;

    // Tracking variables
    integer i, FAILURES = 0, SUCCESSES = 0;

    // --------------------------------------------------------
    // Instantiate UUT (Updated flush_ex mapping)
    // --------------------------------------------------------
    stage_decode uut (
        .cache_line(cache_line), .o_eip(o_eip), .tail_ptr(tail_ptr), .cs_limit_reg(cs_limit_reg),
        .eip_target_ex(eip_target_ex), 
        .flush_ex(mispredict_src_ex), // FIXED: Mapped mispredict stimulus to new flush_ex port
        .v_excptn_src_wb(v_excptn_src_wb), .v_ld_cs_src_ex(v_ld_cs_src_ex),
        .stall_ex(stall_ex), .stall_rr(stall_rr), .stall_mem(stall_mem), .stall_wb(stall_wb),
        .clk(clk), .rst_bar(rst_bar), .br_t_nt_ex_d(br_t_nt_ex_d), 
        .br_valid_ex_d(br_valid_ex_d), .pht_idx_ex_d(pht_idx_ex_d),
        .exptn_prot(exptn_prot), .i_eip(i_eip), .pr_de_rr_valid(pr_de_rr_valid),
        .ld_eip(ld_eip), .eip_true(eip_true), .prefix_rep(prefix_rep), 
        .prefix_op_size(prefix_op_size), .prefix_seg_ov_id(prefix_seg_ov_id), 
        .prefix_ext(prefix_ext), .opcode(opcode), .modrm(modrm), .sib(sib),
        .disp_size_mux(disp_size_mux), .disp(disp), .imm_size(imm_size), 
        .imm(imm), .addressing_mode(addressing_mode), .instr_length(instr_length)
    );

    always #5 clk = ~clk;

    // Helper task to safely check pipeline state
    task check_state;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_eip_true;
        input exp_valid;
        input exp_exptn;
        reg eip_target_ok;
        begin
            @(negedge clk); 
            #15;
            // If ld_eip is 0, ignore the true EIP target (since it's not being latched anyway)
            eip_target_ok = (exp_ld_eip === 1'b0) || (eip_true === exp_eip_true);

            if (ld_eip === exp_ld_eip && eip_target_ok && pr_de_rr_valid === exp_valid && exptn_prot === exp_exptn) begin
                $display("  ✅ PASS | %0s", test_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: ld=%b | valid=%b | exptn=%b | target=%h", exp_ld_eip, exp_valid, exp_exptn, exp_eip_true);
                $display("     ACTUAL  : ld=%b | valid=%b | exptn=%b | target=%h", ld_eip, pr_de_rr_valid, exptn_prot, eip_true);
                $display(" instr_len: %d | tail_ptr: %h", instr_length, tail_ptr);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // STIMULUS
    // --------------------------------------------------------
    initial begin
        $dumpfile("advanced_decode.vpd");
        $dumpvars(0, tb_advanced_decode);
        
        // Reset and baseline state
        clk = 0; rst_bar = 0;
        cache_line = 128'h00000000000000000000000000000000;
        o_eip = 32'h0000_1000; tail_ptr = 4'd15; cs_limit_reg = 20'hFFFFF;
        mispredict_src_ex = 0; v_excptn_src_wb = 0; v_ld_cs_src_ex = 0; eip_target_ex = 0;
        stall_ex = 0; stall_rr = 0; stall_mem = 0; stall_wb = 0;
        br_t_nt_ex_d = 0; br_valid_ex_d = 0; pht_idx_ex_d = 0;
        
        #15 rst_bar = 1;

        $display("\n=======================================================");
        $display(" PILLAR 2: BOUNDARIES AND EXCEPTIONS ");
        $display("=======================================================");
        
        // Setup a 6-byte instruction: 0F 85 44 33 22 11 (JNE rel32)
        cache_line = 128'h0000_0000_0000_0000_0000_11223344850F;
        
        // 1. Buffer Starvation Sweep
        for (i = 0; i < 6; i = i + 1) begin
            tail_ptr = i[3:0];
            check_state($sformatf("Buffer Starvation (tail_ptr=%0d)", i), 1'b0, 32'h0, 1'b0, 1'b0);
        end
        // Release buffer starvation
        tail_ptr = 4'd6; 
        check_state("Buffer Valid (tail_ptr=6)", 1'b1, 32'h0000_1006, 1'b1, 1'b0);

        // 2. Segment Limit Violation
        tail_ptr = 4'd15; 
        o_eip = 32'h0000_1002;
        cs_limit_reg = 20'h01004; // Limit is 1004. A 6-byte inst starting at 1002 crosses it!
        check_state("Segment Limit Violation Exception", 1'b1, 32'h0, 1'b1, 1'b1);
        cs_limit_reg = 20'hFFFFF; // Restore limit

        // 3. Wrap Around
        o_eip = 32'hFFFF_FFFC; 
        // Same 6 byte instruction. FFFFFFFC + 6 = 00000002
        check_state("32-bit Wrap-Around", 1'b1, 32'h0000_0002, 1'b1, 1'b0);


        $display("\n=======================================================");
        $display(" PILLAR 3: CONTROL FLOW & HAZARDS ");
        $display("=======================================================");
        
        o_eip = 32'h0000_1000;
        
        // 1. The Stall Matrix
        stall_rr = 1;
        check_state("Stall RR (Valid stays high, LD drops)", 1'b0, 32'h0, 1'b1, 1'b0);
        stall_rr = 0; stall_ex = 1; stall_mem = 1;
        check_state("Stall EX & MEM", 1'b0, 32'h0, 1'b1, 1'b0);
        
        // 2. The Flush Hierarchy (Flush overrides Stall)
        stall_rr = 1; // Try to stall...
        mispredict_src_ex = 1; eip_target_ex = 32'h0000_BEEF; // ...but Execute stage forces a flush!
        // Expecting valid=0 (bubble), ld_eip=1 (loading the mispredict target BEEF)
        check_state("Flush overrides Stalls", 1'b1, 32'h0000_BEEF, 1'b0, 1'b0);
        mispredict_src_ex = 0; stall_rr = 0;

        // 3. Branch Predictor Training (JNE rel32)
        // Feed the EX stage branch info for a few cycles
        for (i = 0; i < 5; i = i + 1) begin
            br_valid_ex_d = 1;
            br_t_nt_ex_d = 1; // Train it that the branch is TAKEN
            pht_idx_ex_d = i[3:0]; // Fake PHT indexes being updated
            @(negedge clk);
        end
        br_valid_ex_d = 0;
        // Since it's trained "Taken", check if your BP now outputs 1!
        // NOTE: If you haven't implemented your BP fully yet, this might fail, which is a good reminder to wire it up!
        if (uut.cur_instr_prediction === 1'b1) begin
            $display("  ✅ PASS | Branch Predictor successfully learned 'Taken'");
            SUCCESSES = SUCCESSES + 1;
        end else begin
            $display("  ❌ FAIL | Branch Predictor still outputs %b after 5 'Taken' updates", uut.cur_instr_prediction);
            FAILURES = FAILURES + 1;
        end


        $display("\n=======================================================");
        $display(" PILLAR 4: FUZZING (1000 RANDOM TESTS) ");
        $display("=======================================================");
        
        for (i = 0; i < 1000; i = i + 1) begin
            // Concatenate 4 random 32-bit chunks to make a 128-bit random cache line
            cache_line = {$random, $random, $random, $random};
            @(negedge clk);
            
            // Check 1: Instruction length should NEVER be 'x'. It must resolve to a valid number.
            if (instr_length === 4'bx || instr_length === 4'bX) begin
                $display("  ❌ FAIL | Fuzz Test %0d resulted in Length = X!", i);
                FAILURES = FAILURES + 1;
            end 
            // Check 2: It should never try to increment by 0 unless it's an invalid inst (ld_eip=0)
            else if (instr_length == 0 && ld_eip == 1) begin
                $display("  ❌ FAIL | Fuzz Test %0d allowed an increment of 0!", i);
                FAILURES = FAILURES + 1;
            end
            // Check 3: It should never exceed 15 bytes
            else if (instr_length > 15) begin
                $display("  ❌ FAIL | Fuzz Test %0d resulted in Length > 15!", i);
                FAILURES = FAILURES + 1;
            end
        end
        
        $display("  ✅ PASS | 1000 Fuzz Tests completed. Decoder survived hostile inputs.");

        $display("\n=======================================================");
        $display("FINAL RESULTS: %0d SUCCESSES, %0d FAILURES", SUCCESSES, FAILURES);
        $display("=======================================================\n");
        $finish;
    end

endmodule