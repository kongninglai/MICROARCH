module fetch_plus_buffer_tb;

initial begin
  // $vcdplusfile("fetch_plus_buffer_tb.dump.vpd");
  // $vcdpluson(0, fetch_plus_buffer_tb);
  // $vcdpluson(0, fetch_plus_buffer_tb.DUT);
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

wire [VPN_BIT_WIDTH-1:0] ITLB_VPN;
wire [PFN_BIT_WIDTH-1:0] ITLB_PFN_OUT;
wire ITLB_PAGE_FAULT_OUT;

wire from_fetch_buffer_write_enable;
reg [VA_BIT_WIDTH-1:0] from_de_bp_target_out;
reg from_de_taken_predicted_branch;
reg [SEGR_DATA_BIT_WIDTH-1:0] from_rr_code_segment;
reg [VA_BIT_WIDTH-1:0] from_ex_eip_target_out;
reg from_ex_flush;
reg from_wb_flush;

wire [PAGE_BIT_WIDTH-1:0] F_PAGE_OFFSET;

wire [PFN_BIT_WIDTH-1:0] KB_PFN;
wire [PFN_BIT_WIDTH-1:0] DMA_PFN;

wire [MEM_ADDR_WIDTH-1:0] ADDR_BUS;
wire [BUS_BIT_WIDTH-1:0] DATA_BUS;
wire [15:0] WR_mask;
wire [RANK_BIT_WIDTH-1:0] ICACHE_HIT_DATA;
wire ICACHE_VALID;

wire [2:0] ICACHE_SET = F_PAGE_OFFSET[6:4];

stage_fetch DUT (
  .clk(clk),
  .rst_n(rst_n),

  .ITLB_VPN(ITLB_VPN),
  .ITLB_PFN_OUT(ITLB_PFN_OUT),
  .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

  .ICACHE_VALID(ICACHE_VALID),
  .ICACHE_HIT_DATA(ICACHE_HIT_DATA),

  .from_fetch_buffer_write_enable(from_fetch_buffer_write_enable),
  .from_de_bp_target_out(from_de_bp_target_out),
  .from_de_taken_predicted_branch(from_de_taken_predicted_branch),
  .from_rr_code_segment(from_rr_code_segment),
  .from_ex_eip_target_out(from_ex_eip_target_out),
  .from_ex_flush(from_ex_flush),
  .from_wb_flush(from_wb_flush),

  .F_PAGE_OFFSET(F_PAGE_OFFSET)
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

wire [4:0] tail_ptr;
wire [3:0] from_de_instr_len;

assign from_de_valid_and_load_rr = (tail_ptr >= {1'b0, from_de_instr_len});

wire [127:0] to_de_outbytes;

reg [31:0] eip;

always @(posedge clk) begin
  if (rst_n === 1'b1 && from_ex_flush === 1'b1) begin
    eip <= from_ex_eip_target_out;
    // $display("JUMP at %t", $time);
  end else if (rst_n === 1'b1 && from_de_valid_and_load_rr === 1'b1) begin
    eip <= eip + from_de_instr_len;
  end
end

wire to_de_pf_expn;

fetch_buffer fetch_buffer_inst (
  .clk(clk),
  .rst_bar(rst_n),
  .from_de_instr_len(from_de_instr_len),
  .from_de_eip_lower_bits(eip[3:0]),
  .from_f_icache_valid(ICACHE_VALID),
  .from_de_valid_and_load_rr(from_de_valid_and_load_rr),
  .from_wb_flush(from_wb_flush),
  .from_ex_flush(from_ex_flush),
  .from_f_cl_pf(ITLB_PAGE_FAULT_OUT),
  .from_f_cache_line(ICACHE_HIT_DATA),
  .from_de_eip_redirection(1'b0),
  .to_de_outbytes(to_de_outbytes),
  .to_de_pf_expn(to_de_pf_expn),
  .tail_ptr(tail_ptr),
  .global_wr_en(from_fetch_buffer_write_enable)
);

block_decoder block_decoder_inst (
  .cache_line(to_de_outbytes),
  .prefix_rep(),
  .prefix_op_size(),
  .prefix_seg_ov_id(),
  .prefix_ext(),
  .opcode(),
  .modrm_v(),
  .modrm(),
  .sib(),
  .disp_size_mux(),
  .disp(),
  .imm_size(),
  .imm(),
  .addressing_mode(),
  .instr_length(from_de_instr_len)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

reg [VA_BIT_WIDTH-1:0]  EXPECTED_INST_ADDR;

always @(posedge clk) begin
  if (rst_n === 1'b0) begin
    EXPECTED_INST_ADDR = ({from_rr_code_segment, 16'd0} + 0);
  end else if (from_ex_flush === 1'b1) begin
    EXPECTED_INST_ADDR <= ({from_rr_code_segment, 16'd0} + from_ex_eip_target_out) & 32'hFFFFFFF0;
  end else if (from_de_taken_predicted_branch === 1'b1) begin
    EXPECTED_INST_ADDR <= ({from_rr_code_segment, 16'd0} + from_de_bp_target_out) & 32'hFFFFFFF0;
  end else if (from_fetch_buffer_write_enable === 1'b1) begin
    EXPECTED_INST_ADDR <= EXPECTED_INST_ADDR + 16;
  end

  if ({ITLB_VPN, F_PAGE_OFFSET} !== EXPECTED_INST_ADDR && from_fetch_buffer_write_enable !== 1'bX) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: EXPECTED_INST_ADDR exp=%h got=%h", $time, EXPECTED_INST_ADDR, {ITLB_VPN, F_PAGE_OFFSET});
  end else begin
    SUCCESSES = SUCCESSES + 1;
    // $display("SUCCESS AT TIME %t: EXPECTED_INST_ADDR exp=%h got=%h", $time, EXPECTED_INST_ADDR, {ITLB_VPN, F_PAGE_OFFSET});
  end

  // if (to_de_outbytes[7:0] === 8'hF4 && tail_ptr >= 5'd1) begin
  if (tail_ptr === 5'h16) begin /* Page fault test */
    @(posedge clk)
    from_ex_flush <= 1;
    from_rr_code_segment <= 16'h0202;
    #(CYCLE_TIME);
    from_ex_flush <= 0;
    #(10 * CYCLE_TIME);
    from_ex_flush <= 1;
    from_ex_eip_target_out <= 32'd0;
    #(CYCLE_TIME);
    from_rr_code_segment <= 16'h0000;
    from_ex_flush <= 0;
    #(50 * CYCLE_TIME);

  
    if (eip !== 32'h00000035) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t: EIP exp=%h got=%h", $time, 32'h00000035, eip);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end

    $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);
    $finish;
  end
end

initial begin
  rst_n = 0;
  from_de_bp_target_out = 32'h00000015;
  from_de_taken_predicted_branch = 0;
  from_rr_code_segment = 16'h0000;
  from_ex_eip_target_out = 32'h00000005;
  from_ex_flush = 0;
  from_wb_flush = 0;
  eip = 0;

  #(1.5 * CYCLE_TIME);
  rst_n = 1;

  #(CYCLE_TIME);

  #(300*CYCLE_TIME);
  

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

/* D$ TEST CASE FROM WEBSITE */
initial begin
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank0_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank1_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank2_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank3_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank4_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank5_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank6_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank7_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank8_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank9_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank10_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank11_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank12_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank13_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank14_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init_sample/mem_rank15_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
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