`timescale 1ns / 1ps

module tb_logic_imm();

    // Inputs
    reg [127:8] cache_bits;
    reg [3:0] total_offset;
    reg [1:0] imm_size;

    // Outputs
    wire [47:0] imm_bytes;

    // Test tracking
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // UUT Instantiation
    logic_imm uut (
        .cache_bits(cache_bits),
        .total_offset(total_offset),
        .imm_size(imm_size),
        .imm_bytes(imm_bytes)
    );

    // Helper task to check outputs
    task check_output;
        input integer test_num;
        input [47:0] expected_val;
        begin
            #10; // Wait for worst-case combinational delay
            if (imm_bytes !== expected_val) begin
                $display("❌ FAIL [Test %0d] | Offset: %0d | Size: %b | Expected: %h | Got: %h", 
                         test_num, total_offset, imm_size, expected_val, imm_bytes);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("✅ PASS [Test %0d] | Offset: %0d | Size: %b | Got Expected: %h", 
                         test_num, total_offset, imm_size, imm_bytes);
                SUCCESSES = SUCCESSES + 1;
            end
        end
    endtask

    initial begin
        // Populate cache_bits so that Byte N = N (in hex)
        // cache_bytes[1] = 0x01, cache_bytes[14] = 0x0E
        cache_bits[15:8]   = 8'h01;
        cache_bits[23:16]  = 8'h02;
        cache_bits[31:24]  = 8'h03;
        cache_bits[39:32]  = 8'h04;
        cache_bits[47:40]  = 8'h05;
        cache_bits[55:48]  = 8'h06;
        cache_bits[63:56]  = 8'h07;
        cache_bits[71:64]  = 8'h08;
        cache_bits[79:72]  = 8'h09;
        cache_bits[87:80]  = 8'h0A;
        cache_bits[95:88]  = 8'h0B;
        cache_bits[103:96] = 8'h0C;
        cache_bits[111:104]= 8'h0D;
        cache_bits[119:112]= 8'h0E;
        cache_bits[127:120]= 8'h00; // Unused Byte 15

        $display("===============================================================");
        $display("Starting Self-Checking TB for logic_imm...");
        $display("===============================================================");
        #10;

        // Test 1: 1-byte immediate starting at Byte 1
        // Offset = 0 (Opcode only)
        total_offset = 0;
        imm_size = 2'b00; // Selects 8-bit mux
        check_output(1, 48'h0000_0000_0001);

        // Test 2: 4-byte (32-bit) immediate starting at Byte 2
        // Offset = 1 (e.g., Opcode + 1 Prefix)
        total_offset = 1;
        imm_size = 2'b10; // Selects 32-bit mux
        // x86 is little endian, so bytes {5, 4, 3, 2} -> 0x05040302
        check_output(2, 48'h0000_0504_0302);

        // Test 3: 2-byte (16-bit) immediate starting at Byte 10
        // Offset = 9
        total_offset = 9;
        imm_size = 2'b01; // Selects 16-bit mux
        // bytes {11, 10} -> 0x0B0A
        check_output(3, 48'h0000_0000_0B0A);

        // Test 4: 6-byte (48-bit) immediate starting at Byte 4
        // Offset = 3
        total_offset = 3;
        imm_size = 2'b11; // Selects 48-bit mux
        // bytes {9, 8, 7, 6, 5, 4} -> 0x090807060504
        check_output(4, 48'h0908_0706_0504);

        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! Immediate extraction logic is flawless.");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule