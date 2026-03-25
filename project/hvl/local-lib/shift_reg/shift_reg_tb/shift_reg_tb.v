module shifter_tb;

initial begin
  $vcdplusfile("shifter_tb.dump.vpd");
  $vcdpluson(0, shifter_tb);
end

reg clk, rst_n;
reg shift;
reg [3:0] instr_len;
reg [30:0] wr_en;
reg [247:0] inbytes;

wire [127:0] outbytes_dut, outbytes_ref;
wire ready_dut, ready_ref;

integer num_tests, num_failures;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// DUT: structural shift_reg
shift_reg dut(
    .clk(clk), .rst_n(rst_n), .shift(shift),
    .instr_len(instr_len), .inbytes(inbytes),
    .wr_en(wr_en), .outbytes(outbytes_dut), .ready(ready_dut)
);

// Reference: behavioral model
shift_reg_behav ref_model(
    .clk(clk), .rst_n(rst_n), .shift(shift),
    .instr_len(instr_len), .inbytes(inbytes),
    .wr_en(wr_en), .outbytes(outbytes_ref), .ready(ready_ref)
);

// ── Tasks ────────────────────────────────────────────────────────────

task apply_reset;
begin
    shift = 1'b0;
    wr_en = 31'b0;
    rst_n = 1'b0;
    instr_len = 4'b0;
    inbytes = 248'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
end
endtask

task verify;
    input [255:0] test_name; // up to 32 chars
begin
    num_tests = num_tests + 1;
    if (outbytes_dut !== outbytes_ref) begin
        num_failures = num_failures + 1;
        $display("FAIL %0s: DUT=%h  REF=%h", test_name, outbytes_dut, outbytes_ref);
    end else begin
        $display("PASS %0s: out=%h", test_name, outbytes_dut);
    end
    if (ready_dut !== ready_ref) begin
        $display("FAIL %0s ready: DUT=%b  REF=%b", test_name, ready_dut, ready_ref);
    end
end
endtask

// Apply one cycle of stimulus then check after posedge + settle
task drive_and_check;
    input [255:0] test_name;
    input         s;
    input [3:0]   ilen;
    input [30:0]  we;
    input [247:0] idata;
begin
    @(posedge clk);
    shift     = s;
    instr_len = ilen;
    wr_en     = we;
    inbytes   = idata;
    @(posedge clk);
    shift = 1'b0;
    wr_en = 31'b0;
    #1;
    verify(test_name);
end
endtask

// ── Random stimulus helpers ──────────────────────────────────────────

// Generate a random 248-bit value
function [247:0] rand248;
    input integer dummy;
begin
    rand248 = {$random, $random, $random, $random, $random, $random, $random, $random};
end
endfunction

// Generate a random 31-bit write-enable mask for a contiguous range
// starting at byte `start` for `count` bytes
function [30:0] wr_en_range;
    input [4:0] start;
    input [4:0] count;
    integer j;
begin
    wr_en_range = 31'b0;
    for (j = 0; j < count; j = j + 1)
        if (start + j < 31)
            wr_en_range[start + j] = 1'b1;
end
endfunction

// ── Test sequence ────────────────────────────────────────────────────

integer i;
reg [3:0] rand_len;
reg [4:0] rand_start, rand_count;

initial begin
    num_tests = 0;
    num_failures = 0;

    // ── Directed tests ───────────────────────────────────────────────

    apply_reset();

    // T1: Write 16 bytes from position 0
    @(posedge clk);
    wr_en = 31'h0000_ffff;
    inbytes = 248'hxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_0011_2233_4455_6677_8899_aabb_ccdd_eeff;
    @(posedge clk);
    #1;
    verify("T1_write16");

    // T2: Consume 13 bytes (shift only, no write)
    drive_and_check("T2_shift13", 1'b1, 4'd13, 31'h0, 248'h0);

    // T3: Consume 1 byte + write 16 bytes at positions [3:18]
    drive_and_check("T3_shf1_wr16",
        1'b1, 4'd1, 31'h0007_fff8,
        248'hxxxx_xxxx_xxxx_xxxx_xx00_1122_3344_5566_7788_99aa_bbcc_ddee_ffxx_xxxx);

    // T4: Consume 15 bytes
    drive_and_check("T4_shift15", 1'b1, 4'd15, 31'h0, 248'h0);

    // T5: Write-only to non-zero start position
    apply_reset();
    drive_and_check("T5_wr_offset",
        1'b0, 4'd0, 31'h0000_1fe0,
        248'h0000_0000_0000_0000_0000_0000_00aa_bbcc_ddee_ff11_2233_0000_0000);

    // T6: Shift by 0 (should be a no-op on data)
    drive_and_check("T6_shift0", 1'b1, 4'd0, 31'h0, 248'h0);

    // T7: Reset clears everything
    apply_reset();
    #1;
    verify("T7_reset");

    // T8: Write all 31 bytes
    drive_and_check("T8_wr_all31",
        1'b0, 4'd0, 31'h7fff_ffff,
        248'h0102_0304_0506_0708_090a_0b0c_0d0e_0f10_1112_1314_1516_1718_191a_1b1c_1d1e_1f);

    // T9: Shift all 15, then shift again (buffer should be partially from upper bytes)
    drive_and_check("T9_shift15", 1'b1, 4'd15, 31'h0, 248'h0);

    // ── Randomized tests ─────────────────────────────────────────────

    $display("\n--- Random tests ---");

    for (i = 0; i < 200; i = i + 1) begin
        // Re-seed the buffer every 20 iterations
        if (i % 20 == 0) begin
            apply_reset();
            drive_and_check("RAND_FILL",
                1'b0, 4'd0, 31'h7fff_ffff, rand248(i));
        end

        // Randomly choose: write-only, shift-only, or shift+write
        case ($random % 3)
            0: begin // write-only
                rand_start = $random % 31;
                rand_count = $random % (31 - rand_start + 1);
                drive_and_check("RAND_WR",
                    1'b0, 4'd0,
                    wr_en_range(rand_start, rand_count),
                    rand248(i));
            end
            1: begin // shift-only
                rand_len = ($random % 15) + 1; // 1-15
                drive_and_check("RAND_SHF",
                    1'b1, rand_len, 31'h0, 248'h0);
            end
            2: begin // shift + write
                rand_len = ($random % 15) + 1;
                rand_start = $random % 31;
                rand_count = $random % (31 - rand_start + 1);
                drive_and_check("RAND_S+W",
                    1'b1, rand_len,
                    wr_en_range(rand_start, rand_count),
                    rand248(i));
            end
        endcase
    end

    // ── Summary ──────────────────────────────────────────────────────

    $display("\n========================================");
    if (num_failures == 0)
        $display("ALL %0d TESTS PASSED", num_tests);
    else
        $display("FAILED: %0d / %0d tests", num_failures, num_tests);
    $display("========================================\n");

    $finish;
end

endmodule
