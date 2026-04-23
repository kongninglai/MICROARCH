module pipeline_top(
    input wire clk,
    input wire rst_bar
);

localparam CYCLE_TIME_X10 = 100;
localparam TRUE_LRU       = 1;

//decode wires
wire [6:0] to_rr_prefix;
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
wire to_rr_pred_dir;
wire [3:0] to_rr_pht_idx;
wire [31:0] to_pr_pred_eip;
wire [1:0] to_rr_exception;
wire to_rr_valid;
wire [95:0] to_rr_ucode_sigs;
//TLB wires
wire [19:0] ITLB_VPN; //stage fetch a
wire [2:0]  ITLB_PFN_OUT;
wire ITLB_PAGE_FAULT_OUT;

//Cache wires
wire ICACHE_VALID;
wire [127:0] ICACHE_HIT_DATA;
wire [11:0] F_PAGE_OFFSET; //stage fetch a

wire [15:0] from_regunit_CS;
wire [31:0] from_regunit_cs_limit;
wire from_rr_stall;
wire from_ex_ld_cs;
wire [31:0] from_ex_eip_target;
wire from_ex_flush;
wire from_ex_br_t_nt;
wire from_ex_br_valid;
wire [3:0] from_ex_pht_idx;
wire from_wb_flush;

// frontend controls that are not currently surfaced by backend_top
assign from_ex_ld_cs   = 1'b0;

fetch_decode_top FRONTEND_TOP (
    //inputs
    .clk(clk),
    .rst_bar(rst_bar),

    .ITLB_VPN(ITLB_VPN), //output
    .ITLB_PFN_OUT(ITLB_PFN_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),
    
    .ICACHE_VALID(ICACHE_VALID),
    .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
    .F_PAGE_OFFSET(F_PAGE_OFFSET), //output

    .from_rr_cs(from_regunit_CS),
    .from_rr_stall(from_rr_stall),
    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_eip_target(from_ex_eip_target),
    .from_ex_flush(from_ex_flush),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_pht_idx(from_ex_pht_idx),
    .from_wb_flush(from_wb_flush),

    //outputs
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
    .to_rr_pred_dir(to_rr_pred_dir),
    .to_rr_pht_idx(to_rr_pht_idx),
    .to_pr_pred_eip(to_pr_pred_eip),
    .to_rr_exception(to_rr_exception),
    .to_rr_ucode_sigs(to_rr_ucode_sigs),
    .to_rr_valid(to_rr_valid)
);


wire [19:0] D_RD_TLB_VPN;
wire [2:0]  D_RD_TLB_PFN_OUT;
wire        D_RD_TLB_WRITE_DISABLE_OUT;
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

wire        ITLB_WRITE_DISABLE_OUT;
wire        ITLB_CACHE_ENABLE_OUT;

wire [2:0]  KB_PFN;
wire [2:0]  DMA_PFN;

wire [31:0]  DATA_BUS;
wire [14:0]  ADDR_BUS;
wire [15:0]  WR_mask;

wire [11:0] MEM_PAGE_OFFSET;
wire        MEM_VALID_LOAD_INST;

wire [14:4]  WB_PR_ST_ADDR_L0;
wire [15:0]  WB_PR_ST_MASK_L0;
wire [127:0] WB_SHF_ST_DATA_L0;
wire         WB_VALID_IO_STORE_INST;

wire         STOREQ_STORING;
wire         STOREQ_LAST_ENTRY;
wire [127:0] STOREQ_DATA;
wire [15:0]  STOREQ_DATA_WR_MASK;
wire [14:4]  STOREQ_PHYS_ADDR;

wire [127:0] DCACHE_HIT_DATA;
wire         DCACHE_HIT;
wire         DCACHE_STALL;
wire         WBE_BUSY;
wire         DMA_INT;

wire         DCACHE_STALL_UNCOND_BAR;
wire         DCACHE_STALL_IF_MEM_BAR;

tlb_wrapper tlb_inst (
    .ITLB_VPN(ITLB_VPN), //input from frontend

    //output
    .ITLB_PFN_OUT(ITLB_PFN_OUT), 
    .ITLB_WRITE_DISABLE_OUT(ITLB_WRITE_DISABLE_OUT),
    .ITLB_CACHE_ENABLE_OUT(ITLB_CACHE_ENABLE_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

    .D_RD_TLB_VPN(D_RD_TLB_VPN),//input

    //output
    .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
    .D_RD_TLB_WRITE_DISABLE_OUT(D_RD_TLB_WRITE_DISABLE_OUT),
    .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
    .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),


    .D_WR0_TLB_VPN(D_WR0_TLB_VPN), //input

    //output
    .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
    .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
    .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
    .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

    .D_WR1_TLB_VPN(D_WR1_TLB_VPN), //input

    //output
    .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
    .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
    .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
    .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT),

    .DMA_PFN(DMA_PFN),
    .KB_PFN(KB_PFN)
);


full_cache #(
    .CYCLE_TIME_X10    (CYCLE_TIME_X10),
    .TRUE_LRU          (TRUE_LRU)
) full_cache_inst (
    .rst(rst_bar),
    .clk(clk),

    //inputs
    .KB_PFN(KB_PFN),
    .DMA_PFN(DMA_PFN),

    //bus inout
    .DATA_BUS(DATA_BUS),
    .ADDR_BUS(ADDR_BUS),
    .WR_mask(WR_mask),

    //inputs for store queue and cache (for writes)
    .STOREQ_STORING(STOREQ_STORING),
    .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
    .STOREQ_DATA(STOREQ_DATA),
    .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
    .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

    //inputs for tlb and cache (for reads)
    .ITLB_PFN_OUT(ITLB_PFN_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

    //i/o between pr and cache
    .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT), //input
    .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT), //input

    .F_PAGE_OFFSET(F_PAGE_OFFSET), //output
    .ICACHE_HIT_DATA(ICACHE_HIT_DATA), //output
    .ICACHE_VALID(ICACHE_VALID), //output

    .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET), //input
    .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST), //input

    .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),//input
    .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),//input
    .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),//input
    .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),//input

    //output
    .DCACHE_HIT_DATA(DCACHE_HIT_DATA), 
    .DCACHE_HIT(DCACHE_HIT),
    .DCACHE_STALL(DCACHE_STALL),
    .WBE_BUSY(WBE_BUSY),
    .DCACHE_STALL_UNCOND_BAR(DCACHE_STALL_UNCOND_BAR),
    .DCACHE_STALL_IF_MEM_BAR(DCACHE_STALL_IF_MEM_BAR),

    .DMA_INT(DMA_INT),

    //input
    .TEST_CASE_NEW_CHAR(8'd0),
    .TEST_CASE_NEW_CHAR_WR(8'd0),
    .TEST_CASE_NEW_READY(1'b0),
    .TEST_CASE_NEW_READY_WR(1'b0),

    .WB_FLUSH(from_wb_flush),
    .EX_FLUSH(from_ex_flush)
);


backend_top #(
    .CYCLE_TIME_X10(CYCLE_TIME_X10),
    .TRUE_LRU(TRUE_LRU)
) BACKEND_TOP (

    //inputs
    .clk(clk),
    .rst_n(rst_bar),
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
    .to_rr_pred_dir(to_rr_pred_dir),
    .to_rr_pht_idx(to_rr_pht_idx),
    .to_rr_exception(to_rr_exception),
    .to_rr_ucode_sigs(to_rr_ucode_sigs),
    .to_rr_valid(to_rr_valid),

    //outputs to frontend
    .from_rr_stall(from_rr_stall),
    .from_regunit_CS(from_regunit_CS),
    .from_regunit_cs_limit(from_regunit_cs_limit),
    .from_ex_flush(from_ex_flush),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_eip_target(from_ex_eip_target),
    .from_ex_pht_idx(from_ex_pht_idx),
    .from_wb_flush(from_wb_flush),

    //inputs for D$
    .DCACHE_STALL(DCACHE_STALL),
    .DCACHE_HIT_DATA(DCACHE_HIT_DATA),
    .DCACHE_HIT(DCACHE_HIT),
    .WBE_BUSY(WBE_BUSY),
    .DCACHE_STALL_UNCOND_BAR(DCACHE_STALL_UNCOND_BAR),
    .DCACHE_STALL_IF_MEM_BAR(DCACHE_STALL_IF_MEM_BAR),

    //input for dma interrupt
    .DMA_INT(DMA_INT),

    //outputs to D$
    .MEM_PAGE_OFFSET(MEM_PAGE_OFFSET),
    .MEM_VALID_LOAD_INST(MEM_VALID_LOAD_INST),

    //outputs for i/o
    .WB_PR_ST_ADDR_L0(WB_PR_ST_ADDR_L0),
    .WB_PR_ST_MASK_L0(WB_PR_ST_MASK_L0),
    .WB_SHF_ST_DATA_L0(WB_SHF_ST_DATA_L0),
    .WB_VALID_IO_STORE_INST(WB_VALID_IO_STORE_INST),

    //output to D$
    .STOREQ_STORING(STOREQ_STORING),
    .STOREQ_LAST_ENTRY(STOREQ_LAST_ENTRY),
    .STOREQ_DATA(STOREQ_DATA),
    .STOREQ_DATA_WR_MASK(STOREQ_DATA_WR_MASK),
    .STOREQ_PHYS_ADDR(STOREQ_PHYS_ADDR),

    //i/o for TLB
    .D_RD_TLB_VPN(D_RD_TLB_VPN), //output
    .D_RD_TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
    .D_RD_TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
    .D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT),

    //i/o for TLB
    .D_WR0_TLB_VPN(D_WR0_TLB_VPN), //output
    .D_WR0_TLB_PFN_OUT(D_WR0_TLB_PFN_OUT),
    .D_WR0_TLB_WRITE_DISABLE_OUT(D_WR0_TLB_WRITE_DISABLE_OUT),
    .D_WR0_TLB_CACHE_ENABLE_OUT(D_WR0_TLB_CACHE_ENABLE_OUT),
    .D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT),

    .D_WR1_TLB_VPN(D_WR1_TLB_VPN),//output
    .D_WR1_TLB_PFN_OUT(D_WR1_TLB_PFN_OUT),
    .D_WR1_TLB_WRITE_DISABLE_OUT(D_WR1_TLB_WRITE_DISABLE_OUT),
    .D_WR1_TLB_CACHE_ENABLE_OUT(D_WR1_TLB_CACHE_ENABLE_OUT),
    .D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT)
);

endmodule