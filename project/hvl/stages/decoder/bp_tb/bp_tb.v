`timescale 1ns / 1ps

module tb_bp();

    initial begin
        $dumpfile("bp_tb.vpd"); 
        $dumpvars(0, tb_bp);    
    end

    // 1. Inputs
    reg clk;
    reg rst_bar;
    
    // Decode Stage Inputs
    reg is_branch;
    reg [31:0] o_eip;
    reg [31:0] i_eip;
    reg [127:0] cache_line;

    // Execute Stage Inputs
    reg br_t_nt_ex_d;
    reg br_valid_ex_d;
    reg [3:0] ext_pht_idx;

    // 2. Decoder Wires
    wire prefix_rep;
    wire prefix_op_size; 
    wire [2:0] prefix_seg_ov_id;
    wire prefix_seg;
    wire prefix_ext;
    wire [7:0] opcode;
    wire [7:0] modrm;
    wire modrm_v;
    wire [7:0] sib; 
    wire [1:0] disp_size_mux;
    wire [31:0] disp; 
    wire [2:0] imm_size;
    wire [47:0] imm;
    wire [1:0] addressing_mode;
    wire [3:0] instr_length;

    // 3. BP Wires
    wire cur_instr_prediction;
    wire [7:0] ghr_out;
    wire hit;
    wire [3:0] pht_idx;
    wire [31:0] bp_eip_target;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // State Tracking for Speculative GHRs
    reg [3:0] last_hash;
    reg captured_pred;
    reg [31:0] captured_tgt;
    
    reg [31:0] test_eip;
    reg [31:0] test_tgt;
    reg [31:0] target_offset;

    function [3:0] eip_low_for_hash;
        input [3:0] desired_hash;
        begin
            // hash = eip_low ^ (ghr[7:4] ^ ghr[3:0])
            eip_low_for_hash = desired_hash ^ (ghr_out[7:4] ^ ghr_out[3:0]);
        end
    endfunction

    // 4. Instantiate UUTs
    block_decoder DECODER(
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size), 
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_seg(prefix_seg),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm(modrm),
        .modrm_v(modrm_v),
        .sib(sib), 
        .disp_size_mux(disp_size_mux),
        .disp(disp), 
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .instr_length(instr_length),
        .ucode_sigs() // Unused in this testbench
    );

    bp PREDICTOR (
        .clk(clk),
        .rst_bar(rst_bar),
        .opcode(opcode),
        .imm(imm),
        .op_size_overload(prefix_op_size),
        .prefix_ext(prefix_ext),
        .is_branch(is_branch), 
        .o_eip(o_eip),
        .i_eip(i_eip),
        .br_t_nt_ex_d(br_t_nt_ex_d),
        .br_valid_ex_d(br_valid_ex_d),
        .ext_pht_idx(ext_pht_idx),
        .bp_eip_target(bp_eip_target), 
        .hit(hit),                     
        .cur_instr_prediction(cur_instr_prediction),
        .pht_idx(pht_idx),
        .ghr_out(ghr_out)
    );

    // 5. Clock Generation (100ns Period)
    always #50 clk = ~clk; 

    // 6. Tasks
    task check_result;
        input [8*35:1] test_name; 
        input exp_pred;
        input [31:0] exp_target;
        begin
            if (is_branch == 0) begin
                $display("  [PASS] | %0s | Not a branch (Ignored Target)", test_name);
                SUCCESSES = SUCCESSES + 1;
            // CHECK AGAINST THE CAPTURED PREDICTION, NOT THE LIVE WIRE!
            end else if (captured_pred === exp_pred && captured_tgt === exp_target) begin
                $display("  [PASS] | %0s | Pred: %b | Target: %h | Hash: %h", test_name, captured_pred, captured_tgt, last_hash);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  [FAIL] | %0s", test_name);
                $display("         EXPECTED: Pred=%b | Target=%h", exp_pred, exp_target);
                $display("         ACTUAL  : Pred=%b | Target=%h | Hash: %h", captured_pred, captured_tgt, last_hash);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    task test_decode;
        input [8*35:1] name;
        input [31:0] t_eip;
        input t_is_br;
        input [127:0] t_cache;
        input exp_pred;
        input [31:0] exp_tgt; //offset
        reg [31:0] dyn_exp_tgt;

        begin
            @(negedge clk);
            o_eip = t_eip;
            is_branch = t_is_br;
            cache_line = t_cache;
            br_valid_ex_d = 0; 
            
            // Wait 40ns (Clock posedge hits at +50ns). Let structural logic settle.
            #10;
            i_eip = o_eip + instr_length;
            dyn_exp_tgt = i_eip + exp_tgt; //Calculate dynamic expected target based on test EIP and offset
            #30; 
            // CAPTURE COMBINATIONAL OUTPUTS RIGHT BEFORE THE CLOCK EDGE!
            last_hash = PREDICTOR.hash_out; 
            captured_pred = cur_instr_prediction;
            captured_tgt = bp_eip_target;


            @(posedge clk); // Clock edge shifts GHR
            #20; 
            check_result(name, exp_pred, dyn_exp_tgt);
        end
    endtask

    task train_for_hit;
        begin
            @(negedge clk);
            is_branch = 0; 
            br_valid_ex_d = 1;
            br_t_nt_ex_d = 1;
            ext_pht_idx = last_hash; 
            
            @(negedge clk);
            br_valid_ex_d = 1;
            br_t_nt_ex_d = 1;
            ext_pht_idx = last_hash;
            
            @(negedge clk);
            br_valid_ex_d = 0; 
        end
    endtask

    task train_for_miss;
        begin
            @(negedge clk);
            is_branch = 0; 
            br_valid_ex_d = 1;
            br_t_nt_ex_d = 0;
            ext_pht_idx = last_hash; 
            
            @(negedge clk);
            br_valid_ex_d = 1;
            br_t_nt_ex_d = 0;
            ext_pht_idx = last_hash;
            
            @(negedge clk);
            br_valid_ex_d = 0; 
        end
    endtask

    task reset_predictor_state;
        begin
            @(negedge clk);
            rst_bar = 0;
            is_branch = 0;
            br_valid_ex_d = 0;
            br_t_nt_ex_d = 0;
            ext_pht_idx = 4'b0000;
            o_eip = 32'h01_00_00_00;
            cache_line = 128'h0;

            @(posedge clk);
            @(negedge clk);
            rst_bar = 1;
            @(posedge clk); #20;
        end
    endtask

    // 7. Stimulus
    initial begin
        $display("=======================================");
        $display(" DECODER + SPECULATIVE BP INTEGRATED   ");
        $display("=======================================");

        // Init
        clk = 0; rst_bar = 0; is_branch = 0;
        o_eip = 32'h01_00_00_00;
        cache_line = 128'h0;
        br_valid_ex_d = 0; br_t_nt_ex_d = 0; ext_pht_idx = 4'b0000;

        @(negedge clk); rst_bar = 1; 
        @(posedge clk); #20; 


        // ==========================================
        // GROUP 1: Extended Prefix Tests (0F 85 / 0F 87)
        // ==========================================
        $display("\n--- 1. Extended Prefix Tests ---");
        
        target_offset = 32'h00_00_10_24;
        test_eip = 32'h01_00_00_00;
        test_decode("0F 85 JNE rel32 (Untrained) ", test_eip, 1'b1, {80'h0, 48'h00_00_10_24_85_0F}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("0F 85 JNE rel32 (Trained)   ", test_eip, 1'b1, {80'h0, 48'h00_00_10_24_85_0F}, 1'b1, target_offset);

        test_decode("85 TEST (Not a branch)      ", 32'h01_00_00_00, 1'b0, {88'h0, 40'h00_00_10_24_85}, 1'bx, 32'hxxxx_xxxx);

        target_offset = 32'hFF_FF_FF_F0;
        test_eip = 32'h01_00_00_00;
        test_decode("0F 87 JNBE rel32 (Untrained)", test_eip, 1'b1, {80'h0, 48'hFF_FF_FF_F0_87_0F}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("0F 87 JNBE rel32 (Trained)  ", test_eip, 1'b1, {80'h0, 48'hFF_FF_FF_F0_87_0F}, 1'b1, target_offset);

        test_decode("87 XCHG (Not a branch)      ", 32'h01_00_00_00, 1'b0, {88'h0, 40'hFF_FF_FF_F0_87}, 1'bx, 32'hxxxx_xxxx);


        // ==========================================
        // GROUP 2: Op Size Override Tests (0x66)
        // ==========================================
        $display("\n--- 2. Operand Size Overrides (0x66) ---");
        reset_predictor_state();
        
        target_offset = 32'h00_00_24_10;
        test_eip = 32'h01_00_00_00;
        test_decode("66 0F 85 JNE rel16 (Untr)   ", test_eip, 1'b1, {88'h0, 40'h24_10_85_0F_66}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("66 0F 85 JNE rel16 (Trnd)   ", test_eip, 1'b1, {88'h0, 40'h24_10_85_0F_66}, 1'b1, target_offset);
        
        target_offset = 32'hFF_FF_FF_F0;
        test_eip = 32'h01_00_00_00;
        test_decode("66 0F 87 JNBE rel16 (Untr)  ", test_eip, 1'b1, {88'h0, 40'hFF_F0_87_0F_66}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("66 0F 87 JNBE rel16 (Trnd)  ", test_eip, 1'b1, {88'h0, 40'hFF_F0_87_0F_66}, 1'b1, target_offset);


        // ==========================================
        // GROUP 3: Unconditional Calls and Jumps
        // ==========================================
        $display("\n--- 3. Unconditional Rel32 / Rel16 ---");
        reset_predictor_state();

        target_offset = 32'h00_00_12_34;
        test_eip = 32'h01_00_00_00;
        test_decode("E8 CALL rel32 (Untrained)   ", test_eip, 1'b1, {88'h0, 40'h00_00_12_34_E8}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("E8 CALL rel32 (Trained)     ", test_eip, 1'b1, {88'h0, 40'h00_00_12_34_E8}, 1'b1, target_offset);

        target_offset = 32'h00_00_12_34;
        test_eip = 32'h01_00_00_00;
        test_decode("66 E8 CALL rel16 (Untrained)", test_eip, 1'b1, {96'h0, 32'h12_34_E8_66}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("66 E8 CALL rel16 (Trained)  ", test_eip, 1'b1, {96'h0, 32'h12_34_E8_66}, 1'b1, target_offset);

        target_offset = 32'h00_00_00_55;
        test_eip = 32'h01_00_00_00;
        test_decode("E9 JMP rel32 (Untrained)    ", test_eip, 1'b1, {88'h0, 40'h00_00_00_55_E9}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("E9 JMP rel32 (Trained)      ", test_eip, 1'b1, {88'h0, 40'h00_00_00_55_E9}, 1'b1, target_offset);


        // ==========================================
        // GROUP 4: 8-bit Rel Jumps
        // ==========================================
        $display("\n--- 4. Rel8 Jumps ---");
        reset_predictor_state();

        target_offset = 32'h00_00_00_08;
        test_eip = 32'h01_00_00_00;
        test_decode("75 JNE rel8 (Untrained)     ", test_eip, 1'b1, {112'h0, 16'h08_75}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("75 JNE rel8 (Trained)       ", test_eip, 1'b1, {112'h0, 16'h08_75}, 1'b1, target_offset);

        target_offset = 32'h00_00_00_1A;
        test_eip = 32'h01_00_00_00;
        test_decode("EB JMP rel8 (Untrained)     ", test_eip, 1'b1, {112'h0, 16'h1A_EB}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("EB JMP rel8 (Trained)       ", test_eip, 1'b1, {112'h0, 16'h1A_EB}, 1'b1, target_offset);


        // ==========================================
        // GROUP 5: Aliasing Tests
        // ==========================================
        $display("\n--- 5. PHT Aliasing Tests ---");
        reset_predictor_state();
        
        target_offset = 32'h00_00_00_08;
        test_eip = 32'h01_00_00_04;
        test_decode("Br A (Untrained)            ", test_eip, 1'b1, {112'h0, 16'h08_75}, 1'b0, target_offset);
        train_for_hit();
        
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("Br A (Trained)              ", test_eip, 1'b1, {112'h0, 16'h08_75}, 1'b1, target_offset);

        // Branch B uses a different instruction block base address (0x02_00_00_00)
        // But we force its lower bits to ALIAS to Branch A's hash.
        target_offset = 32'h00_00_00_1A;
        test_eip = {28'h02_00_00_0, eip_low_for_hash(last_hash)}; 
        
        // This predicts TAKEN (1) because Branch A trained the entry!
        test_decode("Br B (Aliased to A)         ", test_eip, 1'b1, {112'h0, 16'h1A_EB}, 1'b1, target_offset); 
        
        // Force Branch B to Miss (Destroying Branch A's prediction state)
        train_for_miss(); 

        // Re-test Branch A (Expected prediction is now 0)
        target_offset = 32'h00_00_00_08;
        test_eip = {28'h01_00_00_0, eip_low_for_hash(last_hash)};
        test_decode("Br A (Destructive Alias)    ", test_eip, 1'b1, {112'h0, 16'h08_75}, 1'b0, target_offset);

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule