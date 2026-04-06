module fetch_decode_top_tb;

initial begin
  $vcdplusfile("fetch_decode_top_tb.dump.vpd");
  $vcdpluson(0, fetch_decode_top_tb);
  $vcdpluson(0, fetch_decode_top_tb.DUT);
end

localparam MEM_BYTE_CAPACITY    = 32768;
localparam MEM_ADDR_WIDTH       = $clog2(MEM_BYTE_CAPACITY);

localparam BUS_BIT_WIDTH        = 32;
localparam RANK_BIT_WIDTH       = 128;
localparam RANK_BURST_SIZE      = RANK_BIT_WIDTH/BUS_BIT_WIDTH;

localparam VA_BIT_WIDTH         = 32;
localparam PAGE_SIZE_BYTES      = 4096;
localparam PAGE_BIT_WIDTH       = $clog2(PAGE_SIZE_BYTES);
localparam PFN_BIT_WIDTH        = MEM_ADDR_WIDTH - PAGE_BIT_WIDTH;
localparam VPN_BIT_WIDTH        = VA_BIT_WIDTH - PAGE_BIT_WIDTH;

localparam SEGR_DATA_BIT_WIDTH  = 16;

localparam CYCLE_TIME_X10 = 98;
localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;

reg clk;
reg rst_n;

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

//IO of integrated fetch-decode
wire [VPN_BIT_WIDTH-1:0] ITLB_VPN;
wire [PFN_BIT_WIDTH-1:0] ITLB_PFN_OUT;
wire ITLB_PAGE_FAULT_OUT;

wire ICACHE_VALID;
wire [RANK_BIT_WIDTH-1:0] ICACHE_HIT_DATA;
wire [PAGE_BIT_WIDTH-1:0] F_PAGE_OFFSET;

//reg [VA_BIT_WIDTH-1:0] from_de_bp_target_out;
reg [SEGR_DATA_BIT_WIDTH-1:0] from_rr_cs;
reg from_rr_stall;
reg from_ex_ld_cs;
reg [VA_BIT_WIDTH-1:0] from_ex_eip_target_out;
reg from_ex_flush;
reg from_ex_br_t_nt;
reg from_ex_br_valid;
reg [3:0] from_ex_pht_idx;
reg from_wb_flush;

wire [5:0] to_rr_prefix;
wire [7:0] to_rr_opcode;
wire [7:0] to_rr_modrm;
wire [7:0] to_rr_sib;
wire [31:0] to_rr_disp;
wire [1:0] to_rr_dispsize;
wire [47:0] to_rr_imm;
wire [2:0] to_rr_imm_size;
wire [1:0] to_rr_addr_mode;
wire [31:0] to_rr_oeip;
wire [31:0] to_rr_ieip;
wire [31:0] to_rr_pred_eip;
wire [31:0] to_pr_pred_eip;
wire [1:0] to_rr_exception;
wire to_rr_valid;

//mem?
wire [PFN_BIT_WIDTH-1:0] KB_PFN;
wire [PFN_BIT_WIDTH-1:0] DMA_PFN;
wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [15:0] WR_mask;
wire [2:0] ICACHE_SET = F_PAGE_OFFSET[6:4];

fetch_decode_top DUT (
    .clk(clk),
    .rst_bar(rst_n),

    .ITLB_VPN(ITLB_VPN),
    .ITLB_PFN_OUT(ITLB_PFN_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

    .ICACHE_VALID(ICACHE_VALID),
    .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
    .F_PAGE_OFFSET(F_PAGE_OFFSET),

    //Pipeline Inputs
    .from_rr_cs(from_rr_cs),
    .from_rr_stall(from_rr_stall),

    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_eip_target(from_ex_eip_target_out),
    .from_ex_flush(from_ex_flush),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_pht_idx(from_ex_pht_idx),

    .from_wb_flush(from_wb_flush),

    //Outputs
    .to_rr_prefix(to_rr_prefix),
    .to_rr_opcode(to_rr_opcode),
    .to_rr_modrm(to_rr_modrm),
    .to_rr_sib(to_rr_sib),
    .to_rr_disp(to_rr_disp),
    .to_rr_dispsize(to_rr_dispsize),
    .to_rr_imm(to_rr_imm),
    .to_rr_imm_size(to_rr_imm_size),
    .to_rr_addr_mode(to_rr_addr_mode),
    .to_rr_oeip(to_rr_oeip),
    .to_rr_ieip(to_rr_ieip),
    .to_rr_pred_eip(to_rr_pred_eip),
    .to_pr_pred_eip(to_pr_pred_eip),
    .to_rr_exception(to_rr_exception),
    .to_rr_valid(to_rr_valid)
);

full_cache #(
  .MEM_BYTE_CAPACITY (MEM_BYTE_CAPACITY),
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (1)
) full_cache_inst (
  .rst(rst_n),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(1'b0),
  .STOREQ_LAST_ENTRY(1'b0),
  .STOREQ_DATA(128'd0),
  .STOREQ_DATA_WR_MASK(16'd0),
  .STOREQ_PHYS_ADDR(11'd0),

  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .D_RD_TLB_PFN_OUT({PFN_BIT_WIDTH{1'b0}}),
  .D_RD_TLB_CACHE_ENABLE_OUT(1'b0),

  .F_PAGE_OFFSET(F_PAGE_OFFSET),
  .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
  .ICACHE_VALID(ICACHE_VALID),

  .MEM_PAGE_OFFSET({PAGE_BIT_WIDTH{1'b0}}),
  .MEM_VALID_LOAD_INST(1'b0),

  .WB_PR_ST_ADDR_L0(11'd0),
  .WB_PR_ST_MASK_L0(16'd0),
  .WB_SHF_ST_DATA_L0(128'd0),
  .WB_VALID_IO_STORE_INST(1'b0),

  .DCACHE_HIT_DATA(),
  .DCACHE_HIT(),
  .DCACHE_STALL(),
  .WBE_BUSY(),

  .DMA_INT(),

  .TEST_CASE_NEW_CHAR(8'd0),
  .TEST_CASE_NEW_CHAR_WR(8'd0),
  .TEST_CASE_NEW_READY(1'b0),
  .TEST_CASE_NEW_READY_WR(1'b0),

  .WB_FLUSH(from_wb_flush),
  .EX_FLUSH(from_ex_flush)
);

tlb_wrapper tlb_inst (
  .ITLB_VPN(ITLB_VPN),
  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_WRITE_DISABLE_OUT(),
  .ITLB_CACHE_ENABLE_OUT(),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .D_RD_TLB_VPN({VPN_BIT_WIDTH{1'b0}}),
  .D_RD_TLB_PFN_OUT(),
  .D_RD_TLB_WRITE_DISABLE_OUT(),
  .D_RD_TLB_CACHE_ENABLE_OUT(),
  .D_RD_TLB_PAGE_FAULT_OUT(),

  .D_WR0_TLB_VPN({VPN_BIT_WIDTH{1'b0}}),
  .D_WR0_TLB_PFN_OUT(),
  .D_WR0_TLB_WRITE_DISABLE_OUT(),
  .D_WR0_TLB_CACHE_ENABLE_OUT(),
  .D_WR0_TLB_PAGE_FAULT_OUT(),

  .D_WR1_TLB_VPN({VPN_BIT_WIDTH{1'b0}}),
  .D_WR1_TLB_PFN_OUT(),
  .D_WR1_TLB_WRITE_DISABLE_OUT(),
  .D_WR1_TLB_CACHE_ENABLE_OUT(),
  .D_WR1_TLB_PAGE_FAULT_OUT(),

  .DMA_PFN(DMA_PFN),
  .KB_PFN(KB_PFN)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

assign from_fetch_buffer_write_enable = ICACHE_VALID;

reg [VA_BIT_WIDTH-1:0]  EXPECTED_INST_ADDR;

// always @(posedge clk) begin
//   if (rst_n === 1'b0) begin
//     EXPECTED_INST_ADDR = ({from_rr_code_segment, 16'd0} + 0);
//   end else if (from_ex_flush === 1'b1) begin
//     EXPECTED_INST_ADDR <= ({from_rr_code_segment, 16'd0} + from_ex_eip_target_out) & 32'hFFFFFFF0;
//   end else if (from_de_taken_predicted_branch === 1'b1) begin
//     EXPECTED_INST_ADDR <= ({from_rr_code_segment, 16'd0} + from_de_bp_target_out) & 32'hFFFFFFF0;
//   end else if (ICACHE_VALID === 1'b1) begin
//     EXPECTED_INST_ADDR <= EXPECTED_INST_ADDR + 16;
//   end

//   if ({ITLB_VPN, F_PAGE_OFFSET} !== EXPECTED_INST_ADDR) begin
//     FAILURES = FAILURES + 1;
//     $display("FAILURE AT TIME %t: EXPECTED_INST_ADDR exp=%h got=%h", $time, EXPECTED_INST_ADDR, {ITLB_VPN, F_PAGE_OFFSET});
//   end else begin
//     SUCCESSES = SUCCESSES + 1;
//     // $display("SUCCESS AT TIME %t: EXPECTED_INST_ADDR exp=%h got=%h", $time, EXPECTED_INST_ADDR, {ITLB_VPN, F_PAGE_OFFSET});
//   end
// end

always @(posedge clk) begin
    if (rst_n === 1'b0) begin
        // Reset to CS base
        EXPECTED_INST_ADDR <= ({from_rr_cs, 16'd0} + 0);

    end else if (from_ex_flush === 1'b1) begin
        // Execute Flush
        EXPECTED_INST_ADDR <= ({from_rr_cs, 16'd0} + from_ex_eip_target_out) & 32'hFFFFFFF0;

    end else if (DUT.from_de_take_branch === 1'b1) begin
        // USE HIERARCHICAL PATH to read the internal branch signal
        // We use to_pr_pred_eip because you made it an output port of the DUT
        EXPECTED_INST_ADDR <= ({from_rr_cs, 16'd0} + to_pr_pred_eip) & 32'hFFFFFFF0;

    end else if (DUT.from_fetch_buffer_shft_reg_we === 1'b1) begin
        // USE HIERARCHICAL PATH to read the internal shift enable
        // Only increment when the buffer actually shifts to a new cache line!
        EXPECTED_INST_ADDR <= EXPECTED_INST_ADDR + 16;
    end

    // The Verification Check (Only check when out of reset)
    if (rst_n === 1'b1) begin
        if ({ITLB_VPN, F_PAGE_OFFSET} !== EXPECTED_INST_ADDR) begin
            FAILURES = FAILURES + 1;
            $display("❌ HW FAILURE AT TIME %t: FETCH ADDR exp=%h got=%h", 
                     $time, EXPECTED_INST_ADDR, {ITLB_VPN, F_PAGE_OFFSET});
        end
    end
end

//Verify Task
task verify_instruction;
    input [8*40:1] inst_name;
    input [31:0] exp_ieip;
    input [31:0] exp_oeip;
    input [5:0]  exp_prefix;     // {rep(1), opsize(1), seg_ov(3), ext(1)}
    input [7:0]  exp_opcode;
    input        exp_has_modrm;  // 1 if we expect a ModRM byte, 0 otherwise
    input [7:0]  exp_modrm;
    input [2:0]  exp_imm_size;   // 000(0), 001(1), 010(2), 100(4)
    input [47:0] exp_imm;
    
    integer timeout;
    reg passed;
    begin
        passed = 1;
        timeout = 0;
        
        // Wait for Decode to declare the instruction valid (Timeout after 20 cycles)
        while (to_rr_valid !== 1'b1 && timeout < 20) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (timeout >= 20) begin
            $display(" ❌ FAIL | %0s | Timeout waiting for to_rr_valid", inst_name);
            FAILURES = FAILURES + 1;
        end else begin
            // Check EIPs
            if (to_rr_ieip !== exp_ieip) begin
                $display("    [EIP ERROR]   Exp iEIP: %h | Got: %h", exp_ieip, to_rr_ieip);
                passed = 0;
            end
            if (to_rr_oeip !== exp_oeip) begin
                $display("    [EIP ERROR]   Exp oEIP: %h | Got: %h", exp_oeip, to_rr_oeip);
                passed = 0;
            end
            
            // Check Prefix and Opcode
            if (to_rr_prefix !== exp_prefix) begin
                $display("    [PFX ERROR]   Exp Pfx: %b | Got: %b", exp_prefix, to_rr_prefix);
                passed = 0;
            end
            if (to_rr_opcode !== exp_opcode) begin
                $display("    [OP ERROR]    Exp Opcode: %h | Got: %h", exp_opcode, to_rr_opcode);
                passed = 0;
            end

            // Check ModRM conditionally
            if (exp_has_modrm) begin
                if (to_rr_modrm !== exp_modrm) begin
                    $display("    [MODRM ERROR] Exp ModRM: %h | Got: %h", exp_modrm, to_rr_modrm);
                    passed = 0;
                end
                // Validate address mode confirms ModRM (01) or SIB (11)
                if (to_rr_addr_mode !== 2'b01 && to_rr_addr_mode !== 2'b11) begin
                    $display("    [ADDR ERROR]  Expected ModRM but addr_mode is %b", to_rr_addr_mode);
                    passed = 0;
                end
            end

            // Check Immediate conditionally
            if (to_rr_imm_size !== exp_imm_size) begin
                $display("    [IMM SZ ERR]  Exp Size: %b | Got: %b", exp_imm_size, to_rr_imm_size);
                passed = 0;
            end else if (exp_imm_size > 0 && to_rr_imm !== exp_imm) begin
                $display("    [IMM ERROR]   Exp Imm: %h | Got: %h", exp_imm, to_rr_imm);
                passed = 0;
            end

            // Pass/Fail Result
            if (passed) begin
                $display(" ✅ PASS | %0s", inst_name);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display(" ❌ FAIL | %0s", inst_name);
                FAILURES = FAILURES + 1;
            end
            
            // Step one clock forward so we don't double-trigger on the same valid signal
            @(negedge clk);
        end
    end
endtask

//Test case File Parser
integer trace_file;
integer scan_res;
reg [31:0] exp_ieip, exp_oeip;
reg [5:0]  exp_prefix;
reg [7:0]  exp_opcode, exp_modrm;
reg        exp_has_modrm;
reg [2:0]  exp_imm_size;
reg [47:0] exp_imm;
integer    instruction_count;
task run_automated_verification;
    begin
        instruction_count = 0;
        // 1. Open the file (Make sure it's in your simulation directory)
        trace_file = $fopen("testcase_dcache.txt", "r");
        if (trace_file == 0) begin
            $display("CRITICAL ERROR: Could not open test case expected values file.");
            $finish;
        end

        $display("=======================================");
        $display("      STARTING AUTOMATED TRACE         ");
        $display("=======================================");

        // 2. Loop through the file until the end
        while (!$feof(trace_file)) begin
            
            // Read 8 hex values from the current line
            scan_res = $fscanf(trace_file, "%x %x %x %x %x %x %x %x\n", 
                                exp_ieip, exp_oeip, exp_prefix, exp_opcode, 
                                exp_has_modrm, exp_modrm, exp_imm_size, exp_imm);
            
            // If we successfully read exactly 8 items, run the check
            if (scan_res == 8) begin
                instruction_count = instruction_count + 1;
                $display("--- Checking Instruction %0d ---", instruction_count);
                
                // Call your verify task with the variables we just read
                verify_instruction("Trace Inst", 
                                    exp_ieip, exp_oeip, 
                                    exp_prefix, exp_opcode, 
                                    exp_has_modrm, exp_modrm, 
                                    exp_imm_size, exp_imm);
            end
        end
        
        $fclose(trace_file);
        $display("=======================================");
        $display("TRACE COMPLETE: %0d Instructions Checked", instruction_count);
        $display("FAILURES = %0d | SUCCESSES = %0d", FAILURES, SUCCESSES);
        $display("=======================================");
    end
endtask

initial begin
    rst_n = 0;
    from_rr_cs = 16'h0200;
    from_rr_stall = 0;
    from_ex_ld_cs = 0;
    from_ex_eip_target_out = 32'h00000005;
    from_ex_flush = 0;
    from_ex_br_t_nt = 0;
    from_ex_br_valid = 0;
    from_ex_pht_idx = 0;
    from_wb_flush = 0;

    #(1.5 * CYCLE_TIME);
    rst_n = 1;

    #(CYCLE_TIME);

    from_ex_ld_cs = 1;
    #(CYCLE_TIME);
    from_ex_ld_cs = 0;
    #(CYCLE_TIME);

    run_automated_verification();  

    $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

    $finish;
end

/* D$ TEST CASE FROM WEBSITE */
initial begin
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
end


integer file_handle_icache;
integer file_dump;
integer clk_ctr_$;
integer k;
initial begin
  // Open the file for writing
  file_handle_icache = $fopen("icache.csv", "w");
  if (file_handle_icache == 0) begin
    $display("Error: Filed to open file for icache!");
  end
  clk_ctr_$ = 0;
end

always @(posedge (clk)) begin
  clk_ctr_$ = clk_ctr_$ + 1;
end


wire  [MEM_ADDR_WIDTH-1:0]  ICACHE_PHYS_ADDR_READ = {ITLB_PFN_OUT, F_PAGE_OFFSET};


integer ic_set, ic_way, ic_byte;
genvar ic_s;

genvar ic_gway, ic_gbyte;
genvar ic_gtagway;
genvar ic_vset, ic_vway;
genvar ic_lset;

generate

/* ---------------- ICACHE DATA STORE DUMP ---------------- */

for (ic_gway = 0; ic_gway < 4; ic_gway = ic_gway + 1) begin : IC_DATA_WAY
  for (ic_gbyte = 15; ic_gbyte >= 0; ic_gbyte = ic_gbyte - 1) begin : IC_DATA_BYTE

    always begin
      @(posedge ICACHE_VALID);
      @(posedge clk);

      if (ICACHE_VALID === 1'b1) begin
        if (ic_gway == 0 && ic_gbyte == 15) begin
          $fwrite(file_handle_icache, "////////////////////// NEW DATA, PHYS ADDR = %04x @ time = %0t //////////////////////\n", ICACHE_PHYS_ADDR_READ, $time);
          $fwrite(file_handle_icache, "/*** DATA STORE SET 0 ***/\n");
        end
        $fwrite(file_handle_icache,"%02x ",
          full_cache_inst.icache_data_store
            .data_store_generation[ic_gway]
            .data_position_generation[ic_gbyte]
            .ram8b8w$_data_store_one_bus
            .mem[0]
        );
        if (ic_gbyte == 0) begin
          $fwrite(file_handle_icache,"\n");
        end
      end
    end

  end
end

/* ---------------- ICACHE TAG STORE DUMP ---------------- */

for (ic_s = 0; ic_s < 8; ic_s = ic_s + 1) begin : IC_TAG_WAY

  always begin
    @(posedge ICACHE_VALID);
    @(posedge clk);

    if (ICACHE_VALID === 1'b1) begin
      if (ic_s == 0) begin
        $fwrite(file_handle_icache, "/*** TAG STORE ***/\n");
      end
        $fwrite(file_handle_icache,
          "%02x ",
          full_cache_inst.icache_tag_store
            .tag_store_generation[0]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x ",
          full_cache_inst.icache_tag_store
            .tag_store_generation[1]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x ",
          full_cache_inst.icache_tag_store
            .tag_store_generation[2]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
        $fwrite(file_handle_icache,
          "%02x\n",
          full_cache_inst.icache_tag_store
            .tag_store_generation[3]
            .ram8b8w$_tag_store_one_way
            .mem[ic_s]
        );
      end

  end

end

/* ---------------- ICACHE VALID STORE DUMP ---------------- */

for (ic_vset = 0; ic_vset < 8; ic_vset = ic_vset + 1) begin : IC_VSET
  for (ic_vway = 0; ic_vway < 4; ic_vway = ic_vway + 1) begin : IC_VWAY

    always begin
      @(posedge ICACHE_VALID);
      @(posedge clk);

      if (ICACHE_VALID === 1'b1) begin
        if (ic_vway == 0 && ic_vset == 0) begin
          $fwrite(file_handle_icache, "/*** VALID STORE ***/\n");
        end
        $fwrite(file_handle_icache,
          "%0d ",
          full_cache_inst.icache_valid_store
            .valid_per_set[ic_vset]
            .valid_per_way[ic_vway]
            .reg_n_stream_buffer_next_line_addr.q
        );
        if (ic_vway == 3) begin
          $fwrite(file_handle_icache, "\n");
        end
      end
    end

  end
end

/* ---------------- ICACHE LRU STORE DUMP ---------------- */

for (ic_lset = 0; ic_lset < 8; ic_lset = ic_lset + 1) begin : IC_LSET

  always begin
    @(posedge ICACHE_VALID);
    @(posedge clk);

    if (ICACHE_VALID === 1'b1) begin
      if (ic_lset == 0) begin
        $fwrite(file_handle_icache, "/*** LRU STORE ***/\n");
      end
      $fwrite(file_handle_icache,
        "%0d%0d\n",
        full_cache_inst.lru_store_ICACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[ic_lset]
          .lru_store_per_set_VICT_WAYS.D4,
        full_cache_inst.lru_store_ICACHE_VICT_WAY
          .LRU_STORE_TOUCH_VALIDS_GEN[ic_lset]
          .lru_store_per_set_VICT_WAYS.D3
      );
      if (ic_lset == 7) begin
        $fwrite(file_handle_icache, "\n");
      end
    end

  end

end

endgenerate

endmodule