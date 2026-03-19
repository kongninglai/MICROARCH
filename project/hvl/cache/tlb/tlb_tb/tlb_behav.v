module tlb_behav #(
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
)(
  input  [VPN_BIT_WIDTH-1:0] TLB_VPN,

  output reg [PFN_BIT_WIDTH-1:0] TLB_PFN_OUT,
  output reg                     TLB_WRITE_DISABLE_OUT,
  output reg                     TLB_CACHE_ENABLE_OUT,
  output reg                     TLB_PAGE_FAULT_OUT
);

reg [TLB_ENTRY_BIT_WIDTH-1:0] TLB_ENTRIES_BEHAV[0:NUM_TLB_ENTRIES-1];

initial begin
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tlb/tlb_init.txt",
            TLB_ENTRIES_BEHAV);
end

integer i;

reg hit;
reg [TLB_ENTRY_BIT_WIDTH-1:0] matched_entry;

always @(*) begin

  hit = 0;
  matched_entry = {TLB_ENTRY_BIT_WIDTH{1'b0}};

  for (i = 0; i < NUM_TLB_ENTRIES; i = i + 1) begin
    if (TLB_ENTRIES_BEHAV[i][TLB_ENTRY_BIT_WIDTH-1:TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH] == TLB_VPN) begin
      hit = 1;
      matched_entry = TLB_ENTRIES_BEHAV[i];
    end
  end

  TLB_PFN_OUT =
      matched_entry[TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH-1 :
                    TLB_ENTRY_BIT_WIDTH-VPN_BIT_WIDTH-PFN_BIT_WIDTH];

  TLB_WRITE_DISABLE_OUT =
      matched_entry[PAGE_LEVEL_WRITE_DISABLE_BIT_POS];

  TLB_CACHE_ENABLE_OUT =
      matched_entry[PAGE_LEVEL_CACHE_ENABLE_BIT_POS];

  TLB_PAGE_FAULT_OUT =
      ~(hit &
        matched_entry[VALID_BIT_POS] &
        matched_entry[PRESENT_BIT_POS]);

end

endmodule