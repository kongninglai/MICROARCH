module shifter_tb;

    initial begin
      // $vcdplusfile("shifter_tb.dump.vpd");
      // $vcdpluson(0, shifter_tb);
    end

    reg clk, rst_n;
    reg shift;
    reg [3:0] instr_len;
    reg [30:0] wr_en;
    reg [247:0] inbytes;

    wire [127:0] outbytes_dut, outbytes_ref;
    wire ready_dut, ready_ref;

    // --- Shadow Tracking Variables ---
    integer num_tests, FAILURES, SUCCESSES;
    reg [30:0] valid_occupancy; // TB's internal record of which bytes are valid
    reg [127:0] dynamic_mask;   // Calculated mask for the 128-bit outbytes

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    shift_reg dut(
        .clk(clk), .rst_n(rst_n), .shift(shift),
        .instr_len(instr_len), .gate(1'b1), .inbytes(inbytes),
        .wr_en(wr_en), .outbytes(outbytes_dut), .ready(ready_dut)
    );

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
        valid_occupancy = 31'b0; // Reset TB tracking
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
    end
    endtask

    task verify;
        input [255:0] test_name;
        integer b;
    begin
        num_tests = num_tests + 1;
        
        // Generate Dynamic Mask based on occupancy
        // outbytes is Bytes 0 to 15.
        dynamic_mask = 0;
        for (b = 0; b < 16; b = b + 1) begin
            if (valid_occupancy[b]) begin
                dynamic_mask[b*8 +: 8] = 8'hFF;
            end
        end

        // Check if the "Valid" window matches
        if ((outbytes_dut & dynamic_mask) !== (outbytes_ref & dynamic_mask)) begin
            FAILURES = FAILURES + 1;
            $display("[%t] ❌ FAIL: %0s", $time, test_name);
            $display("    Mask: %h", dynamic_mask);
            $display("    DUT (Masked): %h", outbytes_dut & dynamic_mask);
            $display("    REF (Masked): %h", outbytes_ref & dynamic_mask);
        end else begin
            $display("[%t] ✅ PASS: %0s", $time, test_name);
            SUCCESSES = SUCCESSES + 1;
        end
    end
    endtask

    task drive_and_check;
        input [255:0] test_name;
        input         s;
        input [3:0]   ilen;
        input [30:0]  we;
        input [247:0] idata;
        reg [30:0]    temp_occ;
    begin
        @(negedge clk);
        shift     = s;
        instr_len = ilen;
        wr_en     = we;
        inbytes   = idata;

        // --- Shadow Update Logic ---
        // 1. Mark bytes being written as valid
        temp_occ = valid_occupancy | we;
        // 2. If shifting, move the validity mask down
        if (s) begin
            valid_occupancy = temp_occ >> ilen;
        end else begin
            valid_occupancy = temp_occ;
        end

        @(posedge clk);
        #2; // Propagate structural gates
        verify(test_name);
        
        // Clear control signals for next cycle
        shift = 1'b0;
        wr_en = 31'b0;
    end
    endtask

    // ── Random stimulus helpers ──────────────────────────────────────────

    function [247:0] rand248;
        input integer dummy;
    begin
        rand248 = {$random, $random, $random, $random, $random, $random, $random, $random};
    end
    endfunction

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
    reg [4:0] rand_start, rand_count;

    initial begin
        num_tests = 0;
        FAILURES = 0;
        SUCCESSES = 0;
        apply_reset();

        // T1: Write 16 bytes. Shadow: Occupancy becomes hFFFF
        drive_and_check("T1_write16", 1'b0, 4'd0, 31'h0000_ffff, 
            248'h0011_2233_4455_6677_8899_aabb_ccdd_eeff);

        // T2: Shift 13. Shadow: hFFFF >> 13 = h0007 (3 bytes left)
        drive_and_check("T2_shift13", 1'b1, 4'd13, 31'h0, 248'h0);

        // T3: Shift 1, Write 16 at [3:18]. 
        drive_and_check("T3_shf1_wr16", 1'b1, 4'd1, 31'h0007_fff8, 
            248'h00112233445566778899aabbccddeeff00);

        $display("\n--- Starting 200 Random Tests ---");
        for (i = 0; i < 200; i = i + 1) begin
            if (i % 20 == 0) apply_reset();

            case ($random % 3)
                0: drive_and_check("RAND_WR", 1'b0, 4'd0, wr_en_range($random%31, $random%16), rand248(i));
                1: drive_and_check("RAND_SHF", 1'b1, ($random%15)+1, 31'h0, 248'h0);
                2: drive_and_check("RAND_S+W", 1'b1, ($random%15)+1, wr_en_range($random%31, $random%16), rand248(i));
            endcase
        end

        $display("\n========================================");
        if (FAILURES == 0)
            $display("  ✅ ALL %0d TESTS PASSED (Dynamic Masking Active)", num_tests);
        else
            $display("  ❌ FAILED: %0d / %0d tests", FAILURES, num_tests);
        $display("========================================\n");
        
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule