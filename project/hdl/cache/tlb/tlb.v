// PFN is ready at 2.0 ns as of 03/09/2026. -VR

module tlb #(
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
  input       [VPN_BIT_WIDTH-1:0]                           TLB_VPN,
  
  output      [PFN_BIT_WIDTH-1:0]                           TLB_PFN_OUT, 
  output                                                    TLB_WRITE_DISABLE_OUT, 
                                                            TLB_CACHE_ENABLE_OUT, 
                                                            TLB_PAGE_FAULT_OUT
);

reg [TLB_ENTRY_BIT_WIDTH-1:0]   TLB_ENTRIES_BEHAV[0:NUM_TLB_ENTRIES-1];
wire [TLB_ENTRY_BIT_WIDTH-1:0]  TLB_ENTRIES_BEHAV_INV[0:NUM_TLB_ENTRIES-1];

initial begin
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tlb/tlb_init.txt", TLB_ENTRIES_BEHAV);
end

genvar h;
generate
  for (h = 0; h < NUM_TLB_ENTRIES; h = h + 1) begin : TLB_ENTRIES_BEHAV_INV_GEN
    inv1$   inv1$_TLB_ENTRIES_BEHAV_INV[TLB_ENTRY_BIT_WIDTH-1:0](TLB_ENTRIES_BEHAV_INV[h], TLB_ENTRIES_BEHAV[h]);
  end
endgenerate

/* One-hot encoding of which entry has a HIT */
wire [NUM_TLB_ENTRIES-1:0]  TLB_ENTRY_SEL;

// Critical path of big_eq, WIDTH=20 is xor2 + nor4 + nand2 + nor3 = 0.3 + 0.35 + 0.2 + 0.25 = 1.1 ns
genvar i;
generate
  for (i = 0; i < NUM_TLB_ENTRIES; i = i + 1) begin : VPN_COMPARE_GEN
    big_eq #(
      .WIDTH(VPN_BIT_WIDTH)
    ) big_eq_TLB_ENTRY_SEL (
      .in0(TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH]), 
      .in1(TLB_VPN),
      .eq(TLB_ENTRY_SEL[i])
    );
  end
endgenerate

/* One-hot mux */

// Critical path of bufferH16 = 0.24 ns
// Critical path of bufferHInv16 = 0.15 ns
wire [NUM_TLB_ENTRIES-1:0]    TLB_ENTRY_SEL_buf16, TLB_ENTRY_SEL_buf16_inv;
bufferH16$        bufferH16$_TLB_ENTRY_SEL_buf16[NUM_TLB_ENTRIES-1:0](TLB_ENTRY_SEL_buf16, TLB_ENTRY_SEL);
bufferHInv16$     bufferHInv16$_TLB_ENTRY_SEL_buf16_inv[NUM_TLB_ENTRIES-1:0](TLB_ENTRY_SEL_buf16_inv, TLB_ENTRY_SEL);


wire [TLB_OUT_BIT_WIDTH-1:0]  TLB_OUT_GATED[0:NUM_TLB_ENTRIES-1];

wire [TLB_OUT_BIT_WIDTH-1:0]  TLB_OUT_COMBINED;

// Critical path of nor2 = 0.2 ns
genvar j;
generate
  for (j = 0; j < NUM_TLB_ENTRIES; j = j + 1) begin : TLB_OUT_GATED_GEN
    // Same thing as TLB_ENTRY_BEHAV & TLB_ENTRY_SEL, just optimized
    nor2$   nor2$_TLB_OUT_GATED[TLB_OUT_BIT_WIDTH-1:0](TLB_OUT_GATED[j], TLB_ENTRIES_BEHAV_INV[j][TLB_OUT_BIT_WIDTH-1:0], {TLB_OUT_BIT_WIDTH{TLB_ENTRY_SEL_buf16_inv[j]}});
  end
endgenerate

// Critical path of big_or, WIDTH=8 = nor4 + nand2 = 0.35 + 0.2 = 0.55 ns
genvar k;
generate
  for (k = 0; k < TLB_OUT_BIT_WIDTH; k = k + 1) begin : TLB_OUT_COMBINED_GEN
    big_or #(
      .WIDTH(NUM_TLB_ENTRIES)
    ) big_or_TLB_OUT_COMBINED (
      .out(TLB_OUT_COMBINED[k]),
      .in({ TLB_OUT_GATED[0][k], TLB_OUT_GATED[1][k],
            TLB_OUT_GATED[2][k], TLB_OUT_GATED[3][k],
            TLB_OUT_GATED[4][k], TLB_OUT_GATED[5][k],
            TLB_OUT_GATED[6][k], TLB_OUT_GATED[7][k]})
    );
  end
endgenerate

/* Hit logic */

wire    TLB_HIT;

// Critical path of big_or, WIDTH=8 = nor4 + nand2 = 0.35 + 0.2 = 0.55 ns
big_or #(
  .WIDTH(NUM_TLB_ENTRIES)
) big_or_TLB_HIT (
  .out(TLB_HIT),
  .in(TLB_ENTRY_SEL_buf16)
);

/* Simple output logic */

assign TLB_PFN_OUT            = TLB_OUT_COMBINED[TLB_OUT_BIT_WIDTH-1:TLB_OUT_BIT_WIDTH-PFN_BIT_WIDTH];
assign TLB_WRITE_DISABLE_OUT  = TLB_OUT_COMBINED[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];
assign TLB_CACHE_ENABLE_OUT   = TLB_OUT_COMBINED[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

// Critical path of nand3 = 0.2 ns
nand3$  nand3$_TLB_PAGE_FAULT_OUT(TLB_PAGE_FAULT_OUT, TLB_HIT, TLB_OUT_COMBINED[VALID_BIT_POS], TLB_OUT_COMBINED[PRESENT_BIT_POS]);

endmodule