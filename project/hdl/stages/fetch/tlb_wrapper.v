module tlb_wrapper #(
  parameter VA_BIT_WIDTH=32,
  parameter PA_BIT_WIDTH=15,
  parameter PAGE_SIZE_BYTES=4096,
  parameter PAGE_BIT_WIDTH=$clog2(PAGE_SIZE_BYTES),
  parameter VPN_BIT_WIDTH=VA_BIT_WIDTH-PAGE_BIT_WIDTH,
  parameter PFN_BIT_WIDTH=PA_BIT_WIDTH-PAGE_BIT_WIDTH,
  parameter VALID_BIT_POS=3,
  parameter PRESENT_BIT_POS=2,
  parameter PAGE_LEVEL_WRITE_DISABLE_BIT_POS=1,
  parameter PAGE_LEVEL_CACHE_ENABLE_BIT_POS=0,
  parameter METADATA_BIT_WIDTH=VALID_BIT_POS+1,
  parameter TLB_OUT_BIT_WIDTH=PFN_BIT_WIDTH+METADATA_BIT_WIDTH,
  parameter TLB_ENTRY_BIT_WIDTH=VPN_BIT_WIDTH+PFN_BIT_WIDTH+METADATA_BIT_WIDTH,
  parameter NUM_TLB_ENTRIES=8
) (
  input       [VPN_BIT_WIDTH-1:0]                           ITLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           ITLB_PFN_OUT, 
  output                                                    ITLB_WRITE_DISABLE_OUT, 
                                                            ITLB_CACHE_ENABLE_OUT, 
                                                            ITLB_PAGE_FAULT_OUT,


  input       [VPN_BIT_WIDTH-1:0]                           D_RD_TLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           D_RD_TLB_PFN_OUT, 
  output                                                    D_RD_TLB_WRITE_DISABLE_OUT, 
                                                            D_RD_TLB_CACHE_ENABLE_OUT, 
                                                            D_RD_TLB_PAGE_FAULT_OUT,

                                                            
  input       [VPN_BIT_WIDTH-1:0]                           D_WR_TLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           D_WR_TLB_PFN_OUT, 
  output                                                    D_WR_TLB_WRITE_DISABLE_OUT, 
                                                            D_WR_TLB_CACHE_ENABLE_OUT, 
                                                            D_WR_TLB_PAGE_FAULT_OUT
);

tlb itlb (
  .TLB_VPN(ITLB_VPN),
  .TLB_PFN_OUT(ITLB_PFN_OUT),
  .TLB_WRITE_DISABLE_OUT(ITLB_WRITE_DISABLE_OUT),
  .TLB_CACHE_ENABLE_OUT(ITLB_CACHE_ENABLE_OUT),
  .TLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT)
);

tlb drdtlb (
  .TLB_VPN(D_RD_TLB_VPN),
  .TLB_PFN_OUT(D_RD_TLB_PFN_OUT),
  .TLB_WRITE_DISABLE_OUT(D_RD_TLB_WRITE_DISABLE_OUT),
  .TLB_CACHE_ENABLE_OUT(D_RD_TLB_CACHE_ENABLE_OUT),
  .TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT)
);

tlb dwrtlb (
  .TLB_VPN(D_WR_TLB_VPN),
  .TLB_PFN_OUT(D_WR_TLB_PFN_OUT),
  .TLB_WRITE_DISABLE_OUT(D_WR_TLB_WRITE_DISABLE_OUT),
  .TLB_CACHE_ENABLE_OUT(D_WR_TLB_CACHE_ENABLE_OUT),
  .TLB_PAGE_FAULT_OUT(D_WR_TLB_PAGE_FAULT_OUT)
);

endmodule