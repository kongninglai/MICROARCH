/*
 * fetch_buffer_tb.v — Exhaustive self-checking testbench for fetch_buffer
 *
 * Updated: Reference model now correctly accounts for the 1-cycle latency 
 * of the latched cache line request (fb_req_cl_stable) and mirrors the 
 * de_valid instruction length gating logic.
 */

`timescale 1ns / 1ps

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
reg         from_f_icache_valid; // <--- ADDED missing port
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
    .from_f_icache_valid(from_f_icache_valid), // <--- Connected to DUT
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

// Account for gated length (Fixes shift/write corruption on invalid cycles)
wire [3:0] ref_gated_ilen = from_de_valid ? from_de_instr_len : 4'd0;

wire ref_eip_redir_valid = from_de_eip_redirection & from_de_valid;
wire ref_flush = from_wb_flush | from_ex_flush | ref_eip_redir_valid;
wire ref_cl_space = (ref_tp < 5'd16);

// Mimic the exact 1-cycle latch behavior of CL_REQ_HOLD (fb_req_cl_stable)
reg ref_req_stable;
wire ref_v_cl_ld;
wire ref_gated_req = ref_cl_space & ~ref_v_cl_ld;

always @(posedge clk or negedge rst_bar) begin
    if (!rst_bar) ref_req_stable <= 1'b0;
    else          ref_req_stable <= ref_gated_req;
end

// The final actual write-enable signal equivalent to v_cl_ld
assign ref_v_cl_ld = ref_req_stable & rst_bar & from_f_icache_valid;

// Bytes written from cache line: normal=16, redirect=16-instr_len
wire [4:0] ref_wr_cnt = ref_flush ? (5'd16 - {1'b0, ref_gated_ilen}) : 5'd16;

// Write-enable mask: ONLY when a cache line is actually being loaded
reg [30:0] ref_wr_en;
always @(*) begin
    ref_wr_en = 31'b0;
    if (ref_v_cl_ld) begin
        for (ri_we = 0; ri_we < 16; ri_we = ri_we + 1)
            if (ref_tp[3:0] + ri_we < 31)
                ref_wr_en[ref_tp[3:0] + ri_we] = 1'b1;
    end
end

// Correct 248-bit inbytes calculation based on gated len
reg [247:0] ref_inbytes;
always @(*) begin
    ref_inbytes = 248'b0;
    if (ref_flush) begin
        // Redirect: right-shift cache line by instr_len bytes
        for (ri_inb = 0; ri_inb < 16; ri_inb = ri_inb + 1)
            if (ri_inb + ref_gated_ilen < 16)
                ref_inbytes[ri_inb*8 +: 8] = from_f_cache_line[(ri_inb + ref_gated_ilen)*8 +: 8];
    end else begin
        // Normal: place CL at tail_ptr offset
        for (ri_inb = 0; ri_inb < 16; ri_inb = ri_inb + 1)
            if (ref_tp[3:0] + ri_inb < 31)
                ref_inbytes[(ref_tp[3:0] + ri_inb)*8 +: 8] = from_f_cache_line[ri_inb*8 +: 8];
    end
end

// Shift control
wire ref_stall_cl  = ref_v_cl_ld & from_de_stall;
wire ref_shift_sig = from_de_valid | ref_v_cl_ld | ref_flush;
wire ref_shift_en  = ref_shift_sig & shft_reg_we;
wire ref_clr       = ~rst_bar | ref_flush;
wire ref_tp_en     = from_de_valid | ref_flush | from_de_stall | ref_v_cl_ld;

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
                if (ref_gated_ilen <= (30 - ri_buf)) begin
                    if (ref_wr_en[ri_buf + ref_gated_ilen]) begin
                        ref_buf[ri_buf] <= ref_inbytes[(ri_buf + ref_gated_ilen)*8 +: 8];
                        ref_pf[ri_buf]  <= from_f_cl_pf;
                    end else begin
                        ref_buf[ri_buf] <= ref_buf[ri_buf + ref_gated_ilen];
                        ref_pf[ri_buf]  <= ref_pf[ri_buf + ref_gated_ilen];
                    end
                end
            end else if (ref_wr_en[ri_buf]) begin
                ref_buf[ri_buf] <= ref_inbytes[ri_buf*8 +: 8];
                ref_pf[ri_buf]  <= from_f_cl_pf;
            end
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
        case ({from_de_stall, ref_v_cl_ld})
            2'b00: ref_tp <= ref_tp - {1'b0, ref_gated_ilen};
            2'b01: ref_tp <= ref_tp - {1'b0, ref_gated_ilen} + ref_wr_cnt;
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
integer fail_flag;

task apply_reset;
begin
    rst_bar                 = 1'b0;
    from_de_instr_len       = 4'd0;
    from_de_valid           = 1'b0;
    from_f_icache_valid     = 1'b0; // Default cache to invalid on reset
    from_wb_flush           = 1'b0;
    from_ex_flush           = 1'b0;
    from_de_stall           = 1'b0;
    from_f_cl_pf            = 1'b0;
    from_f_cache_line       = 128'b0;
    i_eip                   = 32'b0;
    from_de_eip_redirection = 1'b0;
    shft_reg_we             = 1'b1;
    repeat (3) @(posedge clk);
    #1;
    rst_bar = 1'b1;
    @(posedge clk);
end
endtask

task check;
    input [255:0] tag;
begin
    num_tests = num_tests + 1;
    if (tail_ptr !== ref_tp) begin
        fail_flag = 1;
        $display("FAIL %0s  tail_ptr: DUT=%0d  REF=%0d  (t=%0t)", tag, tail_ptr, ref_tp, $time);
    end
    if (to_de_outbytes !== ref_outbytes) begin
        fail_flag = 1;
        $display("FAIL %0s  outbytes: DUT=%h  REF=%h  (t=%0t)",
                 tag, to_de_outbytes, ref_outbytes, $time);
    end
    if (to_de_pf_expn_bytes_out !== ref_pf_out) begin
        fail_flag = 1;
        $display("FAIL %0s  pf_out: DUT=%h  REF=%h  (t=%0t)",
                 tag, to_de_pf_expn_bytes_out, ref_pf_out, $time);
    end
    if(fail_flag == 1) begin
        num_fail = num_fail + 1;
        fail_flag = 0;
    end 
end
endtask

function [127:0] make_cl;
    input [7:0] base;
    integer k;
begin
    make_cl = 128'b0;
    for (k = 0; k < 16; k = k + 1)
        make_cl[k*8 +: 8] = base + k[7:0];
end
endfunction

task drive_cycle;
    input [255:0] tag;
    input         i_valid;
    input [3:0]   i_ilen;
    input         i_icache_valid; // <--- NEW ARGUMENT
    input         i_stall;
    input         i_wb_flush;
    input         i_ex_flush;
    input         i_eip_redir;
    input         i_pf;
    input [127:0] i_cl;
begin
    @(negedge clk); 
    from_de_valid           = i_valid;
    from_de_instr_len       = i_ilen;
    from_f_icache_valid     = i_icache_valid; // Apply Handshake
    from_de_stall           = i_stall;
    from_wb_flush           = i_wb_flush;
    from_ex_flush           = i_ex_flush;
    from_de_eip_redirection = i_eip_redir;
    from_f_cl_pf            = i_pf;
    from_f_cache_line       = i_cl;
    
    @(posedge clk);
    #5; // Wait for flip-flops to update state
    check(tag);
    
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
    $display("\n=== Phase 1: Reset ===");
    apply_reset();
    #1; check("P1_RESET");

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 2: Basic load/consume ===");
    apply_reset();

    cl_a = make_cl(8'hA0);
    drive_cycle("P2_IDLE_LOAD", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P2_SETTLE",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    drive_cycle("P2_CONSUME3",  1'b1, 4'd3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P2_CONSUME5",  1'b1, 4'd5, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P2_CONSUME1",  1'b1, 4'd1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 3: All instruction lengths ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(t_ilen[7:0] * 16);

        drive_cycle("P3_LOAD",     1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P3_SETTLE",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        drive_cycle("P3_CONSUME",  1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        cl_b = make_cl(8'hB0 + t_ilen[7:0]);
        drive_cycle("P3_RELOAD",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
        drive_cycle("P3_SETTLE2",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);

        drive_cycle("P3_CONSUME2", 1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 4: Control signal sweep (64 combos) ===");
    for (t_ctrl = 0; t_ctrl < 64; t_ctrl = t_ctrl + 1) begin
        apply_reset();

        cl_a = make_cl(t_ctrl[7:0]);
        drive_cycle("P4_PRELOAD", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P4_SETTLE",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        cl_b = make_cl(8'hFF - t_ctrl[7:0]);
        drive_cycle("P4_CTRL",
            /* valid */     t_ctrl[3],
            /* instr_len */ 4'd4,
            /* icache_val*/ 1'b1, 
            /* stall */     t_ctrl[2],
            /* wb_flush */  t_ctrl[5],
            /* ex_flush */  t_ctrl[4],
            /* eip_redir */ t_ctrl[1],
            /* pf */        t_ctrl[0],
            /* cl */        cl_b
        );

        drive_cycle("P4_AFTER", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 5: Stall + load combinations ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'hC0);
        drive_cycle("P5_LOAD",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P5_SETTLE", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        drive_cycle("P5_DRAIN", 1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        cl_b = make_cl(8'hD0);
        drive_cycle("P5_STALL",    1'b0, 4'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
        drive_cycle("P5_STALL_CL", 1'b0, 4'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
        drive_cycle("P5_RELEASE",  1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 6: Flush + recovery ===");

    apply_reset();
    cl_a = make_cl(8'h10);
    drive_cycle("P6_LOAD1",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_SETTLE1", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_WB_FL",   1'b0, 4'd0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 128'b0);
    drive_cycle("P6_WB_REC",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h20));
    drive_cycle("P6_WB_SET",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h20));

    apply_reset();
    cl_a = make_cl(8'h30);
    drive_cycle("P6_LOAD2",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_SETTLE2", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P6_EX_FL",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 128'b0);
    drive_cycle("P6_EX_REC",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h40));
    drive_cycle("P6_EX_SET",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h40));

    for (t_ilen = 0; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'h50);
        drive_cycle("P6_LOAD3",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P6_SETTLE3", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        
        drive_cycle("P6_REDIR",   1'b0, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, make_cl(8'h60));
        drive_cycle("P6_REC3",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h70));
        drive_cycle("P6_SET3",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h70));
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 7: Exhaustive tail_ptr x instr_len ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(t_ilen[7:0]);

        drive_cycle("P7_LOAD", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P7_SET",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        t_rep = 0;
        while (t_rep < 16) begin
            cl_b = make_cl(8'h80 + t_rep[7:0]);
            drive_cycle("P7_CONSUME", 1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
            t_rep = t_rep + t_ilen;
        end
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 8: Page fault tracking ===");
    apply_reset();

    drive_cycle("P8_PF_LOAD",   1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, make_cl(8'h80));
    drive_cycle("P8_PF_SET",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, make_cl(8'h80));
    drive_cycle("P8_PF_SHIFT",  1'b1, 4'd5, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h80));

    drive_cycle("P8_NOPF_LOAD", 1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));
    drive_cycle("P8_NOPF_SET",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));
    drive_cycle("P8_MIX",       1'b1, 4'd3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'h90));

    drive_cycle("P8_FLUSH",     1'b0, 4'd0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 128'b0);
    drive_cycle("P8_AFTER_FL",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, make_cl(8'hA0));

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 9: Simultaneous shift+write ===");
    for (t_ilen = 1; t_ilen <= 15; t_ilen = t_ilen + 1) begin
        apply_reset();
        cl_a = make_cl(8'hE0);

        drive_cycle("P9_LOAD",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P9_SETTLE",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
        drive_cycle("P9_DRAIN",   1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

        cl_b = make_cl(8'hF0);
        drive_cycle("P9_SHF_WR",  1'b1, t_ilen[3:0], 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
        drive_cycle("P9_VERIFY",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_b);
    end

    // ══════════════════════════════════════════════════════════
    $display("\n=== Phase 10: shft_reg_we gating ===");
    apply_reset();
    cl_a = make_cl(8'h11);
    drive_cycle("P10_LOAD",    1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    drive_cycle("P10_SETTLE",  1'b0, 4'd0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    shft_reg_we = 1'b0;
    drive_cycle("P10_NOWE",    1'b1, 4'd5, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);
    shft_reg_we = 1'b1;

    drive_cycle("P10_YEWE",    1'b1, 4'd5, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, cl_a);

    // ══════════════════════════════════════════════════════════
    $display("\n========================================");
    if (num_fail == 0)
        $display("  ✅ ALL %0d TESTS PASSED", num_tests);
    else
        $display("  ❌ FAILED: %0d / %0d tests", num_fail, num_tests);
    $display("========================================\n");

    $finish;
end

endmodule