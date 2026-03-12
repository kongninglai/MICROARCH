// PFN is ready at 2 ns as of 03/09/2026. -VR

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

                                                            
  input       [VPN_BIT_WIDTH-1:0]                           D_WR0_TLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           D_WR0_TLB_PFN_OUT, 
  output                                                    D_WR0_TLB_WRITE_DISABLE_OUT, 
                                                            D_WR0_TLB_CACHE_ENABLE_OUT, 
                                                            D_WR0_TLB_PAGE_FAULT_OUT,

                                                            
  input       [VPN_BIT_WIDTH-1:0]                           D_WR1_TLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           D_WR1_TLB_PFN_OUT, 
  output                                                    D_WR1_TLB_WRITE_DISABLE_OUT, 
                                                            D_WR1_TLB_CACHE_ENABLE_OUT, 
                                                            D_WR1_TLB_PAGE_FAULT_OUT,

  output      [PFN_BIT_WIDTH-1:0]                           KB_PFN,
                                                            DMA_PFN
);

reg [TLB_ENTRY_BIT_WIDTH-1:0]   TLB_ENTRIES_BEHAV_prebuf[0:NUM_TLB_ENTRIES-1];
wire [TLB_ENTRY_BIT_WIDTH-1:0]  TLB_ENTRIES_BEHAV_INV[0:NUM_TLB_ENTRIES-1];

initial begin
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/fetch/tlb_init.txt", TLB_ENTRIES_BEHAV_prebuf);
end

wire  [TLB_ENTRY_BIT_WIDTH-1:0] TLB_ENTRIES_BEHAV[0:NUM_TLB_ENTRIES-1];
genvar h;
generate
  for (h = 0; h < NUM_TLB_ENTRIES; h = h + 1) begin : TLB_ENTRIES_BEHAV_INV_GEN
    bufferH16$    bufferH16$_TLB_ENTRIES_BEHAV[TLB_ENTRY_BIT_WIDTH-1:0](TLB_ENTRIES_BEHAV[h], TLB_ENTRIES_BEHAV_prebuf[h]);
    inv1$         inv1$_TLB_ENTRIES_BEHAV_INV[TLB_ENTRY_BIT_WIDTH-1:0](TLB_ENTRIES_BEHAV_INV[h], TLB_ENTRIES_BEHAV[h]);
  end
endgenerate

wire  [PFN_BIT_WIDTH-1:0] DMA_PFN_prebuf, KB_PFN_prebuf;

assign DMA_PFN_prebuf = TLB_ENTRIES_BEHAV[6][TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign KB_PFN_prebuf = TLB_ENTRIES_BEHAV[7][TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];

bufferH1024$  bufferH1024$_DMA_PFN[PFN_BIT_WIDTH-1:0](DMA_PFN, DMA_PFN_prebuf);
bufferH1024$  bufferH1024$_KB_PFN[PFN_BIT_WIDTH-1:0](KB_PFN, KB_PFN_prebuf);

/* One-hot encoding of which entry has a HIT */

wire [NUM_TLB_ENTRIES-1:0]  ITLB_ENTRY_SEL;
wire [NUM_TLB_ENTRIES-1:0]  D_RD_TLB_ENTRY_SEL;
wire [NUM_TLB_ENTRIES-1:0]  D_WR0_TLB_ENTRY_SEL;
wire [NUM_TLB_ENTRIES-1:0]  D_WR1_TLB_ENTRY_SEL;

genvar i;
generate
  for (i = 0; i < NUM_TLB_ENTRIES; i = i + 1) begin : VPN_COMPARE_GEN

    big_eq #(
      .WIDTH(VPN_BIT_WIDTH)
    ) big_eq_ITLB_ENTRY_SEL (
      .in0(TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH]), 
      .in1(ITLB_VPN),
      .eq(ITLB_ENTRY_SEL[i])
    );

    big_eq #(
      .WIDTH(VPN_BIT_WIDTH)
    ) big_eq_D_RD_TLB_ENTRY_SEL (
      .in0(TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH]), 
      .in1(D_RD_TLB_VPN),
      .eq(D_RD_TLB_ENTRY_SEL[i])
    );

    big_eq #(
      .WIDTH(VPN_BIT_WIDTH)
    ) big_eq_D_WR0_TLB_ENTRY_SEL (
      .in0(TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH]), 
      .in1(D_WR0_TLB_VPN),
      .eq(D_WR0_TLB_ENTRY_SEL[i])
    );

    big_eq #(
      .WIDTH(VPN_BIT_WIDTH)
    ) big_eq_D_WR1_TLB_ENTRY_SEL (
      .in0(TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH]), 
      .in1(D_WR1_TLB_VPN),
      .eq(D_WR1_TLB_ENTRY_SEL[i])
    );

  end
endgenerate

/* One-hot mux */

wire [NUM_TLB_ENTRIES-1:0] ITLB_ENTRY_SEL_buf16, ITLB_ENTRY_SEL_buf16_inv;
wire [NUM_TLB_ENTRIES-1:0] D_RD_TLB_ENTRY_SEL_buf16, D_RD_TLB_ENTRY_SEL_buf16_inv;
wire [NUM_TLB_ENTRIES-1:0] D_WR0_TLB_ENTRY_SEL_buf16, D_WR0_TLB_ENTRY_SEL_buf16_inv;
wire [NUM_TLB_ENTRIES-1:0] D_WR1_TLB_ENTRY_SEL_buf16, D_WR1_TLB_ENTRY_SEL_buf16_inv;

bufferH16$        bufferH16$_ITLB_ENTRY_SEL_buf16[NUM_TLB_ENTRIES-1:0](ITLB_ENTRY_SEL_buf16, ITLB_ENTRY_SEL);
bufferHInv16$     bufferHInv16$_ITLB_ENTRY_SEL_buf16_inv[NUM_TLB_ENTRIES-1:0](ITLB_ENTRY_SEL_buf16_inv, ITLB_ENTRY_SEL);

bufferH16$        bufferH16$_D_RD_TLB_ENTRY_SEL_buf16[NUM_TLB_ENTRIES-1:0](D_RD_TLB_ENTRY_SEL_buf16, D_RD_TLB_ENTRY_SEL);
bufferHInv16$     bufferHInv16$_D_RD_TLB_ENTRY_SEL_buf16_inv[NUM_TLB_ENTRIES-1:0](D_RD_TLB_ENTRY_SEL_buf16_inv, D_RD_TLB_ENTRY_SEL);

bufferH16$        bufferH16$_D_WR0_TLB_ENTRY_SEL_buf16[NUM_TLB_ENTRIES-1:0](D_WR0_TLB_ENTRY_SEL_buf16, D_WR0_TLB_ENTRY_SEL);
bufferHInv16$     bufferHInv16$_D_WR0_TLB_ENTRY_SEL_buf16_inv[NUM_TLB_ENTRIES-1:0](D_WR0_TLB_ENTRY_SEL_buf16_inv, D_WR0_TLB_ENTRY_SEL);

bufferH16$        bufferH16$_D_WR1_TLB_ENTRY_SEL_buf16[NUM_TLB_ENTRIES-1:0](D_WR1_TLB_ENTRY_SEL_buf16, D_WR1_TLB_ENTRY_SEL);
bufferHInv16$     bufferHInv16$_D_WR1_TLB_ENTRY_SEL_buf16_inv[NUM_TLB_ENTRIES-1:0](D_WR1_TLB_ENTRY_SEL_buf16_inv, D_WR1_TLB_ENTRY_SEL);

wire [TLB_OUT_BIT_WIDTH-1:0]  ITLB_OUT_GATED[0:NUM_TLB_ENTRIES-1];
wire [TLB_OUT_BIT_WIDTH-1:0]  D_RD_TLB_OUT_GATED[0:NUM_TLB_ENTRIES-1];
wire [TLB_OUT_BIT_WIDTH-1:0]  D_WR0_TLB_OUT_GATED[0:NUM_TLB_ENTRIES-1];
wire [TLB_OUT_BIT_WIDTH-1:0]  D_WR1_TLB_OUT_GATED[0:NUM_TLB_ENTRIES-1];

wire [TLB_OUT_BIT_WIDTH-1:0]  ITLB_OUT_COMBINED;
wire [TLB_OUT_BIT_WIDTH-1:0]  D_RD_TLB_OUT_COMBINED;
wire [TLB_OUT_BIT_WIDTH-1:0]  D_WR0_TLB_OUT_COMBINED;
wire [TLB_OUT_BIT_WIDTH-1:0]  D_WR1_TLB_OUT_COMBINED;

genvar j;
generate
  for (j = 0; j < NUM_TLB_ENTRIES; j = j + 1) begin : TLB_OUT_GATED_GEN

    // Same thing as TLB_ENTRY_BEHAV & TLB_ENTRY_SEL, just optimized
    nor2$   nor2$_ITLB_OUT_GATED[TLB_OUT_BIT_WIDTH-1:0](ITLB_OUT_GATED[j], TLB_ENTRIES_BEHAV_INV[j][TLB_OUT_BIT_WIDTH-1:0], {TLB_OUT_BIT_WIDTH{ITLB_ENTRY_SEL_buf16_inv[j]}});
    nor2$   nor2$_D_RD_TLB_OUT_GATED[TLB_OUT_BIT_WIDTH-1:0](D_RD_TLB_OUT_GATED[j], TLB_ENTRIES_BEHAV_INV[j][TLB_OUT_BIT_WIDTH-1:0], {TLB_OUT_BIT_WIDTH{D_RD_TLB_ENTRY_SEL_buf16_inv[j]}});
    nor2$   nor2$_D_WR0_TLB_OUT_GATED[TLB_OUT_BIT_WIDTH-1:0](D_WR0_TLB_OUT_GATED[j], TLB_ENTRIES_BEHAV_INV[j][TLB_OUT_BIT_WIDTH-1:0], {TLB_OUT_BIT_WIDTH{D_WR0_TLB_ENTRY_SEL_buf16_inv[j]}});
    nor2$   nor2$_D_WR1_TLB_OUT_GATED[TLB_OUT_BIT_WIDTH-1:0](D_WR1_TLB_OUT_GATED[j], TLB_ENTRIES_BEHAV_INV[j][TLB_OUT_BIT_WIDTH-1:0], {TLB_OUT_BIT_WIDTH{D_WR1_TLB_ENTRY_SEL_buf16_inv[j]}});

  end
endgenerate

genvar k;
generate
  for (k = 0; k < TLB_OUT_BIT_WIDTH; k = k + 1) begin : TLB_OUT_COMBINED_GEN

    big_or #(
      .WIDTH(NUM_TLB_ENTRIES)
    ) big_or_ITLB_OUT_COMBINED (
      .out(ITLB_OUT_COMBINED[k]),
      .in({ ITLB_OUT_GATED[0][k], ITLB_OUT_GATED[1][k],
            ITLB_OUT_GATED[2][k], ITLB_OUT_GATED[3][k],
            ITLB_OUT_GATED[4][k], ITLB_OUT_GATED[5][k],
            ITLB_OUT_GATED[6][k], ITLB_OUT_GATED[7][k]})
    );

    big_or #(
      .WIDTH(NUM_TLB_ENTRIES)
    ) big_or_D_RD_TLB_OUT_COMBINED (
      .out(D_RD_TLB_OUT_COMBINED[k]),
      .in({ D_RD_TLB_OUT_GATED[0][k], D_RD_TLB_OUT_GATED[1][k],
            D_RD_TLB_OUT_GATED[2][k], D_RD_TLB_OUT_GATED[3][k],
            D_RD_TLB_OUT_GATED[4][k], D_RD_TLB_OUT_GATED[5][k],
            D_RD_TLB_OUT_GATED[6][k], D_RD_TLB_OUT_GATED[7][k]})
    );

    big_or #(
      .WIDTH(NUM_TLB_ENTRIES)
    ) big_or_D_WR0_TLB_OUT_COMBINED (
      .out(D_WR0_TLB_OUT_COMBINED[k]),
      .in({ D_WR0_TLB_OUT_GATED[0][k], D_WR0_TLB_OUT_GATED[1][k],
            D_WR0_TLB_OUT_GATED[2][k], D_WR0_TLB_OUT_GATED[3][k],
            D_WR0_TLB_OUT_GATED[4][k], D_WR0_TLB_OUT_GATED[5][k],
            D_WR0_TLB_OUT_GATED[6][k], D_WR0_TLB_OUT_GATED[7][k]})
    );

    big_or #(
      .WIDTH(NUM_TLB_ENTRIES)
    ) big_or_D_WR1_TLB_OUT_COMBINED (
      .out(D_WR1_TLB_OUT_COMBINED[k]),
      .in({ D_WR1_TLB_OUT_GATED[0][k], D_WR1_TLB_OUT_GATED[1][k],
            D_WR1_TLB_OUT_GATED[2][k], D_WR1_TLB_OUT_GATED[3][k],
            D_WR1_TLB_OUT_GATED[4][k], D_WR1_TLB_OUT_GATED[5][k],
            D_WR1_TLB_OUT_GATED[6][k], D_WR1_TLB_OUT_GATED[7][k]})
    );

  end
endgenerate

/* Hit logic */

wire ITLB_HIT;
wire D_RD_TLB_HIT;
wire D_WR0_TLB_HIT;
wire D_WR1_TLB_HIT;

big_or #(
  .WIDTH(NUM_TLB_ENTRIES)
) big_or_ITLB_HIT (
  .out(ITLB_HIT),
  .in(ITLB_ENTRY_SEL_buf16)
);

big_or #(
  .WIDTH(NUM_TLB_ENTRIES)
) big_or_D_RD_TLB_HIT (
  .out(D_RD_TLB_HIT),
  .in(D_RD_TLB_ENTRY_SEL_buf16)
);

big_or #(
  .WIDTH(NUM_TLB_ENTRIES)
) big_or_D_WR0_TLB_HIT (
  .out(D_WR0_TLB_HIT),
  .in(D_WR0_TLB_ENTRY_SEL_buf16)
);

big_or #(
  .WIDTH(NUM_TLB_ENTRIES)
) big_or_D_WR1_TLB_HIT (
  .out(D_WR1_TLB_HIT),
  .in(D_WR1_TLB_ENTRY_SEL_buf16)
);

/* Simple output logic */

assign ITLB_PFN_OUT             = ITLB_OUT_COMBINED[TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign ITLB_WRITE_DISABLE_OUT   = ITLB_OUT_COMBINED[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];
assign ITLB_CACHE_ENABLE_OUT    = ITLB_OUT_COMBINED[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

assign D_RD_TLB_PFN_OUT             = D_RD_TLB_OUT_COMBINED[TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign D_RD_TLB_WRITE_DISABLE_OUT   = D_RD_TLB_OUT_COMBINED[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];
assign D_RD_TLB_CACHE_ENABLE_OUT    = D_RD_TLB_OUT_COMBINED[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

assign D_WR0_TLB_PFN_OUT             = D_WR0_TLB_OUT_COMBINED[TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign D_WR0_TLB_WRITE_DISABLE_OUT   = D_WR0_TLB_OUT_COMBINED[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];
assign D_WR0_TLB_CACHE_ENABLE_OUT    = D_WR0_TLB_OUT_COMBINED[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

assign D_WR1_TLB_PFN_OUT             = D_WR1_TLB_OUT_COMBINED[TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign D_WR1_TLB_WRITE_DISABLE_OUT   = D_WR1_TLB_OUT_COMBINED[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];
assign D_WR1_TLB_CACHE_ENABLE_OUT    = D_WR1_TLB_OUT_COMBINED[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

nand3$  nand3$_ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT, ITLB_HIT, ITLB_OUT_COMBINED[VALID_BIT_POS], ITLB_OUT_COMBINED[PRESENT_BIT_POS]);
nand3$  nand3$_D_RD_TLB_PAGE_FAULT_OUT(D_RD_TLB_PAGE_FAULT_OUT, D_RD_TLB_HIT, D_RD_TLB_OUT_COMBINED[VALID_BIT_POS], D_RD_TLB_OUT_COMBINED[PRESENT_BIT_POS]);
nand3$  nand3$_D_WR0_TLB_PAGE_FAULT_OUT(D_WR0_TLB_PAGE_FAULT_OUT, D_WR0_TLB_HIT, D_WR0_TLB_OUT_COMBINED[VALID_BIT_POS], D_WR0_TLB_OUT_COMBINED[PRESENT_BIT_POS]);
nand3$  nand3$_D_WR1_TLB_PAGE_FAULT_OUT(D_WR1_TLB_PAGE_FAULT_OUT, D_WR1_TLB_HIT, D_WR1_TLB_OUT_COMBINED[VALID_BIT_POS], D_WR1_TLB_OUT_COMBINED[PRESENT_BIT_POS]);

endmodule