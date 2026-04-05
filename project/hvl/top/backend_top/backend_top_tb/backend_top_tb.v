module backend_top_tb;

initial begin
  // $vcdplusfile("backend_top_tb.dump.vpd");
  // $vcdpluson(0, backend_top_tb); 
end

integer i;
integer NUM_TESTS = 0;
integer FAILURES  = 0;
integer SUCCESSES = 0;

localparam CYCLE_TIME_X10 = 98;
localparam CYCLE_TIME = CYCLE_TIME_X10 / 10.0;
localparam TRUE_LRU = 1;

reg clk;
reg rst_n;
reg [6:0]  to_rr_prefix;
reg [7:0]  to_rr_opcode;
reg [7:0]  to_rr_modrm;
reg [7:0]  to_rr_sib;
reg [31:0] to_rr_disp;
reg [1:0]  to_rr_dispsize;
reg [47:0] to_rr_imm;
reg [2:0]  to_rr_imm_size;
reg [1:0]  to_rr_addr_mode;
reg [31:0] to_rr_oeip;
reg [31:0] to_rr_ieip;
reg [31:0] to_rr_pred_eip;
reg [1:0]  to_rr_exception;
reg        to_rr_valid;

/*** CACHE / TLB INTERNAL WIRES ***/
wire [11:0] MEM_PAGE_OFFSET;
wire        MEM_VALID_LOAD_INST;

wire [14:4] WB_PR_ST_ADDR_L0;
wire [15:0] WB_PR_ST_MASK_L0;
wire [127:0] WB_SHF_ST_DATA_L0;
wire        WB_VALID_IO_STORE_INST;

wire        STOREQ_STORING;
wire        STOREQ_LAST_ENTRY;
wire [127:0] STOREQ_DATA;
wire [15:0]  STOREQ_DATA_WR_MASK;
wire [14:4]  STOREQ_PHYS_ADDR;

wire [19:0] D_RD_TLB_VPN;
wire [2:0]  D_RD_TLB_PFN_OUT;
wire        D_RD_TLB_CACHE_ENABLE_OUT;
wire        D_RD_TLB_PAGE_FAULT_OUT;

wire [19:0] D_WR0_TLB_VPN;
wire [2:0]  D_WR0_TLB_PFN_OUT;
wire        D_WR0_TLB_WRITE_DISABLE_OUT;
wire        D_WR0_TLB_CACHE_ENABLE_OUT;
wire        D_WR0_TLB_PAGE_FAULT_OUT;

wire [19:0] D_WR1_TLB_VPN;
wire [2:0]  D_WR1_TLB_PFN_OUT;
wire        D_WR1_TLB_WRITE_DISABLE_OUT;
wire        D_WR1_TLB_CACHE_ENABLE_OUT;
wire        D_WR1_TLB_PAGE_FAULT_OUT;

/*** CACHE INTERFACES ***/
wire [127:0] DCACHE_HIT_DATA;
wire         DCACHE_HIT;
wire         DCACHE_STALL;
wire         WBE_BUSY;
wire         DMA_INT;

/*** FULL CACHE BUS WIRES (TB SIDE) ***/
wire [31:0] DATA_BUS;
wire [14:0]  ADDR_BUS;
wire [15:0]  WR_mask;

wire [2:0] KB_PFN;
wire [2:0] DMA_PFN;

/*** OUTPUTS FROM DUT ***/
wire from_rr_stall;
wire [31:0] from_regunit_cs_limit;
wire from_ex_flush;
wire from_ex_br_t_nt;
wire from_ex_br_valid;
wire [31:0] from_ex_eip_target;
wire from_wb_flush;

/*** DUT ***/
backend_top dut (
  .clk(clk),
  .rst_n(rst_n),

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
  .to_rr_exception(to_rr_exception),
  .to_rr_valid(to_rr_valid),

  .from_rr_stall(from_rr_stall),
  .from_regunit_cs_limit(from_regunit_cs_limit),
  .from_ex_flush(from_ex_flush),
  .from_ex_br_t_nt(from_ex_br_t_nt),
  .from_ex_br_valid(from_ex_br_valid),
  .from_ex_eip_target(from_ex_eip_target),
  .from_wb_flush(from_wb_flush),

  /*** CACHE INTERFACE ***/
  .DCACHE_STALL(DCACHE_STALL),
  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .WBE_BUSY(WBE_BUSY),
  .DMA_INT(DMA_INT),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  /*** TLB INTERFACE ***/
  .D_RD_TLB_VPN(D_RD_TLB_VPN),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

  .D_WR0_TLB_VPN(D_WR0_TLB_VPN),
  .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
  .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
  .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
  .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

  .D_WR1_TLB_VPN(D_WR1_TLB_VPN),
  .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
  .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
  .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
  .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT)
);

full_cache #(
  .CYCLE_TIME_X10    (CYCLE_TIME_X10),
  .TRUE_LRU          (TRUE_LRU)
) full_cache_inst (
  .rst(rst_n),
  .clk(clk),

  .KB_PFN(KB_PFN),
  .DMA_PFN(DMA_PFN),

  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS),
  .WR_mask(WR_mask),

  .STOREQ_STORING(STOREQ_STORING),
  .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
  .STOREQ_DATA(STOREQ_DATA),
  .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
  .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

  .ITLB_PFN_OUT(3'd0),
  .ITLB_PAGE_FAULT_OUT(1'b0),

  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),

  .F_PAGE_OFFSET(12'd0),
  .ICACHE_HIT_DATA(),
  .ICACHE_VALID(),

  .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
  .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

  .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
  .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
  .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
  .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

  .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
  .DCACHE_HIT(DCACHE_HIT),
  .DCACHE_STALL(DCACHE_STALL),
  .WBE_BUSY(WBE_BUSY),

  .DMA_INT(DMA_INT),

  .TEST_CASE_NEW_CHAR(8'd0),
  .TEST_CASE_NEW_CHAR_WR(8'd0),
  .TEST_CASE_NEW_READY(1'b0),
  .TEST_CASE_NEW_READY_WR(1'b0),

  .WB_FLUSH(from_wb_flush),
  .EX_FLUSH(from_ex_flush)
);

tlb_wrapper tlb_inst (
  .ITLB_VPN(),
  .ITLB_PFN_OUT(),
  .ITLB_WRITE_DISABLE_OUT(),
  .ITLB_CACHE_ENABLE_OUT(),
  .ITLB_PAGE_FAULT_OUT(),

  .D_RD_TLB_VPN(D_RD_TLB_VPN),
  .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .D_RD_TLB_WRITE_DISABLE_OUT(),
  .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

  .D_WR0_TLB_VPN(D_WR0_TLB_VPN),
  .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
  .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
  .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
  .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

  .D_WR1_TLB_VPN(D_WR1_TLB_VPN),
  .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
  .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
  .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
  .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT),

  .DMA_PFN(DMA_PFN),
  .KB_PFN(KB_PFN)
);

always #(CYCLE_TIME / 2.0) clk = ~clk;

task clear_inputs;
begin
  to_rr_prefix = 7'd0;
  to_rr_opcode = 8'd0;
  to_rr_modrm = 8'd0;
  to_rr_sib = 8'd0;
  to_rr_disp = 32'd0;
  to_rr_dispsize = 2'd0;
  to_rr_imm = 48'd0;
  to_rr_imm_size = 3'd0;
  to_rr_addr_mode = 2'd0;
  to_rr_oeip = 32'd0;
  to_rr_ieip = 32'd0;
  to_rr_pred_eip = 32'd0;
  to_rr_exception = 2'd0;
  to_rr_valid = 1'b0;
end
endtask

task apply_inputs;
  input [6:0] prefix;
  input [7:0] opcode;
  input [7:0] modrm;
  input [7:0] sib;
  input [31:0] disp;
  input [1:0] dispsize;
  input [47:0] imm;
  input [2:0] imm_size;
  input [1:0] addr_mode;
  input [31:0] oeip;
  input [31:0] ieip;
  input [31:0] pred_eip;
  input [1:0] exception;
  input valid;
begin 
  to_rr_prefix      = prefix;          
  to_rr_opcode      = opcode;    
  to_rr_modrm       = modrm;     
  to_rr_sib         = sib;       
  to_rr_disp        = disp;      
  to_rr_dispsize    = dispsize;  
  to_rr_imm         = imm;       
  to_rr_imm_size    = imm_size;  
  to_rr_addr_mode   = addr_mode; 
  to_rr_oeip        = oeip;      
  to_rr_ieip        = ieip;  
  to_rr_pred_eip    = pred_eip;
  to_rr_exception   = exception;    
  to_rr_valid       = valid;     
end
endtask

task print_arch_status;
begin 
  $display("======================================");
  $display("General Purpose RegFile");
  $display("======================================");
  for(i = 0; i < 8; i = i + 1) begin
      $display("reg[%0d] = %h", i, dut.inst_regunit.gprf.q[i]);
  end

  $display("======================================");
  $display("Segment RegFile");
  $display("======================================");
  for(i = 0; i < 8; i = i + 1) begin
      if(i==1) begin 
          $display("reg[%0d](CS) = %h", i, dut.inst_regunit.segrf.cs_q);
      end else begin 
          $display("reg[%0d] = %h", i, dut.inst_regunit.segrf.seg_rf.q[i]);
      end
  end

  $display("======================================");
  $display("MMX RegFile");
  $display("======================================");
  for(i = 0; i < 8; i = i + 1) begin
      $display("reg[%0d] = %h", i, dut.inst_regunit.mmxrf.mmx_regs.q[i]);
  end
  $display("\n");

  $display("eflags=%08h", dut.inst_stage_ex.eflags_out);
  $display("\n");
end
endtask

task insert_nop; 
  apply_inputs(7'b0000110, 8'h01, 8'hc0, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'h0, 2'b0, 1'b0);
endtask

task test_with_nops;
  input [6:0] prefix;
  input [7:0] opcode;
  input [7:0] modrm;
  input [7:0] sib;
  input [31:0] disp;
  input [1:0] dispsize;
  input [47:0] imm;
  input [2:0] imm_size;
  input [1:0] addr_mode;
  input [31:0] oeip;
  input [31:0] ieip;
  input [31:0] pred_eip;
  input [1:0] exception;
  input valid;
begin 
  @(posedge clk);
  apply_inputs(prefix, opcode, modrm, sib, disp, dispsize, imm, imm_size, addr_mode, oeip, ieip, pred_eip, exception, valid);
  @(posedge clk); // updated rr_to_ag
  insert_nop();
  @(posedge clk); // updated ag_to_mem
  insert_nop();
  @(posedge clk); // updated mem_to_ex
  insert_nop();
  @(posedge clk); // updated ex_to_wb
  insert_nop();
  @(posedge clk); // updated register files
  insert_nop();
  repeat (30) begin
    @(posedge clk);
    insert_nop();
  end
  print_arch_status();
  $display("\n");
  NUM_TESTS = NUM_TESTS + 1;
end
endtask

initial begin 
  clk = 1'b0;
  rst_n = 1'b0;
  clear_inputs();
  @(posedge clk);
  @(posedge clk);
  rst_n = 1'b1;
  
  print_arch_status();

  $display("======================================");
  $display("[ALU] TEST CASE%0d: ADD BH, 0x8", NUM_TESTS);
  $display("======================================");
  // 80 c7 08
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'h80, 8'hc7, 8'bx, 32'bx, 2'b00,
                  48'h8, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

  $display("======================================");
  $display("[ALU] TEST CASE%0d: ADD EAX, 0x12345678", NUM_TESTS);
  $display("======================================");
  // 05 78 56 34 12
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'h05, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'h12345678, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[ALU] TEST CASE%0d: ADD AX, BX", NUM_TESTS);
  $display("======================================");
  // 66 01 D8
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0010110, 8'h01, 8'hD8, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);


  $display("======================================");
  $display("[CMPXCHG] TEST CASE%0d: MOV EAX, 0x5", NUM_TESTS);
  $display("======================================");
  // b8 05 00 00 00
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'hb8, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'h5, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[CMPXCHG] TEST CASE%0d: MOV EBX, 0x5", NUM_TESTS);
  $display("======================================");
  // bb 05 00 00 00
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'hbb, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'h5, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

  $display("======================================");
  $display("[CMPXCHG] TEST CASE%0d: MOV ECX, 0x9", NUM_TESTS);
  $display("======================================");
  // b9 09 00 00 00
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'hb9, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'h9, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

  $display("======================================");
  $display("[CMPXCHG] TEST CASE%0d: CMPXCHG EBX, ECX", NUM_TESTS);
  $display("======================================");
  // 0f b1 cb
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000111, 8'hb1, 8'hcb, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[CMPXCHG] TEST CASE%0d: CMPXCHG EBX, ECX", NUM_TESTS);
  $display("======================================");
  // 0f b1 cb
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000111, 8'hb1, 8'hcb, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[MMX] TEST CASE%0d: MOVQ MM0, [EBX]", NUM_TESTS);
  $display("======================================");
  // 0f 6f 03
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000111, 8'h6f, 8'h03, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[MMX] TEST CASE%0d: PAVGB MM2, MM0", NUM_TESTS);
  $display("======================================");
  // 0f e0 d0
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000111, 8'he0, 8'hd0, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
  
  $display("======================================");
  $display("[STACK] TEST CASE%0d: MOV ESP 0x1234", NUM_TESTS);
  $display("======================================");
  // bc 34 12 00 00
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'hbc, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'h1234, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

  $display("======================================");
  $display("[STACK] TEST CASE%0d: POP DS", NUM_TESTS);
  $display("======================================");
  // 1f
  // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
  // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
  test_with_nops(7'b0000110, 8'h1f, 8'bx, 8'bx, 32'bx, 2'b00,
                  48'bx, 3'b000, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

                  
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

// Auto-generated memory initialization (Verilog-2005)

initial begin
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank0_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[0].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank1_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[1].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank2_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[2].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank3_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[3].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank4_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[4].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank5_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[5].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank6_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[6].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank7_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[7].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank8_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[8].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank9_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[9].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank10_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[10].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank11_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[11].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank12_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[12].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank13_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[13].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank14_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[14].rank_inst.chip_generation[15].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip0.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[0].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip1.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[1].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip2.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[2].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip3.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[3].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip4.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[4].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip5.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[5].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip6.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[6].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip7.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[7].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip8.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[8].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip9.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[9].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip10.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[10].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip11.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[11].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip12.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[12].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip13.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[13].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip14.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[14].sram128x8$_inst.mem);
  $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/mem_init/mem_rank15_chip15.hex", full_cache_inst.full_cc_off_core_inst.off_core_top_inst.mcu_inst.main_memory_inst.rank_generation[15].rank_inst.chip_generation[15].sram128x8$_inst.mem);
end


endmodule