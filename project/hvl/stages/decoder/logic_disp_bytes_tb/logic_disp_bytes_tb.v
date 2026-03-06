`timescale 1ns / 1ps

module tb_logic_disp_bytes();

    // Inputs (CHANGED to match the flat 88-bit bus)
    reg [87:0] cache_bits;
    reg [7:0] modrm_byte;
    reg is_modrm_true;
    reg has_sib;
    reg [2:0] prefix_num;

    // Outputs
    wire [2:0] disp_size_inbytes;
    wire [1:0] disp_size;
    wire [31:0] disp_bytes;

    // Error tracking
    integer error_count = 0;

    // Instantiate the Unit Under Test (UUT)
    logic_disp_bytes uut (
        .cache_bits(cache_bits),      // CHANGED: Port name updated
        .modrm_byte(modrm_byte),
        .is_modrm_true(is_modrm_true),
        .has_sib(has_sib),
        .prefix_num(prefix_num),
        .disp_size_inbytes(disp_size_inbytes),
        .disp_size(disp_size),
        .disp_bytes(disp_bytes)
    );

    // Reusable validation task
    task check_result;
        input integer test_num;
        input [1:0] exp_size_bits;
        input [2:0] exp_size_bytes;
        input [31:0] exp_disp_bytes;
        begin
            if (disp_size !== exp_size_bits || disp_size_inbytes !== exp_size_bytes || disp_bytes !== exp_disp_bytes) begin
                $display("❌ FAIL [Test %0d]:", test_num);
                $display("    Expected: SizeBits=%b, Bytes=%0d, Data=0x%h", exp_size_bits, exp_size_bytes, exp_disp_bytes);
                $display("    Actual:   SizeBits=%b, Bytes=%0d, Data=0x%h", disp_size, disp_size_inbytes, disp_bytes);
                error_count = error_count + 1;
            end else begin
                $display("✅ PASS [Test %0d]: Correctly extracted 0x%h (%0d bytes)", test_num, disp_bytes, disp_size_inbytes);
            end
        end
    endtask

    initial begin
        // 1. Initialize our instruction cache flat bus
        // CHANGED: Assigning directly to the bit slices of the flat bus
        cache_bits[7:0]   = 8'hA2; // Byte 2
        cache_bits[15:8]  = 8'hB3; // Byte 3
        cache_bits[23:16] = 8'hC4; // Byte 4
        cache_bits[31:24] = 8'hD5; // Byte 5
        cache_bits[39:32] = 8'hE6; // Byte 6
        cache_bits[47:40] = 8'hF7; // Byte 7
        cache_bits[55:48] = 8'h08; // Byte 8
        cache_bits[63:56] = 8'h19; // Byte 9
        cache_bits[71:64] = 8'h2A; // Byte 10
        cache_bits[79:72] = 8'h3B; // Byte 11
        cache_bits[87:80] = 8'h4C; // Byte 12

        is_modrm_true = 0;
        modrm_byte = 0;
        has_sib = 0;
        prefix_num = 0;

        $display("===============================================================");
        $display("Starting Self-Checking TB for logic_disp_bytes...");
        $display("===============================================================");
        
        // Wait for global reset
        #15;

        // --------------------------------------------------------------------
        // TEST 1: 1-byte displacement, Offset = 0 (No prefixes, no SIB)
        // --------------------------------------------------------------------
        is_modrm_true = 1;
        modrm_byte = 8'b01_000_000; // Mod = 01 (1-byte disp)
        prefix_num = 0;
        has_sib = 0;
        #10; 
        // Expected Data: Byte 2 (A2) zero-extended
        check_result(1, 2'b01, 3'd1, 32'h000000A2);

        // --------------------------------------------------------------------
        // TEST 2: 4-byte displacement, Offset = 1 (1 prefix, no SIB)
        // --------------------------------------------------------------------
        is_modrm_true = 1;
        modrm_byte = 8'b10_000_000; // Mod = 10 (4-byte disp)
        prefix_num = 1;
        has_sib = 0;
        #10;
        // Expected Data: Little Endian combination of Bytes 6, 5, 4, 3
        check_result(2, 2'b10, 3'd4, 32'hE6D5C4B3);

        // --------------------------------------------------------------------
        // TEST 3: 4-byte displacement, Offset = 3 (2 prefixes, 1 SIB)
        // --------------------------------------------------------------------
        is_modrm_true = 1;
        modrm_byte = 8'b00_000_101; // Mod = 00, RM = 101 (Special disp32 case)
        prefix_num = 2;
        has_sib = 1;
        #10;
        // Expected Data: Little Endian combination of Bytes 8, 7, 6, 5
        check_result(3, 2'b10, 3'd4, 32'h08F7E6D5);

        // --------------------------------------------------------------------
        // TEST 4: 0-byte displacement
        // --------------------------------------------------------------------
        is_modrm_true = 1;
        modrm_byte = 8'b00_000_000; // Mod = 00, RM = 000 (0-byte disp)
        prefix_num = 2;
        has_sib = 0;
        #10;
        // Expected Data: Masked to 0
        check_result(4, 2'b00, 3'd0, 32'h00000000);

        // --------------------------------------------------------------------
        // TEST 5: 1-byte displacement, Max Offset = 5 (4 prefixes, 1 SIB)
        // --------------------------------------------------------------------
        is_modrm_true = 1;
        modrm_byte = 8'b01_000_000; // Mod = 01 (1-byte disp)
        prefix_num = 4;
        has_sib = 1;
        #10;
        // Expected Data: Byte 7 (F7) zero-extended
        check_result(5, 2'b01, 3'd1, 32'h000000F7);

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $finish;
    end
endmodule