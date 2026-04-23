/*
 * iq_de_to_rr: 4-entry instruction queue between Decode and Register Read.
 *
 * Write: when wr == 1'b1 (from_de_pr_valid AND NOT full), advances wr_ptr.
 * Read:  when rd == 1'b1 (NOT from_rr_stall), advances rd_ptr.
 * Flush: clears entry_count to 0 next cycle.
 *
 * ENTRY LAYOUT (MSB to LSB, 226 bits total):
 *   [225]     from_de_pred_dir        (1b)
 *   [224:221] from_de_pht_idx         (4b)
 *   [220:219] from_f_exception_flags  (2b)
 *   [218:187] from_de_i_eip           (32b)
 *   [186:155] from_de_o_eip           (32b)
 *   [154:123] from_de_bp_target       (32b)
 *   [122]     from_de_pr_valid        (1b)  <-- valid bit
 *   [121:115] prefixes                (7b)
 *   [114:107] from_de_opcode          (8b)
 *   [106:99]  from_de_modrm           (8b)
 *   [98:91]   from_de_sib             (8b)
 *   [90:89]   from_de_disp_size_mux   (2b)
 *   [88:57]   from_de_disp            (32b)
 *   [56:54]   from_de_imm_size        (3b)
 *   [53:6]    from_de_imm             (48b)
 *   [5:4]     from_de_addressing_mode (2b)
 *   [3:0]     from_de_instr_length    (4b)
 *
 */

module iq_de_to_rr #(
  parameter ENTRY_BIT_WIDTH = 318,
  parameter VALID_BIT       = 218,
  parameter NUM_ENTRIES     = 4,
  parameter PTR_WIDTH       = $clog2(NUM_ENTRIES),
  parameter COUNT_WIDTH     = PTR_WIDTH + 1
) (
  input                           clk,
  input                           rst_n,
  input                           wr,
  input                           rd,
  input                           flush,
  input   [ENTRY_BIT_WIDTH-1:0]   data_in,

  output                          empty,
  output                          full,
  output  [COUNT_WIDTH-1:0]       entry_count,
  output  [ENTRY_BIT_WIDTH-1:0]   data_out,
  output                          head_valid
);

/*** WRITE POINTER LOGIC ***/

wire    [PTR_WIDTH-1:0]   wr_ptr, wr_ptr_buf64, wr_ptr_plus_1, wr_ptr_d;

bufferH64$    bufferH64$_wr_ptr_buf64[PTR_WIDTH-1:0](wr_ptr_buf64, wr_ptr);

/* wr_ptr_plus_1 = (wr_ptr + 1) mod 4, implemented as mux4_8$ with dummy bits */
wire [5:0] wr_ptr_plus_1_dummy;
mux4_8$ mux4_8$_wr_ptr_plus_1(
  {wr_ptr_plus_1_dummy, wr_ptr_plus_1},
  {6'd0, 2'b01},
  {6'd0, 2'b10},
  {6'd0, 2'b11},
  {6'd0, 2'b00},
  wr_ptr_buf64[0],
  wr_ptr_buf64[1]);

/* On flush, reset wr_ptr to 0 */
wire [5:0] wr_ptr_d_dummy;
mux2_8$ mux2_8$_wr_ptr_d(
  {wr_ptr_d_dummy, wr_ptr_d},
  {6'd0, wr_ptr_plus_1},
  {8'd0},
  flush);

wire    wr_ptr_en;
or2$    or2$_wr_ptr_en(wr_ptr_en, wr, flush);

reg_n #(
  .WIDTH(PTR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_wr_ptr (
  .clk(clk), .rst(rst_n),
  .en({PTR_WIDTH{wr_ptr_en}}), .d(wr_ptr_d),
  .q(wr_ptr)
);

/*** READ POINTER LOGIC ***/

wire    [PTR_WIDTH-1:0]   rd_ptr, rd_ptr_buf64, rd_ptr_plus_1, rd_ptr_d;

bufferH64$    bufferH64$_rd_ptr_buf64[PTR_WIDTH-1:0](rd_ptr_buf64, rd_ptr);

/* rd_ptr_plus_1 = (rd_ptr + 1) mod 4 */
wire [5:0] rd_ptr_plus_1_dummy;
mux4_8$ mux4_8$_rd_ptr_plus_1(
  {rd_ptr_plus_1_dummy, rd_ptr_plus_1},
  {6'd0, 2'b01},
  {6'd0, 2'b10},
  {6'd0, 2'b11},
  {6'd0, 2'b00},
  rd_ptr_buf64[0],
  rd_ptr_buf64[1]
);

/* On flush, reset rd_ptr to 0 */
wire [5:0] rd_ptr_d_dummy;
mux2_8$ mux2_8$_rd_ptr_d(
  {rd_ptr_d_dummy, rd_ptr_d},
  {6'd0, rd_ptr_plus_1},
  {8'd0},
  flush);

wire    rd_ptr_en;
or2$    or2$_rd_ptr_en(rd_ptr_en, rd, flush);

reg_n #(
  .WIDTH(PTR_WIDTH),
  .USE_EN_BAR(0)
) reg_n_rd_ptr (
  .clk(clk), .rst(rst_n),
  .en({PTR_WIDTH{rd_ptr_en}}), .d(rd_ptr_d),
  .q(rd_ptr)
);

/*** ENTRY COUNT LOGIC ***/

wire    [COUNT_WIDTH-1:0]   entry_count_buf16, entry_count_plus_1,
                            entry_count_minus_1, entry_count_next,
                            entry_count_d;

bufferH16$    bufferH16$_entry_count_buf16[COUNT_WIDTH-1:0](entry_count_buf16, entry_count);

big_increment #(
  .WIDTH(COUNT_WIDTH)
) big_increment_entry_count_plus_1 (
  .a(entry_count_buf16),
  .s(entry_count_plus_1)
);

big_decrement #(
  .WIDTH(COUNT_WIDTH)
) big_decrement_entry_count_minus_1 (
  .a(entry_count_buf16),
  .s(entry_count_minus_1)
);

/* mux4_8$: (out, in0, in1, in2, in3, s0, s1)
   s1=wr, s0=rd:
     00 -> in0 = entry_count_buf16   (no change)
     01 -> in1 = entry_count_minus_1 (rd only)
     10 -> in2 = entry_count_plus_1  (wr only)
     11 -> in3 = entry_count_buf16   (both, no change) */
wire [4:0] entry_count_next_dummy;
mux4_8$ mux4_8$_entry_count_next(
  {entry_count_next_dummy, entry_count_next},
  {5'd0, entry_count_buf16},
  {5'd0, entry_count_minus_1},
  {5'd0, entry_count_plus_1},
  {5'd0, entry_count_buf16},
  rd, wr);

/* On flush, force entry_count to 0 */
wire [4:0] entry_count_d_dummy;
mux2_8$ mux2_8$_entry_count_d(
  {entry_count_d_dummy, entry_count_d},
  {5'd0, entry_count_next},
  {8'd0},
  flush);

wire    entry_count_en;
nor3$   nor3$_entry_count_en(entry_count_en, wr, rd, flush);

reg_n #(
  .WIDTH(COUNT_WIDTH),
  .USE_EN_BAR(1)
) reg_n_entry_count (
  .clk(clk), .rst(rst_n),
  .en({COUNT_WIDTH{entry_count_en}}), .d(entry_count_d),
  .q(entry_count)
);

/*** ONE-HOT RD / WR LOGIC ***/

wire    [NUM_ENTRIES-1:0]   wr_one_hot, wr_one_hot_gated_bar, wr_one_hot_gated;

decoder2_4$   decoder2_4$_wr_one_hot(.SEL(wr_ptr_buf64), .Y(wr_one_hot), .YBAR());

nand2$   nand2$_wr_one_hot_gated_bar[NUM_ENTRIES-1:0](wr_one_hot_gated_bar, wr_one_hot, {NUM_ENTRIES{wr}});
bufferHInv1024$ bufferHInv1024$_wr_one_hot_gated[NUM_ENTRIES-1:0](wr_one_hot_gated, wr_one_hot_gated_bar);

/*** ENTRY INSTANTIATION ***/

wire    [ENTRY_BIT_WIDTH-1:0]   data_out_full [0:NUM_ENTRIES-1];

genvar i;
generate
  for (i = 0; i < NUM_ENTRIES; i = i + 1) begin : IQ_ENTRY_GEN
    iq_de_to_rr_entry #(
      .ENTRY_BIT_WIDTH(ENTRY_BIT_WIDTH)
    ) iq_de_to_rr_entry_inst (
      .clk(clk),
      .rst_n(rst_n),
      .wr(wr_one_hot_gated[i]),
      .data_in(data_in),
      .data_out(data_out_full[i])
    );
  end
endgenerate

/*** DATA OUTPUT SELECTION (mux4_16$ across entries, selected by rd_ptr) ***/

localparam FULL_CHUNKS = ENTRY_BIT_WIDTH / 16;
localparam REM_BITS    = ENTRY_BIT_WIDTH % 16;

genvar k;
generate
  for (k = 0; k < FULL_CHUNKS; k = k + 1) begin : DATA_OUT_MUX4_16b_GEN
    mux4_16$ mux4_16_data_out (
      data_out[k*16 +: 16],
      data_out_full[0][k*16 +: 16],
      data_out_full[1][k*16 +: 16],
      data_out_full[2][k*16 +: 16],
      data_out_full[3][k*16 +: 16],
      rd_ptr_buf64[0],
      rd_ptr_buf64[1]
    );
  end
endgenerate

/* Top leftover bits, padded to 16 for mux4_16$ */
wire [(16-REM_BITS)-1:0] data_out_top_dummy;
mux4_16$ mux4_16_data_out_top (
  {data_out_top_dummy, data_out[ENTRY_BIT_WIDTH-1 : FULL_CHUNKS*16]},
  {{(16-REM_BITS){1'b0}}, data_out_full[0][ENTRY_BIT_WIDTH-1 : FULL_CHUNKS*16]},
  {{(16-REM_BITS){1'b0}}, data_out_full[1][ENTRY_BIT_WIDTH-1 : FULL_CHUNKS*16]},
  {{(16-REM_BITS){1'b0}}, data_out_full[2][ENTRY_BIT_WIDTH-1 : FULL_CHUNKS*16]},
  {{(16-REM_BITS){1'b0}}, data_out_full[3][ENTRY_BIT_WIDTH-1 : FULL_CHUNKS*16]},
  rd_ptr_buf64[0],
  rd_ptr_buf64[1]
);

/*** HEAD VALID ***/
assign head_valid = data_out[VALID_BIT];

/*** STATUS LOGIC ***/
/* full when entry_count == 4 (bit 2 set) */
assign full = entry_count_buf16[2];

nor3$   nor3$_empty(empty, entry_count_buf16[0], entry_count_buf16[1], entry_count_buf16[2]);

endmodule
