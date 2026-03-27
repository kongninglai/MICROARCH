module stage_fetch #(
  parameter BUS_BIT_WIDTH=32,
  parameter RANK_BIT_WIDTH=128,
  parameter RANK_BURST_SIZE=RANK_BIT_WIDTH/BUS_BIT_WIDTH,
  
  parameter VA_BIT_WIDTH=32,
  parameter PA_BIT_WIDTH=15,
  parameter PAGE_SIZE_BYTES=4096,
  parameter PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES),
  parameter VPN_BIT_WIDTH=VA_BIT_WIDTH-PAGE_BIT_WIDTH,
  parameter PFN_BIT_WIDTH=MEM_ADDR_WIDTH-PAGE_BIT_WIDTH,

  parameter SEGR_DATA_BIT_WIDTH=16,

) (
  input                                       clk,
  input                                       rst_n,

  /*** TLB I/Os: Note the inout behavior for D_RD_TLB_PFN_OUT, D_RD_TLB_CACHE_ENABLE_OUT ***/
  output  [VPN_BIT_WIDTH-1:0]                 ITLB_VPN,
  inout   [PFN_BIT_WIDTH-1:0]                 ITLB_PFN_OUT, 
  input                                       ITLB_PAGE_FAULT_OUT,

  /*** Inputs from full_cache module ***/
  inout                                       ICACHE_VALID,
  inout   [RANK_BIT_WIDTH-1:0]                ICACHE_HIT_DATA,

  /*** Inputs from other stages ***/
  input                                       from_fetch_buffer_write_enable,
  input   [VA_BIT_WIDTH-1:0]                  from_de_bp_target_out,
  input                                       from_de_taken_predicted_branch,
  input   [SEGR_DATA_BIT_WIDTH-1:0]           from_rr_code_segment,
  input   [VA_BIT_WIDTH-1:0]                  from_ex_eip_target_out,
  input                                       from_ex_flush,
  input                                       from_wb_flush,

  /*** Outputs to full_cache module (load-related) ***/
  output  [PAGE_BIT_WIDTH-1:0]                F_PAGE_OFFSET
);

wire    [VA_BIT_WIDTH-1:RANK_BURST_SIZE]  FETCH_POINTER, INC_FETCH_POINTER, NEXT_FETCH_POINTER;
wire    LOAD_ENABLE_FETCH_POINTER, LOAD_ENABLE_FETCH_POINTER_buf64;

bufferH64$    bufferH64$_LOAD_ENABLE_FETCH_POINTER_buf64(LOAD_ENABLE_FETCH_POINTER_buf64, LOAD_ENABLE_FETCH_POINTER);

big_increment #(
  .WIDTH(VA_BIT_WIDTH-RANK_BURST_SIZE)
) big_increment_INC_FETCH_POINTER (
  .a(FETCH_POINTER),
  .s(INC_FETCH_POINTER)
);

reg_n #(
  .WIDTH(VA_BIT_WIDTH-RANK_BURST_SIZE),
  .USE_EN_BAR(0)
) reg_n_FETCH_POINTER (
  .clk(clk), .rst(rst),
  .en({(VA_BIT_WIDTH-RANK_BURST_SIZE){LOAD_ENABLE_FETCH_POINTER_buf64}}), 
  .d(NEXT_FETCH_POINTER),
  .q(FETCH_POINTER)
);

mux4_16$   mux4_16$_NEXT_FETCH_POINTER_TOP (
  NEXT_FETCH_POINTER[31:16],
  INC_FETCH_POINTER[31:16],
  from_de_bp_target_out[31:16],
  from_ex_eip_target_out[31:16],
  from_ex_eip_target_out[31:16],
  from_de_taken_predicted_branch,
  from_ex_flush
);

wire  [RANK_BURST_SIZE-1:0]   DUMMY_NEXT_FETCH_POINTER;

mux4_16$   mux4_16$_NEXT_FETCH_POINTER_BOT (
  {NEXT_FETCH_POINTER[15:4], DUMMY_NEXT_FETCH_POINTER},
  {INC_FETCH_POINTER[15:4], 4'd0},
  {from_de_bp_target_out[15:4], 4'd0},
  {from_ex_eip_target_out[15:4], 4'd0},
  {from_ex_eip_target_out[15:4], 4'd0},
  from_de_taken_predicted_branch,
  from_ex_flush
);

assign F_PAGE_OFFSET  = {FETCH_POINTER, {RANK_BURST_SIZE{1'b0}}};
assign ITLB_VPN       = FETCH_POINTER[VA_BIT_WIDTH-1:PAGE_BIT_WIDTH];

endmodule