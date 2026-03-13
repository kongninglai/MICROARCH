`timescale 1ns / 1ps

module tb_block_decoder();

    // 1. Inputs
    reg [127:0] cache_line;

    // 2. Outputs
    wire prefix_rep;
    wire prefix_op_size; 
    wire [2:0] prefix_seg_ov_id;
    wire prefix_ext;
    wire [7:0] opcode;
    wire [7:0] modrm;
    wire [7:0] sib; 
    wire [1:0] disp_size_mux;
    wire [31:0] disp; 
    wire [1:0] imm_size;
    wire [47:0] imm;
    wire [1:0] addressing_mode;

    // 3. Test Tracking
    integer error_count = 0;
    integer i;

    // 4. Instantiate the Unit Under Test (UUT)
    block_decoder uut (
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm(modrm),
        .sib(sib),
        .disp_size_mux(disp_size_mux),
        .disp(disp),
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode)
    );

    // 5. Reusable Verification Task
    task check_decode;
        input integer test_num;
        input [8*80:1] inst_string;
        input [8*80:1] byte_string;
        input exp_rep;
        input exp_op_size;
        input [2:0] exp_seg_ov_id;
        input exp_ext;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        input [7:0] exp_sib;
        input [1:0] exp_disp_size_mux;
        input [31:0] exp_disp;
        input [1:0] exp_imm_size;
        input [47:0] exp_imm;
        input [1:0] exp_addr_mode;
        begin
            #15; // Wait for the longest critical path
            
            $display("---------------------------------------------------------------");
            $display("TEST %0d: %0s", test_num, inst_string);
            $display("BYTES:  %0s", byte_string);
            
            if (prefix_rep !== exp_rep || prefix_op_size !== exp_op_size || 
                prefix_seg_ov_id !== exp_seg_ov_id || prefix_ext !== exp_ext ||
                opcode !== exp_opcode || 
                (exp_addr_mode[0] === 1'b1 && modrm !== exp_modrm) || 
                (exp_addr_mode[1] === 1'b1 && sib !== exp_sib) ||     
                disp_size_mux !== exp_disp_size_mux || disp !== exp_disp ||
                imm_size !== exp_imm_size || imm !== exp_imm || 
                addressing_mode !== exp_addr_mode) begin
                
                $display("❌ FAIL: Decoder Mismatch!");
                $display("  [PREFIXES] Exp: OS=%b | Got: OS=%b", exp_op_size, prefix_op_size);
                $display("  [BYTES]    Exp: Op=%h, ModRM_Sig=%b, ModRM=%h | Got: Op=%h, ModRM_Sig=%b, ModRM=%h", 
                         exp_opcode, exp_addr_mode[0], exp_modrm, opcode, addressing_mode[0], modrm);
                $display("  [IMM]      Exp: Size=%b, Data=%h | Got: Size=%b, Data=%h (imm_size_inbytes: %0d)", 
                         exp_imm_size, exp_imm, imm_size, imm, 
                         uut.imm_size_inbytes_true);
                $display("  [ADDR MODE]Exp: %b | Got: %b", exp_addr_mode, addressing_mode);
                error_count = error_count + 1;
            end else begin
                $display("✅ PASS: Opcode %h | ModRM Sig: %b | ModRM: %h", opcode, addressing_mode[0], modrm);
            end
        end
    endtask

    task load_cache_byte;
        input integer byte_idx;
        input [7:0] data;
        begin cache_line[(byte_idx*8) + 7 -: 8] = data; end
    endtask

    initial begin
        $dumpfile("block_decoder_tb.vpd");
        $dumpvars(0, tb_block_decoder);
        #20;

        // ====================================================================
        // ADD INSTRUCTION FAMILY (14 Variations)
        // ====================================================================

        // 1. ADD AL, imm8 (04 ib) - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h04); load_cache_byte(1, 8'h12);
        check_decode(1, "ADD AL, 0x12", "04 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h04, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b00);

        // 2. ADD AX, imm16 (05 iw) -> Requires 66h prefix in 32-bit mode - Changed exp_imm_size_mux to 2'b01
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h05); load_cache_byte(2, 8'h34); load_cache_byte(3, 8'h12);
        check_decode(2, "ADD AX, 0x1234", "66 05 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h05, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b00);

        // 3. ADD EAX, imm32 (05 id) - Changed exp_imm_size_mux to 2'b10
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h05); load_cache_byte(1, 8'h78); load_cache_byte(2, 8'h56); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(3, "ADD EAX, 0x12345678", "05 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h05, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b00);

        // 4. ADD r/m8, imm8 (80 /0 ib) -> ModRM: [ECX] = 00_000_001 = 01 - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h80); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(4, "ADD BYTE PTR [ECX], 0x12", "80 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h80, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01);

        // 5. ADD r/m16, imm16 (81 /0 iw) -> Requires 66h prefix - Changed exp_imm_size_mux to 2'b01
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h81); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(5, "ADD WORD PTR [ECX], 0x1234", "66 81 01 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h81, 8'h01, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b01);

        // 6. ADD r/m32, imm32 (81 /0 id) - Changed exp_imm_size_mux to 2'b10
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h81); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h78); load_cache_byte(3, 8'h56); load_cache_byte(4, 8'h34); load_cache_byte(5, 8'h12);
        check_decode(6, "ADD DWORD PTR [ECX], 0x12345678", "81 01 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h81, 8'h01, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b01);

        // 7. ADD r/m16, imm8 (83 /0 ib) -> Requires 66h prefix - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h83); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h12);
        check_decode(7, "ADD WORD PTR [ECX], 0x12 (sign-ext)", "66 83 01 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h83, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01);

        // 8. ADD r/m32, imm8 (83 /0 ib) - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h83); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(8, "ADD DWORD PTR [ECX], 0x12 (sign-ext)", "83 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h83, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01);

        // 9. ADD r/m8, r8 (00 /r) -> ModRM: [ECX], DL = 00_010_001 = 11
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h00); load_cache_byte(1, 8'h11);
        check_decode(9, "ADD BYTE PTR [ECX], DL", "00 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h00, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 10. ADD r/m16, r16 (01 /r) -> Requires 66h prefix
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h11);
        check_decode(10, "ADD WORD PTR [ECX], DX", "66 01 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h01, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 11. ADD r/m32, r32 (01 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h01); load_cache_byte(1, 8'h11);
        check_decode(11, "ADD DWORD PTR [ECX], EDX", "01 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h01, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 12. ADD r8, r/m8 (02 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h02); load_cache_byte(1, 8'h11);
        check_decode(12, "ADD DL, BYTE PTR [ECX]", "02 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h02, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 13. ADD r16, r/m16 (03 /r) -> Requires 66h prefix
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h03); load_cache_byte(2, 8'h11);
        check_decode(13, "ADD DX, WORD PTR [ECX]", "66 03 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h03, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 14. ADD r32, r/m32 (03 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h03); load_cache_byte(1, 8'h11);
        check_decode(14, "ADD EDX, DWORD PTR [ECX]", "03 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h03, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // ====================================================================
        // MOV INSTRUCTION FAMILY (14 Variations)
        // ====================================================================

        // 15. MOV r/m8, r8 (88 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h88); load_cache_byte(1, 8'h11);
        check_decode(15, "MOV BYTE PTR [ECX], DL", "88 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h88, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 16. MOV r/m16, r16 (89 /r) -> 66h prefix
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h89); load_cache_byte(2, 8'h11);
        check_decode(16, "MOV WORD PTR [ECX], DX", "66 89 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h89, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 17. MOV r/m32, r32 (89 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h89); load_cache_byte(1, 8'h11);
        check_decode(17, "MOV DWORD PTR [ECX], EDX", "89 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h89, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 18. MOV r8, r/m8 (8A /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8A); load_cache_byte(1, 8'h11);
        check_decode(18, "MOV DL, BYTE PTR [ECX]", "8A 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8A, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 19. MOV r16, r/m16 (8B /r) -> 66h prefix
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h8B); load_cache_byte(2, 8'h11);
        check_decode(19, "MOV DX, WORD PTR [ECX], DX", "66 8B 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h8B, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 20. MOV r32, r/m32 (8B /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8B); load_cache_byte(1, 8'h11);
        check_decode(20, "MOV EDX, DWORD PTR [ECX]", "8B 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8B, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 21. MOV r/m16, Sreg (8C /r) -> e.g., CS=001
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8C); load_cache_byte(1, 8'h09); // [ECX], CS
        check_decode(21, "MOV WORD PTR [ECX], CS", "8C 09",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8C, 8'h09, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 22. MOV Sreg, r/m16 (8E /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8E); load_cache_byte(1, 8'h09); // CS, [ECX]
        check_decode(22, "MOV CS, WORD PTR [ECX]", "8E 09",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8E, 8'h09, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01);

        // 23. MOV r8, imm8 (B0+ rb) -> B0 + DL(010) = B2 - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hB2); load_cache_byte(1, 8'h12);
        check_decode(23, "MOV DL, 0x12", "B2 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hB2, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b00);

        // 24. MOV r16, imm16 (B8+ rw) -> 66h + B8 + DX(010) = 66 BA - Changed exp_imm_size_mux to 2'b01
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hBA); load_cache_byte(2, 8'h34); load_cache_byte(3, 8'h12);
        check_decode(24, "MOV DX, 0x1234", "66 BA 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hBA, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b00);

        // 25. MOV r32, imm32 (B8+ rd) -> B8 + EDX(010) = BA - Changed exp_imm_size_mux to 2'b10
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hBA); load_cache_byte(1, 8'h78); load_cache_byte(2, 8'h56); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(25, "MOV EDX, 0x12345678", "BA 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hBA, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b00);

        // 26. MOV r/m8, imm8 (C6 /0) -> ModRM: 00_000_001 = 01 - Changed exp_imm_size_mux to 2'b00
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC6); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(26, "MOV BYTE PTR [ECX], 0x12", "C6 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC6, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01);

        // 27. MOV r/m16, imm16 (C7 /0) -> 66h prefix - Changed exp_imm_size_mux to 2'b01
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hC7); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(27, "MOV WORD PTR [ECX], 0x1234", "66 C7 01 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hC7, 8'h01, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b01);

        // 28. MOV r/m32, imm32 (C7 /0) - Changed exp_imm_size_mux to 2'b10
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC7); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h78); load_cache_byte(3, 8'h56); load_cache_byte(4, 8'h34); load_cache_byte(5, 8'h12);
        check_decode(28, "MOV DWORD PTR [ECX], 0x12345678", "C7 01 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC7, 8'h01, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b01);


        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TOP-LEVEL TESTS PASSED!");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $finish;
    end
endmodule