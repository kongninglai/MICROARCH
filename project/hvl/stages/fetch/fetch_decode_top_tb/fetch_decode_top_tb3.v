`timescale 1ns/1ps

module fetch_decode_top_tb3;

localparam VA_BIT_WIDTH        = 32;
localparam VPN_BIT_WIDTH       = 20;
localparam PFN_BIT_WIDTH       = 3;
localparam PAGE_BIT_WIDTH      = 12;
localparam SEGR_DATA_BIT_WIDTH = 16;

localparam CYCLE_TIME_X10 = 150;
localparam CYCLE_TIME     = CYCLE_TIME_X10 / 10.0;

reg clk;
reg rst_n;

initial begin
    clk = 1'b0;
    forever #(CYCLE_TIME/2.0) clk = ~clk;
end

// DUT inputs
reg [PFN_BIT_WIDTH-1:0] ITLB_PFN_OUT;
reg ITLB_PAGE_FAULT_OUT;

reg ICACHE_VALID;
reg [127:0] ICACHE_HIT_DATA;

reg [SEGR_DATA_BIT_WIDTH-1:0] from_rr_cs;
reg from_rr_stall;

reg from_ex_ld_cs;
reg [VA_BIT_WIDTH-1:0] from_ex_eip_target_out;
reg from_ex_flush;
reg from_ex_br_t_nt;
reg from_ex_br_valid;
reg [3:0] from_ex_pht_idx;

reg from_wb_flush;

// DUT outputs
wire [VPN_BIT_WIDTH-1:0] ITLB_VPN;
wire [PAGE_BIT_WIDTH-1:0] F_PAGE_OFFSET;

wire [5:0] to_rr_prefix;
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
wire [31:0] to_pr_pred_eip;
wire [1:0] to_rr_exception;
wire to_rr_valid;

fetch_decode_top DUT (
    .clk(clk),
    .rst_bar(rst_n),

    .ITLB_VPN(ITLB_VPN),
    .ITLB_PFN_OUT(ITLB_PFN_OUT),
    .ITLB_PAGE_FAULT_OUT(ITLB_PAGE_FAULT_OUT),

    .ICACHE_VALID(ICACHE_VALID),
    .ICACHE_HIT_DATA(ICACHE_HIT_DATA),
    .F_PAGE_OFFSET(F_PAGE_OFFSET),

    .from_rr_cs(from_rr_cs),
    .from_rr_stall(from_rr_stall),

    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_eip_target(from_ex_eip_target_out),
    .from_ex_flush(from_ex_flush),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_pht_idx(from_ex_pht_idx),

    .from_wb_flush(from_wb_flush),

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
    .to_pr_pred_eip(to_pr_pred_eip),
    .to_rr_exception(to_rr_exception),
    .to_rr_valid(to_rr_valid)
);

integer FAILURES;
integer SUCCESSES;
integer CYCLE_COUNT;
integer log_fd;
integer CASE_LOCAL_FAIL;

// Program-style byte map used by directed cases.
//
// 0x0000: b8 11 22 33 44    // mov eax,0x44332211 (5B)
// 0x0005: 05 aa bb cc dd    // add eax,0xddccbbaa (5B)
// 0x000a: 25 0f 0f 0f 0f    // and eax,0x0f0f0f0f (5B)
// 0x000e: 05 78 56 34 12    // add eax,0x12345678 (5B, split target)
// 0x0013: 26 81 c0 78 56 34 12 // es:add eax,0x12345678 (7B)

always @(posedge clk) begin
    CYCLE_COUNT = CYCLE_COUNT + 1;
end

always @(posedge clk) begin
    if (ICACHE_VALID === 1'b1 || from_ex_flush === 1'b1 || from_rr_stall === 1'b1) begin
        $display("[TRACE] cyc=%0d t=%0t PC=%h FEIP=%h valid=%b opcode=%h tail=%0d stall=%b flush=%b v_cl_ld=%b",
                 CYCLE_COUNT,
                 $time,
                 {ITLB_VPN, F_PAGE_OFFSET},
                 DUT.STAGE_FETCH_FRONT_HALF.FETCH_POINTER.feip_reg_out32,
                 to_rr_valid,
                 to_rr_opcode,
                 DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr,
                 from_rr_stall,
                 from_ex_flush,
                 DUT.FETCHBUFF_DECODESTAGE_DEPR.FETCH_BUFF.v_cl_ld);
        $fdisplay(log_fd,
                 "[TRACE] cyc=%0d t=%0t PC=%h FEIP=%h valid=%b opcode=%h tail=%0d stall=%b flush=%b v_cl_ld=%b",
                 CYCLE_COUNT,
                 $time,
                 {ITLB_VPN, F_PAGE_OFFSET},
                 DUT.STAGE_FETCH_FRONT_HALF.FETCH_POINTER.feip_reg_out32,
                 to_rr_valid,
                 to_rr_opcode,
                 DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr,
                 from_rr_stall,
                 from_ex_flush,
                 DUT.FETCHBUFF_DECODESTAGE_DEPR.FETCH_BUFF.v_cl_ld);
    end
end

task tick;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            @(posedge clk);
        end
    end
endtask

task clear_line;
    output [127:0] line;
    begin
        line = 128'h0;
    end
endtask

task set_line_byte;
    inout [127:0] line;
    input integer idx;
    input [7:0] value;
    begin
        if (idx >= 0 && idx < 16) begin
            line[(idx*8) +: 8] = value;
        end
    end
endtask

task begin_case;
    input [8*80:1] case_name;
    begin
        CASE_LOCAL_FAIL = 0;
        $display("\n============================================================");
        $display("CASE START: %0s", case_name);
        $display("============================================================");
        $fdisplay(log_fd, "\n============================================================");
        $fdisplay(log_fd, "CASE START: %0s", case_name);
        $fdisplay(log_fd, "============================================================");
    end
endtask

task end_case;
    input [8*80:1] case_name;
    begin
        if (CASE_LOCAL_FAIL == 0) begin
            SUCCESSES = SUCCESSES + 1;
            $display("CASE PASS: %0s", case_name);
            $fdisplay(log_fd, "CASE PASS: %0s", case_name);
        end else begin
            FAILURES = FAILURES + CASE_LOCAL_FAIL;
            $display("CASE FAIL: %0s (local_failures=%0d)", case_name, CASE_LOCAL_FAIL);
            $fdisplay(log_fd, "CASE FAIL: %0s (local_failures=%0d)", case_name, CASE_LOCAL_FAIL);
        end
    end
endtask

task case_fail;
    input [8*120:1] msg;
    begin
        CASE_LOCAL_FAIL = CASE_LOCAL_FAIL + 1;
        $display("  [MISMATCH] %0s (t=%0t)", msg, $time);
        $fdisplay(log_fd, "  [MISMATCH] %0s (t=%0t)", msg, $time);
    end
endtask

task pulse_ex_flush;
    input [31:0] target;
    begin
        @(negedge clk);
        from_ex_eip_target_out = target;
        from_ex_flush = 1'b1;
        @(posedge clk);
        @(negedge clk);
        from_ex_flush = 1'b0;
    end
endtask

task send_line_until_accept;
    input [127:0] line_data;
    input integer max_cycles;
    integer guard;
    reg accepted;
    begin
        accepted = 1'b0;
        ICACHE_HIT_DATA = line_data;
        ICACHE_VALID = 1'b1;

        guard = 0;
        while ((guard < max_cycles) && (accepted == 1'b0)) begin
            @(posedge clk);
            if (DUT.FETCHBUFF_DECODESTAGE_DEPR.FETCH_BUFF.v_cl_ld === 1'b1) begin
                accepted = 1'b1;
            end
            guard = guard + 1;
        end

        @(negedge clk);
        ICACHE_VALID = 1'b0;

        if (accepted == 1'b0) begin
            case_fail("ICACHE line was not accepted within timeout");
        end
    end
endtask

task wait_for_valid;
    input integer max_cycles;
    output timed_out;
    integer cnt;
    begin
        timed_out = 1'b0;
        cnt = 0;
        while ((to_rr_valid !== 1'b1) && (cnt < max_cycles)) begin
            @(posedge clk);
            cnt = cnt + 1;
        end
        if (to_rr_valid !== 1'b1) begin
            timed_out = 1'b1;
        end
    end
endtask

task wait_for_invalid;
    input integer max_cycles;
    output timed_out;
    integer cnt;
    begin
        timed_out = 1'b0;
        cnt = 0;
        while ((to_rr_valid === 1'b1) && (cnt < max_cycles)) begin
            @(posedge clk);
            cnt = cnt + 1;
        end
        if (to_rr_valid === 1'b1) begin
            timed_out = 1'b1;
        end
    end
endtask

task case1_seq_with_miss;
    reg [127:0] line_a;
    reg [127:0] line_b;
    reg timed_out;
    begin
        begin_case("Case1 Sequential Decoding with Intervening Miss");

        from_rr_stall = 1'b0;
        pulse_ex_flush(32'h0000000B);

        clear_line(line_a);
        // Bytes 11..15 become the first 5 buffered bytes when offset=0xB.
        set_line_byte(line_a, 11, 8'hB8);
        set_line_byte(line_a, 12, 8'h11);
        set_line_byte(line_a, 13, 8'h22);
        set_line_byte(line_a, 14, 8'h33);
        set_line_byte(line_a, 15, 8'h44);
        send_line_until_accept(line_a, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case1 expected first instruction valid");
        end else if (to_rr_opcode !== 8'hB8) begin
            case_fail("Case1 first opcode should be B8");
        end

        tick(1);
        wait_for_invalid(8, timed_out);
        if (timed_out) begin
            case_fail("Case1 expected to_rr_valid to drop after consuming 5 bytes from partial line");
        end

        clear_line(line_b);
        set_line_byte(line_b, 0, 8'h05);
        set_line_byte(line_b, 1, 8'hAA);
        set_line_byte(line_b, 2, 8'hBB);
        set_line_byte(line_b, 3, 8'hCC);
        set_line_byte(line_b, 4, 8'hDD);
        send_line_until_accept(line_b, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case1 expected valid after second line arrives");
        end else if (to_rr_opcode !== 8'h05) begin
            case_fail("Case1 second opcode should be 05");
        end

        end_case("Case1 Sequential Decoding with Intervening Miss");
    end
endtask

task case2_miss_flush_collision;
    reg [127:0] old_line;
    reg [127:0] new_line;
    reg timed_out;
    begin
        begin_case("Case2 Collision: Miss + Flush same cycle");

        from_rr_stall = 1'b0;
        pulse_ex_flush(32'h00000000);

        clear_line(old_line);
        set_line_byte(old_line, 0, 8'h90);
        set_line_byte(old_line, 1, 8'h90);
        set_line_byte(old_line, 2, 8'h90);
        set_line_byte(old_line, 3, 8'h90);

        clear_line(new_line);
        set_line_byte(new_line, 0, 8'h25);
        set_line_byte(new_line, 1, 8'h0F);
        set_line_byte(new_line, 2, 8'h0F);
        set_line_byte(new_line, 3, 8'h0F);
        set_line_byte(new_line, 4, 8'h0F);

        // Old-path return collides with new flush.
        @(negedge clk);
        from_ex_eip_target_out = 32'h00000040;
        from_ex_flush = 1'b1;
        ICACHE_HIT_DATA = old_line;
        ICACHE_VALID = 1'b1;
        @(posedge clk);
        @(negedge clk);
        from_ex_flush = 1'b0;
        ICACHE_VALID = 1'b0;

        // New-path line.
        send_line_until_accept(new_line, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case2 expected instruction valid on redirected path");
        end else begin
            if (to_rr_opcode === 8'h90)
                case_fail("Case2 stale old-path opcode (90) was consumed");
            if (to_rr_opcode !== 8'h25)
                case_fail("Case2 expected redirected opcode 25");
            if (to_rr_ieip !== 32'h00000040)
                case_fail("Case2 expected IEIP=0x40 for redirected fetch");
        end

        end_case("Case2 Collision: Miss + Flush same cycle");
    end
endtask

task case3_back_to_back_flushes;
    reg [127:0] target_line;
    reg timed_out;
    begin
        begin_case("Case3 Back-to-Back Flushes Redirect-Redirect");

        from_rr_stall = 1'b0;

        @(negedge clk);
        from_ex_eip_target_out = 32'h00000100;
        from_ex_flush = 1'b1;
        @(posedge clk);

        @(negedge clk);
        from_ex_eip_target_out = 32'h00000200;
        from_ex_flush = 1'b1;
        @(posedge clk);

        @(negedge clk);
        from_ex_flush = 1'b0;

        tick(1);
        if ({ITLB_VPN, F_PAGE_OFFSET} !== 32'h00000200)
            case_fail("Case3 expected fetch PC to track newest target 0x200");

        clear_line(target_line);
        set_line_byte(target_line, 0, 8'hB8);
        set_line_byte(target_line, 1, 8'hFE);
        set_line_byte(target_line, 2, 8'hCA);
        set_line_byte(target_line, 3, 8'hAD);
        set_line_byte(target_line, 4, 8'hDE);
        send_line_until_accept(target_line, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case3 expected valid instruction at newest redirect target");
        end else if (to_rr_ieip !== 32'h00000200) begin
            case_fail("Case3 expected IEIP from 0x200 path, not 0x100 path");
        end

        end_case("Case3 Back-to-Back Flushes Redirect-Redirect");
    end
endtask

task case4_stall_plus_line_arrival;
    reg [127:0] line_0;
    reg [127:0] line_1;
    reg timed_out;
    reg [4:0] tail_before;
    reg [4:0] tail_after;
    reg [5:0] expected_tail;
    reg [31:0] ieip_hold;
    begin
        begin_case("Case4 Stall + Cache Line Arrival");

        from_rr_stall = 1'b0;
        pulse_ex_flush(32'h00000000);

        clear_line(line_0);
        set_line_byte(line_0, 0, 8'hB8);
        set_line_byte(line_0, 1, 8'h01);
        set_line_byte(line_0, 2, 8'h00);
        set_line_byte(line_0, 3, 8'h00);
        set_line_byte(line_0, 4, 8'h00);
        set_line_byte(line_0, 5, 8'h05);
        set_line_byte(line_0, 6, 8'h02);
        set_line_byte(line_0, 7, 8'h00);
        set_line_byte(line_0, 8, 8'h00);
        set_line_byte(line_0, 9, 8'h00);
        send_line_until_accept(line_0, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case4 expected initial instruction valid");
        end

        tick(1);
        tail_before = DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr;
        ieip_hold = to_rr_ieip;

        from_rr_stall = 1'b1;

        clear_line(line_1);
        set_line_byte(line_1, 0, 8'h25);
        set_line_byte(line_1, 1, 8'h0F);
        set_line_byte(line_1, 2, 8'h0F);
        set_line_byte(line_1, 3, 8'h0F);
        set_line_byte(line_1, 4, 8'h0F);
        send_line_until_accept(line_1, 40);

        tail_after = DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr;
        expected_tail = tail_before + 6'd16;

        if (tail_after !== expected_tail[4:0])
            case_fail("Case4 expected tail_ptr increment by 16 while stalled");

        if (to_rr_ieip !== ieip_hold)
            case_fail("Case4 expected IEIP hold while stall is asserted");

        from_rr_stall = 1'b0;
        end_case("Case4 Stall + Cache Line Arrival");
    end
endtask

task case5_stall_no_request_freeze;
    reg [4:0] tail_before;
    reg [4:0] tail_after;
    reg [127:0] bytes_before;
    reg [127:0] bytes_after;
    begin
        begin_case("Case5 Stall with no cache request buffer freeze");

        from_rr_stall = 1'b1;
        ICACHE_VALID = 1'b0;

        tail_before = DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr;
        bytes_before = DUT.FETCHBUFF_DECODESTAGE_DEPR.FETCH_BUFF.to_de_outbytes;

        tick(4);

        tail_after = DUT.FETCHBUFF_DECODESTAGE_DEPR.tail_ptr;
        bytes_after = DUT.FETCHBUFF_DECODESTAGE_DEPR.FETCH_BUFF.to_de_outbytes;

        if (tail_after !== tail_before)
            case_fail("Case5 tail_ptr changed during pure stall");
        if (bytes_after !== bytes_before)
            case_fail("Case5 fetch buffer bytes changed during pure stall");

        from_rr_stall = 1'b0;
        end_case("Case5 Stall with no cache request buffer freeze");
    end
endtask

task case6_split_seamless;
    reg [127:0] line_first;
    reg [127:0] line_second;
    reg timed_out;
    integer wait_cycles;
    begin
        begin_case("Case6 Cache line split seamless second line preloaded");

        from_rr_stall = 1'b0;
        pulse_ex_flush(32'h0000000E);

        clear_line(line_first);
        set_line_byte(line_first, 14, 8'h05);
        set_line_byte(line_first, 15, 8'h78);

        clear_line(line_second);
        set_line_byte(line_second, 0, 8'h56);
        set_line_byte(line_second, 1, 8'h34);
        set_line_byte(line_second, 2, 8'h12);

        send_line_until_accept(line_first, 40);
        send_line_until_accept(line_second, 40);

        timed_out = 1'b0;
        wait_cycles = 0;
        while ((to_rr_valid !== 1'b1) && (wait_cycles < 6)) begin
            @(posedge clk);
            wait_cycles = wait_cycles + 1;
        end

        if (to_rr_valid !== 1'b1) begin
            case_fail("Case6 expected immediate validity once second line already buffered");
            timed_out = 1'b1;
        end

        if (!timed_out) begin
            if (wait_cycles > 1)
                case_fail("Case6 expected no long bubble after second line preload");
            if (to_rr_opcode !== 8'h05)
                case_fail("Case6 expected split instruction opcode 05");
        end

        end_case("Case6 Cache line split seamless second line preloaded");
    end
endtask

task case7_split_wait_for_miss;
    reg [127:0] line_first;
    reg [127:0] line_second;
    reg timed_out;
    integer i;
    begin
        begin_case("Case7 Cache line split stalled until second line arrives");

        from_rr_stall = 1'b0;
        pulse_ex_flush(32'h0000000D);

        clear_line(line_first);
        // 7-byte instruction split as 3 bytes + 4 bytes:
        // 0x26 0x81 0xC0 0x78 0x56 0x34 0x12
        // ES override + ADD EAX, imm32
        set_line_byte(line_first, 13, 8'h26);
        set_line_byte(line_first, 14, 8'h81);
        set_line_byte(line_first, 15, 8'hC0);

        clear_line(line_second);
        set_line_byte(line_second, 0, 8'h78);
        set_line_byte(line_second, 1, 8'h56);
        set_line_byte(line_second, 2, 8'h34);
        set_line_byte(line_second, 3, 8'h12);

        send_line_until_accept(line_first, 40);

        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            if (to_rr_valid === 1'b1)
                case_fail("Case7 to_rr_valid asserted before split instruction completed");
        end

        send_line_until_accept(line_second, 40);

        wait_for_valid(30, timed_out);
        if (timed_out) begin
            case_fail("Case7 expected to_rr_valid after second line arrives");
        end else if (to_rr_opcode !== 8'h81) begin
            case_fail("Case7 expected split opcode 81 after completion");
        end

        end_case("Case7 Cache line split stalled until second line arrives");
    end
endtask

task case8_cold_start_flush;
    reg [127:0] target_line;
    reg timed_out;
    begin
        begin_case("Case8 Cold-start flush on reset release");

        rst_n = 1'b0;
        from_ex_flush = 1'b0;
        from_ex_ld_cs = 1'b0;
        ICACHE_VALID = 1'b0;
        tick(2);

        @(negedge clk);
        rst_n = 1'b1;
        from_ex_ld_cs = 1'b1;
        from_ex_eip_target_out = 32'h00000080;
        from_ex_flush = 1'b1;
        @(posedge clk);
        @(negedge clk);
        from_ex_ld_cs = 1'b0;
        from_ex_flush = 1'b0;

        tick(1);
        if ({ITLB_VPN, F_PAGE_OFFSET} !== 32'h00000080)
            case_fail("Case8 expected boot fetch to pivot to cold-start flush target 0x80");

        clear_line(target_line);
        set_line_byte(target_line, 0, 8'h25);
        set_line_byte(target_line, 1, 8'hAA);
        set_line_byte(target_line, 2, 8'h00);
        set_line_byte(target_line, 3, 8'h00);
        set_line_byte(target_line, 4, 8'h00);
        send_line_until_accept(target_line, 40);

        wait_for_valid(40, timed_out);
        if (timed_out) begin
            case_fail("Case8 expected valid instruction at cold-start redirect target");
        end else begin
            if (to_rr_ieip !== 32'h00000080)
                case_fail("Case8 expected IEIP=0x80");
            if (to_rr_opcode !== 8'h25)
                case_fail("Case8 expected opcode 25 at redirected target");
        end

        end_case("Case8 Cold-start flush on reset release");
    end
endtask

initial begin
    FAILURES = 0;
    SUCCESSES = 0;
    CYCLE_COUNT = 0;
    CASE_LOCAL_FAIL = 0;

    log_fd = $fopen("fetch_decode_top_tb3.log", "w");
    if (log_fd == 0) begin
        $display("WARNING: Could not open fetch_decode_top_tb3.log, logging to stdout only.");
        log_fd = 1;
    end

    rst_n = 1'b0;
    ITLB_PFN_OUT = {PFN_BIT_WIDTH{1'b0}};
    ITLB_PAGE_FAULT_OUT = 1'b0;

    ICACHE_VALID = 1'b0;
    ICACHE_HIT_DATA = 128'h0;

    from_rr_cs = 16'h0000;
    from_rr_stall = 1'b0;

    from_ex_ld_cs = 1'b0;
    from_ex_eip_target_out = 32'h00000000;
    from_ex_flush = 1'b0;
    from_ex_br_t_nt = 1'b0;
    from_ex_br_valid = 1'b0;
    from_ex_pht_idx = 4'h0;

    from_wb_flush = 1'b0;

    tick(3);
    rst_n = 1'b1;
    tick(2);

    case1_seq_with_miss();
    case2_miss_flush_collision();
    case3_back_to_back_flushes();
    case4_stall_plus_line_arrival();
    case5_stall_no_request_freeze();
    case6_split_seamless();
    case7_split_wait_for_miss();
    case8_cold_start_flush();

    $display("\n============================================================");
    $display("TB3 SUMMARY: successes=%0d failures=%0d", SUCCESSES, FAILURES);
    $display("============================================================");
    $fdisplay(log_fd, "\n============================================================");
    $fdisplay(log_fd, "TB3 SUMMARY: successes=%0d failures=%0d", SUCCESSES, FAILURES);
    $fdisplay(log_fd, "============================================================");

    $fclose(log_fd);
    $finish;
end

endmodule
