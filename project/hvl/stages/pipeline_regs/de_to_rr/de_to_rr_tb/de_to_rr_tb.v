module de_to_rr_tb;

    // ---------------------------------------------------------
    // 1. Setup & Printing Logic
    // ---------------------------------------------------------
    initial begin
        // $vcdplusfile("de_to_rr_tb.dump.vpd");
        // $vcdpluson(0, de_to_rr_tb); 
    end

    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    reg clk;
    reg rst_bar;

    // ---------------------------------------------------------
    // 2. Signals
    // ---------------------------------------------------------
    reg [127:0] cache_line;
    reg [31:0]  o_eip_in; 
    reg [3:0]   tail_ptr;
    reg [19:0]  cs_limit_reg;
    reg [31:0]  eip_target_ex; 
    reg         flush_ex; 
    reg         v_excptn_src_wb, v_ld_cs_src_ex; // Kept so test cases don't break
    reg         stall_rr; 
    reg         br_t_nt_ex_d, br_valid_ex_d;
    reg [3:0]   pht_idx_ex_d;

    // Internal Wires (Decode -> Pipe Reg)
    wire exptn_prot;
    wire [31:0] i_eip;
    wire pr_de_rr_valid;
    wire ld_eip;           
    wire [31:0] eip_true;  
    
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0]  prefix_seg_ov_id;
    wire [7:0]  opcode, modrm, sib;
    wire [1:0]  disp_size_mux; 
    wire [1:0]  imm_size;        
    wire [1:0]  addressing_mode; 
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0]  instr_length;
    
    // Output Wires (Pipe Reg -> RR Stage)
    wire [1:0]  to_rr_exception_flags;
    wire [31:0] to_rr_i_eip, to_rr_o_eip, to_rr_bp_target;
    wire        to_rr_pr_valid;
    wire [5:0]  to_rr_prefixes;
    wire [7:0]  to_rr_opcode, to_rr_modrm, to_rr_sib;
    wire [1:0]  to_rr_disp_size_mux;
    wire [2:0]  to_rr_imm_size;       
    wire [1:0]  to_rr_addressing_mode;
    wire [31:0] to_rr_disp;
    wire [47:0] to_rr_imm;
    wire [3:0]  to_rr_instr_length;

    // ---------------------------------------------------------
    // 3. Instantiations
    // ---------------------------------------------------------
    stage_decode dut_decode (
        .cache_line(cache_line), 
        .o_eip(o_eip_in), 
        .tail_ptr(tail_ptr),
        .cs_limit_reg(cs_limit_reg), 
        .eip_target_ex(eip_target_ex),
        .flush_ex(flush_ex), 
        .v_excptn_src_wb(v_excptn_src_wb),
        // REMOVED: .v_ld_cs_src_ex(v_ld_cs_src_ex) to match new port list
        .stall_rr(stall_rr), 
        .clk(clk), 
        .rst_bar(rst_bar), 
        .br_t_nt_ex_d(br_t_nt_ex_d),
        .br_valid_ex_d(br_valid_ex_d), 
        .pht_idx_ex_d(pht_idx_ex_d),
        .exptn_prot(exptn_prot), 
        .i_eip(i_eip), 
        .pr_de_rr_valid(pr_de_rr_valid),
        .ld_eip(ld_eip),         
        .eip_true(eip_true),     
        .prefix_rep(prefix_rep), 
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id), 
        .prefix_seg(), 
        .prefix_ext(prefix_ext),
        .opcode(opcode), 
        .modrm(modrm), 
        .sib(sib),
        .disp_size_mux(disp_size_mux), 
        .disp(disp), 
        .imm_size(imm_size),
        .imm(imm), 
        .addressing_mode(addressing_mode), 
        .instr_length(instr_length)
    );

    de_to_rr dut_pipe (
        .clk(clk), .rst(rst_bar),
        .from_de_ld_pr(~stall_rr),
        .from_de_exptn_prot(exptn_prot), .from_f_exception_flags(2'b0),
        .from_de_i_eip(i_eip), .from_de_o_eip(o_eip_in), .from_de_bp_target(32'h0),
        .from_de_pr_valid(pr_de_rr_valid), .from_de_prefix_rep(prefix_rep),
        .from_de_prefix_op_size(prefix_op_size), .from_de_prefix_seg_ov_id(prefix_seg_ov_id),
        .from_de_prefix_ext(prefix_ext), .from_de_opcode(opcode), .from_de_modrm(modrm),
        .from_de_sib(sib), .from_de_disp_size_mux(disp_size_mux), .from_de_disp(disp),
        .from_de_imm_size({1'b0, imm_size}), // Zero-extended to match the [2:0] input size
        .from_de_imm(imm),
        .from_de_addressing_mode(addressing_mode), .from_de_instr_length(instr_length),
        .to_rr_exception_flags(to_rr_exception_flags),
        .to_rr_i_eip(to_rr_i_eip), .to_rr_o_eip(to_rr_o_eip), .to_rr_bp_target(to_rr_bp_target),
        .to_rr_pr_valid(to_rr_pr_valid), .to_rr_prefixes(to_rr_prefixes),
        .to_rr_opcode(to_rr_opcode), .to_rr_modrm(to_rr_modrm), .to_rr_sib(to_rr_sib),
        .to_rr_disp_size_mux(to_rr_disp_size_mux), .to_rr_disp(to_rr_disp),
        .to_rr_imm_size(to_rr_imm_size), .to_rr_imm(to_rr_imm),
        .to_rr_addressing_mode(to_rr_addressing_mode), .to_rr_instr_length(to_rr_instr_length)
    );

    // ---------------------------------------------------------
    // 4. Tasks & Stimulus
    // ---------------------------------------------------------
    always #20 clk = ~clk;

    task print_rr_pipe_out;
    begin
        $display("************************************************");
        $display("************* DE_TO_RR PIPE OUT ****************");
        $display("************************************************");
        $display("to_rr_valid=%b, to_rr_opcode=%h, to_rr_modrm=%h", to_rr_pr_valid, to_rr_opcode, to_rr_modrm);
        $display("to_rr_prefixes={rep:%b, opsz:%b, segid:%b, ext:%b}", to_rr_prefixes[5], to_rr_prefixes[4], to_rr_prefixes[3:1], to_rr_prefixes[0]);
        $display("to_rr_sib=%h, to_rr_disp=%h, to_rr_imm=%h", to_rr_sib, to_rr_disp, to_rr_imm);
        $display("to_rr_i_eip=%h, to_rr_o_eip=%h, instr_len=%d", to_rr_i_eip, to_rr_o_eip, to_rr_instr_length);
        $display("addressing_mode=%b, imm_size=%b, disp_size_mux=%b", to_rr_addressing_mode, to_rr_imm_size, to_rr_disp_size_mux);
        $display("\n");
    end
    endtask

    task check_results(input [7:0] exp_op, input [7:0] exp_mod, input [5:0] exp_pref, input exp_valid, input [255:0] name);
    begin
        @(posedge clk); #2; 
        $display("DEBUG [%s]:", name);
        $display("  Raw reg_in:  %h", dut_pipe.reg_in);
        $display("  Raw reg_out: %h", dut_pipe.reg_out);

        if (to_rr_opcode !== exp_op || to_rr_modrm !== exp_mod || to_rr_prefixes !== exp_pref || to_rr_pr_valid !== exp_valid) begin
            $display("FAIL: %s | Exp Op:%h Mod:%h Got Op:%h Mod:%h", name, exp_op, exp_mod, to_rr_opcode, to_rr_modrm);
            $display("sib_byte_true: %d | modrm_true: %d", dut_decode.DECODER.sib_byte_true, dut_decode.DECODER.is_modrm_true);
            FAILURES = FAILURES + 1;
        end else begin
            $display("PASS: %s", name);
            SUCCESSES = SUCCESSES + 1;
        end
        print_rr_pipe_out();
    end
    endtask

    task clear_inputs;
    begin
        cache_line = 128'h0; o_eip_in = 32'h0; tail_ptr = 4'hF; // Max tail ptr
        cs_limit_reg = 20'hFFFFF; eip_target_ex = 32'h0;
        flush_ex = 0; v_excptn_src_wb = 0; v_ld_cs_src_ex = 0;
        stall_rr = 0; 
        br_t_nt_ex_d = 0; br_valid_ex_d = 0; pht_idx_ex_d = 0;
    end
    endtask

    initial begin
        clk = 0; rst_bar = 0;
        clear_inputs();
        #10 rst_bar = 1;

        // TEST 1: ADD EAX, EBX
        @(negedge clk);
        cache_line = 128'h0000_0000_0000_0000_0000_0000_0000_C301;
        o_eip_in = 32'h1000;
        check_results(8'h01, 8'hC3, 6'b000110, 1'b1, "ADD EAX, EBX");

        // TEST 2: Stall Test
        @(negedge clk);
        stall_rr = 1;
        cache_line = 128'h0000_0000_0000_0000_0000_0000_0000_01D1;
        check_results(8'h01, 8'hC3, 6'b000110, 1'b1, "Stall Test (Register Held)");

        // TEST 3: Prefix Test (CS + REP)
        @(negedge clk);
        #5;
        stall_rr = 0;
        cache_line = 128'h0000_0000_0000_0000_0000_0000_C301F32E; 
        check_results(8'h01, 8'hC3, 6'b100010, 1'b1, "Prefix Bundle Test (CS + REP)");
       
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule