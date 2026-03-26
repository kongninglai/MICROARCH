/*
 * fetch_buffer_tb.v — Exhaustive self-checking testbench for fetch_buffer
 *
 * Behavioral reference model models CORRECT intended behavior.
 * Known DUT bugs that will cause failures until fixed:
 *   1. mag_comp8$ A input: {4'd0,4'd16} overflows → cl_load stuck at 0
 *   2. cl_aligned is 128b feeding a 248b port → data lost for tail_ptr > 0
 *   3. wr_en is ungated → spurious writes when no cache line load
 *   4. Stray ); on line 113 of fetch_buffer.v → won't compile
 */

module fetch_buffer_tb;

initial begin
    $vcdplusfile("fetch_buffer_tb.dump.vpd");
    $vcdpluson(0, fetch_buffer_tb);
end

// ═══════════════════════════════════════════════════════════════
// Clock
// ═══════════════════════════════════════════════════════════════
reg clk;
initial begin clk = 0; forever #5 clk = ~clk; end

// ═══════════════════════════════════════════════════════════════
// DUT I/O
// ═══════════════════════════════════════════════════════════════
reg         rst_bar;
reg  [3:0]  from_de_instr_len;
reg         from_de_valid;
reg         from_wb_flush;
reg         from_ex_flush;
reg         from_de_stall;
reg         from_f_cl_pf;
reg  [127:0] from_f_cache_line;
reg  [31:0] i_eip;
reg         from_de_eip_redirection;
reg         shft_reg_we;

wire [4:0]   tail_ptr;
wire [127:0] to_de_outbytes;
wire [15:0]  to_de_pf_expn_bytes_out;
wire         ready;

fetch_buffer dut(
    .clk(clk), .rst_bar(rst_bar),
    .from_de_instr_len(from_de_instr_len),
    .from_de_valid(from_de_valid),
    .from_wb_flush(from_wb_flush),
    .from_ex_flush(from_ex_flush),
    .from_de_stall(from_de_stall),
    .from_f_cl_pf(from_f_cl_pf),
    .from_f_cache_line(from_f_cache_line),
    .i_eip(i_eip),
    .from_de_eip_redirection(from_de_eip_redirection),
    .shft_reg_we(shft_reg_we),
    .tail_ptr(tail_ptr),
    .to_de_outbytes(to_de_outbytes),
    .to_de_pf_expn_bytes_out(to_de_pf_expn_bytes_out),
    .ready(ready)
);

// ═══════════════════════════════════════════════════════════════
// Behavioral Reference Model
// ═══════════════════════════════════════════════════════════════

reg [7:0]  ref_buf [30:0];
reg        ref_pf  [30:0];
reg [4:0]  ref_tp;

integer ri_we, ri_inb, ri_buf;

// ─── Combinational derived signals ───────────────────────────

wire ref_flush   = from_wb_flush | from_ex_flush | from_de_eip_redirection;
wire ref_cl_load = (ref_tp < 5'd16);

// Bytes written from cache line: normal=16, redirect=16-instr_len
wire [4:0] ref_wr_cnt = ref_flush ? (5'd16 - {1'b0, from_de_instr_len}) : 5'd16;

// Write-enable mask: 16 contiguous 1s starting at ref_tp[3:0],
// ONLY when a cache line is actually being loaded
reg [30:0] ref_wr_en;
always @(*) begin
    ref_wr_en = 31'b0;
    if (ref_cl_load) begin
        for (ri_we = 0; ri_we < 16; ri_we = ri_we + 1)
            if (ref_tp[3:0] + ri_we < 31)
                ref_wr_en[ref_tp[3:0] + ri_we] = 1'b1;
    end
end

// Correct 248-bit inbytes: place cache line bytes at positions
// ref_tp[3:0]+0 through ref_tp[3:0]+15 (normal) or
// 0 through 15-instr_len (redirect)
reg [247:0] ref_inbytes;
always @(*) begin
    ref_inbytes = 248'b0;
    if (ref_flush) begin
        // Redirect: right-shift cache line by instr_len bytes
        for (ri_inb = 0; ri_inb < 16; ri_inb = ri_inb + 1)
            if (ri_inb + from_de_instr_len < 16)
                ref_inbytes[ri_inb*8 +: 8] = from_f_cache_line[(ri_inb + from_de_instr_len)*8 +: 8];
    end else begin
        // Normal: place CL at tail_ptr offset
        for (ri_inb = 0; ri_inb < 16; ri_inb = ri_inb + 1)
            if (ref_tp[3:0] + ri_inb < 31)
                ref_inbytes[(ref_tp[3:0] + ri_inb)*8 +: 8] = from_f_cache_line[ri_inb*8 +: 8];
    end
end

// Shift control
wire ref_stall_cl  = ref_cl_load & from_de_stall;
wire ref_shift_sig = from_de_valid | ref_stall_cl | from_wb_flush | from_ex_flush;
wire ref_shift_en  = ref_shift_sig & shft_reg_we;
wire ref_clr       = ~rst_bar | ref_flush;
wire ref_tp_en     = from_de_valid | ref_flush | from_de_stall | ref_cl_load;

// ─── Buffer update (async clear from flush/reset) ────────────

always @(posedge clk or posedge ref_clr) begin
    if (ref_clr) begin
        for (ri_buf = 0; ri_buf < 31; ri_buf = ri_buf + 1) begin
            ref_buf[ri_buf] <= 8'h0;
            ref_pf[ri_buf]  <= 1'b0;
        end
    end else begin
        for (ri_buf = 0; ri_buf < 31; ri_buf = ri_buf + 1) begin
            if (ref_shift_en) begin
                // Shift mode: shift by instr_len, with simultaneous write
                if (from_de_instr_len <= (30 - ri_buf)) begin
                    if (ref_wr_en[ri_buf + from_de_instr_len]) begin
                        ref_buf[ri_buf] <= ref_inbytes[(ri_buf + from_de_instr_len)*8 +: 8];
                        ref_pf[ri_buf]  <= from_f_cl_pf;
                    end else begin
                        ref_buf[ri_buf] <= ref_buf[ri_buf + from_de_instr_len];
                        ref_pf[ri_buf]  <= ref_pf[ri_buf + from_de_instr_len];
                    end
                end
                // else: source beyond buffer, hold value
            end else if (ref_wr_en[ri_buf]) begin
                // Write-only mode
                ref_buf[ri_buf] <= ref_inbytes[ri_buf*8 +: 8];
                ref_pf[ri_buf]  <= from_f_cl_pf;
            end
            // else: hold
        end
    end
end

// ─── Tail pointer update (sync, async reset from rst_bar) ────

always @(posedge clk or negedge rst_bar) begin
    if (!rst_bar) begin
        ref_tp <= 5'd0;
    end else if (ref_flush) begin
        ref_tp <= 5'd0;
    end else if (ref_tp_en) begin
        case ({from_de_stall, ref_cl_load})
            2'b00: ref_tp <= ref_tp - {1'b0, from_de_instr_len};
            2'b01: ref_tp <= ref_tp - {1'b0, from_de_instr_len} + ref_wr_cnt;
            2'b10: ref_tp <= ref_tp; // hold
            2'b11: ref_tp <= ref_tp + ref_wr_cnt;
        endcase
    end
end

// ─── Reference outputs ──────────────────────────────────────

wire [127:0] ref_outbytes = {
    ref_buf[15], ref_buf[14], ref_buf[13], ref_buf[12],
    ref_buf[11], ref_buf[10], ref_buf[9],  ref_buf[8],
    ref_buf[7],  ref_buf[6],  ref_buf[5],  ref_buf[4],
    ref_buf[3],  ref_buf[2],  ref_buf[1],  ref_buf[0]
};

wire [15:0] ref_pf_out;
genvar gi;
generate
    for (gi = 0; gi < 16; gi = gi + 1) begin : PF_OUT_GEN
        assign ref_pf_out[gi] = ref_pf[gi];
    end
endgenerate

// ═══════════════════════════════════════════════════════════════
// Test Infrastructure
// ═══════════════════════════════════════════════════════════════

integer num_tests, num_fail;

task apply_reset;
begin
    rst_bar              = 1'b0;
    from_de_instr_len    = 4'd0;
    from_de_valid        = 1'b0;
    from_wb_flush        = 1'b0;
    from_ex_flush        = 1'b0;
    from_de_stall        = 1'b0;
    from_f_cl_pf         = 1'b0;
    from_f_cache_line    = 128'b0;
    i_eip                = 32'b0;
    from_de_eip_redirection = 1'b0;
    shft_reg_we          = 1'b1;
    repeat (3) @(posedge clk);
    rst_bar = 1'b1;
    @(posedge clk);
end
endtask

task check;
    input [255:0] tag;
begin
    num_tests = num_tests + 1;
    if (tail_ptr !== ref_tp) begin
        num_fail = num_fail + 1;
        $display("FAIL %0s  tail_ptr: DUT=%0d  REF=%0d  (t=%0t)", tag, tail_ptr, ref_tp, $time);
    end
    if (to_de_outbytes !== ref_outbytes) begin
        num_fail = num_fail + 1;
        $display("FAIL %0s  outbytes: DUT=%h  REF=%h  (t=%0t)",
                 tag, to_de_outbytes, ref_outbytes, $time);
    end
    if (to_de_pf_expn_bytes_out !== ref_pf_out) begin
        num_fail = num_fail + 1;
        $display("FAIL %0s  pf_out: DUT=%h  REF=%h  (t=%0t)",
                 tag, to_de_pf_expn_bytes_out, ref_pf_out, $time);
    end
end
endtask

// Generate a cache line with recognizable byte values: byte[i] = base + i
function [127:0] make_cl;
    input [7:0] base;
    integer k;
begin
    make_cl = 128'b0;
    for (k = 0; k < 16; k = k + 1)
        make_cl[k*8 +: 8] = base + k[7:0];
end
endfunction

// Apply one cycle of stimulus, wait for settle, then check
// Inputs are set before the posedge, then de-asserted after.
task drive_cycle;
    input [255:0] tag;
    input         i_valid;
    input [3:0]   i_ilen;
    input         i_stall;
    input         i_wb_flush;
    input         i_ex_flush;
    input         i_eip_redir;
    input         i_pf;
    input [127:0] i_cl;
begin
    @(negedge clk);  // set inputs on negedge for clean setup
    from_de_valid           = i_valid;
    from_de_instr_len       = i_ilen;
    from_de_stall           = i_stall;
    from_wb_flush           = i_wb_flush;
    from_ex_flush           = i_ex_flush;
    from_de_eip_redirection = i_eip_redir;
    from_f_cl_pf            = i_pf;
    from_f_cache_line       = i_cl;
    @(posedge clk);
    #1;
    check(tag);
    // De-assert one-shot signals
    from_de_valid           = 1'b0;
    from_de_instr_len       = 4'd0;
    from_wb_flush           = 1'b0;
    from_ex_flush           = 1'b0;
    from_de_eip_redirection = 1'b0;
end
endtask

// ═══════════════════════════════════════════════════════════════
// Test Sequences
// ═══════════════════════════════════════════════════════════════

integer t_ctrl, t_ilen, t_rep, t_tp;
reg [127:0] cl_a, cl_b;

initial begin
    num_tests = 0;
    num_fail  = 0;

    // ══════════════════════════════════════════════════════════
    // Phase 1: Reset
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 1: Reset ===");
    apply_reset();
    #1; check("P1_RESET");

    // ══════════════════════════════════════════════════════════
    // Phase 2: Basic load → consume cycle
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 2: Basic load/consume ===");
    apply_reset();

    // Idle cycle with cache line present — should auto-load (tail_ptr=0 < 16)
    cl_a = make_cl(8'hA0);
    drive_cycle("P2_IDLE_LOAD", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // Wait one more idle cycle for the load to propagate
    drive_cycle("P2_SETTLE",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // Consume 3 bytes
    drive_cycle("P2_CONSUME3",  1'b1, 4'd3, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // Consume 5 bytes
    drive_cycle("P2_CONSUME5",  1'b1, 4'd5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // Consume 1 byte
    drive_cycle("P2_CONSUME1",  1'b1, 4'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // ══════════════════════════════════════════════════════════
    // Phase 3: Every instruction length (1–15)
    // Load a cache line, then consume each possible length
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 3: All instruction lengths ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(t_ilen[7:0] * 16);

        // Load CL (idle cycles until loaded)
        drive_cycle("P3_LOAD",     1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P3_SETTLE",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Consume t_ilen bytes
        drive_cycle("P3_CONSUME",  1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Load second CL at the new tail_ptr offset
        cl_b = make_cl(8'hB0 + t_ilen[7:0]);
        drive_cycle("P3_RELOAD",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
        drive_cycle("P3_SETTLE2",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);

        // Consume again
        drive_cycle("P3_CONSUME2", 1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    // Phase 4: Exhaustive control signal sweep
    // 6 signals: {wb_flush, ex_flush, eip_redir, valid, stall, pf}
    // = 64 combinations, each tested with instr_len=4
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 4: Control signal sweep (64 combos) ===");
    for (t_ctrl = 0; t_ctrl < 64; t_ctrl = t_ctrl + 1) begin
        apply_reset();

        // Pre-load buffer with data
        cl_a = make_cl(t_ctrl[7:0]);
        drive_cycle("P4_PRELOAD", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P4_SETTLE",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Apply control combination
        cl_b = make_cl(8'hFF - t_ctrl[7:0]);
        drive_cycle("P4_CTRL",
            /* valid */     t_ctrl[3],
            /* instr_len */ 4'd4,
            /* stall */     t_ctrl[2],
            /* wb_flush */  t_ctrl[5],
            /* ex_flush */  t_ctrl[4],
            /* eip_redir */ t_ctrl[1],
            /* pf */        t_ctrl[0],
            /* cl */        cl_b
        );

        // One cycle after to observe settled state
        drive_cycle("P4_AFTER", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    // Phase 5: Stall + cache line load combinations
    // For each instr_len, test stall with and without cl load
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 5: Stall + load combinations ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'hC0);
        drive_cycle("P5_LOAD", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P5_SETTLE", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Consume to create some room
        drive_cycle("P5_DRAIN", 1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Stall (no shift, might load CL if room)
        cl_b = make_cl(8'hD0);
        drive_cycle("P5_STALL", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);

        // Stall + CL present (should load without shifting)
        drive_cycle("P5_STALL_CL", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);

        // Release stall, consume
        drive_cycle("P5_RELEASE", 1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    // Phase 6: Flush types and recovery
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 6: Flush + recovery ===");

    // WB flush
    apply_reset();
    cl_a = make_cl(8'h10);
    drive_cycle("P6_LOAD1",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_SETTLE1", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_WB_FL",   1'b0, 4'd0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 128'b0);
    drive_cycle("P6_WB_REC",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h20));
    drive_cycle("P6_WB_SET",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h20));

    // EX flush
    apply_reset();
    cl_a = make_cl(8'h30);
    drive_cycle("P6_LOAD2",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_SETTLE2", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_EX_FL",   1'b0, 4'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 128'b0);
    drive_cycle("P6_EX_REC",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h40));
    drive_cycle("P6_EX_SET",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h40));

    // EIP redirection with every instr_len (jump offset)
    for (t_ilen = 0; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'h50);
        drive_cycle("P6_LOAD3",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P6_SETTLE3", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        // Redirect: cl is right-shifted by t_ilen, only 16-t_ilen bytes valid
        drive_cycle("P6_REDIR",   1'b0, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b1, 1'b0,
                     make_cl(8'h60));
        // Recovery: normal load
        drive_cycle("P6_REC3",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     make_cl(8'h70));
        drive_cycle("P6_SET3",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     make_cl(8'h70));
    end

    // ══════════════════════════════════════════════════════════
    // Phase 7: Sequential consume — walk tail_ptr from 16 down
    // Tests every tail_ptr value with every instr_len
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 7: Exhaustive tail_ptr x instr_len ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(t_ilen[7:0]);

        // Load CL → tail_ptr should go to 16
        drive_cycle("P7_LOAD", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P7_SET",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Consume repeatedly until buffer is nearly empty
        t_rep = 0;
        while (t_rep < 16) begin
            cl_b = make_cl(8'h80 + t_rep[7:0]);
            drive_cycle("P7_CONSUME", 1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
            t_rep = t_rep + t_ilen;
        end
    end

    // ══════════════════════════════════════════════════════════
    // Phase 8: Page fault tracking
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 8: Page fault tracking ===");
    apply_reset();

    // Load CL with page fault
    drive_cycle("P8_PF_LOAD",   1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, make_cl(8'h80));
    drive_cycle("P8_PF_SET",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, make_cl(8'h80));

    // Consume some bytes — PF flag should shift with data
    drive_cycle("P8_PF_SHIFT",  1'b1, 4'd5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h80));

    // Load CL without page fault — new bytes should not have PF
    drive_cycle("P8_NOPF_LOAD", 1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));
    drive_cycle("P8_NOPF_SET",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));

    // Consume — check that PF bytes from first CL are still flagged
    drive_cycle("P8_MIX",       1'b1, 4'd3, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));

    // Flush should clear PF flags
    drive_cycle("P8_FLUSH",     1'b0, 4'd0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 128'b0);
    drive_cycle("P8_AFTER_FL",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'hA0));

    // ══════════════════════════════════════════════════════════
    // Phase 9: Simultaneous shift + write (consume while loading)
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 9: Simultaneous shift+write ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'hE0);

        // Load initial CL
        drive_cycle("P9_LOAD",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P9_SETTLE",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Consume t_ilen bytes to make room
        drive_cycle("P9_DRAIN",   1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        // Now consume again — with new CL present, should shift+write simultaneously
        cl_b = make_cl(8'hF0);
        drive_cycle("P9_SHF_WR",  1'b1, t_ilen[3:0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);

        // Verify settled state
        drive_cycle("P9_VERIFY",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    // Phase 10: shft_reg_we gating
    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 10: shft_reg_we gating ===");
    apply_reset();
    cl_a = make_cl(8'h11);
    drive_cycle("P10_LOAD",    1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P10_SETTLE",  1'b0, 4'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // Try to consume with shft_reg_we=0 — shift should NOT happen
    shft_reg_we = 1'b0;
    drive_cycle("P10_NOWE",    1'b1, 4'd5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    shft_reg_we = 1'b1;

    // Now consume with we=1 — should work
    drive_cycle("P10_YEWE",    1'b1, 4'd5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // ══════════════════════════════════════════════════════════
    // Summary
    // ══════════════════════════════════════════════════════════
    $display("\n========================================");
    if (num_fail == 0)
        $display("ALL %0d TESTS PASSED", num_tests);
    else
        $display("FAILED: %0d / %0d tests", num_fail, num_tests);
    $display("========================================\n");

    $finish;
end

endmodule
