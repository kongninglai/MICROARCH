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
    wire modrm_v;          // <--- ADDED: ModR/M Valid wire
    wire [7:0] modrm;
    wire [7:0] sib; 
    wire [1:0] disp_size_mux;
    wire [31:0] disp; 
    wire [1:0] imm_size;
    wire [47:0] imm;
    wire [1:0] addressing_mode;
    wire [3:0] incr_amt;

    // 3. Test Tracking
    integer error_count = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;

    // 4. Instantiate the Unit Under Test (UUT)
    block_decoder uut (
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm_v(modrm_v), // <--- ADDED: Hooked up to UUT
        .modrm(modrm),
        .sib(sib),
        .disp_size_mux(disp_size_mux),
        .disp(disp),
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .instr_length(incr_amt)
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
        input exp_modrm_v;        // <--- ADDED: Expected ModRM Valid flag
        input [7:0] exp_modrm;
        input [7:0] exp_sib;
        input [1:0] exp_disp_size_mux;
        input [31:0] exp_disp;
        input [1:0] exp_imm_size;
        input [47:0] exp_imm;
        input [1:0] exp_addr_mode;
        input [3:0] exp_incr_amt;
        begin
            #15; // Wait for the longest critical path
            
            $display("---------------------------------------------------------------");
            $display("TEST %0d: %0s", test_num, inst_string);
            $display("BYTES:  %0s", byte_string);
            
            if (prefix_rep !== exp_rep || prefix_op_size !== exp_op_size || 
                prefix_seg_ov_id !== exp_seg_ov_id || prefix_ext !== exp_ext ||
                opcode !== exp_opcode || modrm_v !== exp_modrm_v || 
                (exp_modrm_v === 1'b1 && modrm !== exp_modrm) || 
                (exp_addr_mode[1] === 1'b1 && sib !== exp_sib) ||     
                disp_size_mux !== exp_disp_size_mux || disp !== exp_disp ||
                imm_size !== exp_imm_size || imm !== exp_imm || 
                addressing_mode !== exp_addr_mode || incr_amt !== exp_incr_amt) begin
                
                FAILURES = FAILURES + 1;
                $display("❌ FAIL: Decoder Mismatch!");
                $display("  [PREFIXES] Exp: OS=%b | Got: OS=%b", exp_op_size, prefix_op_size);
                $display("  [BYTES]    Exp: Op=%h, ModRM_V=%b, ModRM=%h | Got: Op=%h, ModRM_V=%b, ModRM=%h", 
                         exp_opcode, exp_modrm_v, exp_modrm, opcode, modrm_v, modrm);
                $display("  [IMM]      Exp: Size=%b, Data=%h | Got: Size=%b, Data=%h (imm_size_inbytes: %0d)", 
                         exp_imm_size, exp_imm, imm_size, imm, 
                         uut.imm_size_inbytes_true);
                $display("  [ADDR MODE]Exp: %b | Got: %b", exp_addr_mode, addressing_mode);
                $display("  [LENGTH]   Exp: %d bytes | Got: %d bytes", exp_incr_amt, incr_amt);
                error_count = error_count + 1;
            end else begin
                SUCCESSES = SUCCESSES + 1;
                $display("✅ PASS: Opcode %h | ModRM_V: %b | ModRM: %h", opcode, modrm_v, modrm);
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

        // 1. ADD AL, imm8 (04 ib)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h04); load_cache_byte(1, 8'h12);
        check_decode(1, "ADD AL, 0x12", "04 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h04, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b00, 4'd2);

        // 2. ADD AX, imm16 (05 iw)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h05); load_cache_byte(2, 8'h34); load_cache_byte(3, 8'h12);
        check_decode(2, "ADD AX, 0x1234", "66 05 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h05, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b00, 4'd4);

        // 3. ADD EAX, imm32 (05 id)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h05); load_cache_byte(1, 8'h78); load_cache_byte(2, 8'h56); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(3, "ADD EAX, 0x12345678", "05 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h05, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b00, 4'd5);

        // 4. ADD r/m8, imm8 (80 /0 ib) -> ModRM: 01
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h80); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(4, "ADD BYTE PTR [ECX], 0x12", "80 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h80, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01, 4'd3);

        // 5. ADD r/m16, imm16 (81 /0 iw) 
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h81); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(5, "ADD WORD PTR [ECX], 0x1234", "66 81 01 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h81, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b01, 4'd5);

        // 6. ADD r/m32, imm32 (81 /0 id)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h81); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h78); load_cache_byte(3, 8'h56); load_cache_byte(4, 8'h34); load_cache_byte(5, 8'h12);
        check_decode(6, "ADD DWORD PTR [ECX], 0x12345678", "81 01 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h81, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b01, 4'd6);

        // 7. ADD r/m16, imm8 (83 /0 ib)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h83); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h12);
        check_decode(7, "ADD WORD PTR [ECX], 0x12 (sign-ext)", "66 83 01 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h83, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01, 4'd4);

        // 8. ADD r/m32, imm8 (83 /0 ib)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h83); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(8, "ADD DWORD PTR [ECX], 0x12 (sign-ext)", "83 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h83, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01, 4'd3);

        // 9. ADD r/m8, r8 (00 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h00); load_cache_byte(1, 8'h11);
        check_decode(9, "ADD BYTE PTR [ECX], DL", "00 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h00, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 10. ADD r/m16, r16 (01 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h11);
        check_decode(10, "ADD WORD PTR [ECX], DX", "66 01 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h01, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd3);

        // 11. ADD r/m32, r32 (01 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h01); load_cache_byte(1, 8'h11);
        check_decode(11, "ADD DWORD PTR [ECX], EDX", "01 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h01, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 12. ADD r8, r/m8 (02 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h02); load_cache_byte(1, 8'h11);
        check_decode(12, "ADD DL, BYTE PTR [ECX]", "02 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h02, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 13. ADD r16, r/m16 (03 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h03); load_cache_byte(2, 8'h11);
        check_decode(13, "ADD DX, WORD PTR [ECX]", "66 03 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h03, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd3);

        // 14. ADD r32, r/m32 (03 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h03); load_cache_byte(1, 8'h11);
        check_decode(14, "ADD EDX, DWORD PTR [ECX]", "03 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h03, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // ====================================================================
        // MOV INSTRUCTION FAMILY (14 Variations)
        // ====================================================================

        // 15. MOV r/m8, r8 (88 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h88); load_cache_byte(1, 8'h11);
        check_decode(15, "MOV BYTE PTR [ECX], DL", "88 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h88, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 16. MOV r/m16, r16 (89 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h89); load_cache_byte(2, 8'h11);
        check_decode(16, "MOV WORD PTR [ECX], DX", "66 89 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h89, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd3);

        // 17. MOV r/m32, r32 (89 /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h89); load_cache_byte(1, 8'h11);
        check_decode(17, "MOV DWORD PTR [ECX], EDX", "89 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h89, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 18. MOV r8, r/m8 (8A /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8A); load_cache_byte(1, 8'h11);
        check_decode(18, "MOV DL, BYTE PTR [ECX]", "8A 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8A, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 19. MOV r16, r/m16 (8B /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h8B); load_cache_byte(2, 8'h11);
        check_decode(19, "MOV DX, WORD PTR [ECX], DX", "66 8B 11",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h8B, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd3);

        // 20. MOV r32, r/m32 (8B /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8B); load_cache_byte(1, 8'h11);
        check_decode(20, "MOV EDX, DWORD PTR [ECX]", "8B 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8B, 1'b1, 8'h11, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 21. MOV r/m16, Sreg (8C /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8C); load_cache_byte(1, 8'h09); 
        check_decode(21, "MOV WORD PTR [ECX], CS", "8C 09",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8C, 1'b1, 8'h09, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 22. MOV Sreg, r/m16 (8E /r)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h8E); load_cache_byte(1, 8'h09); 
        check_decode(22, "MOV CS, WORD PTR [ECX]", "8E 09",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h8E, 1'b1, 8'h09, 8'h00, 2'b00, 32'h0, 2'b00, 48'h0, 2'b01, 4'd2);

        // 23. MOV r8, imm8 (B0+ rb)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hB2); load_cache_byte(1, 8'h12);
        check_decode(23, "MOV DL, 0x12", "B2 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hB2, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b00, 4'd2);

        // 24. MOV r16, imm16 (B8+ rw)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hBA); load_cache_byte(2, 8'h34); load_cache_byte(3, 8'h12);
        check_decode(24, "MOV DX, 0x1234", "66 BA 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hBA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b00, 4'd4);

        // 25. MOV r32, imm32 (B8+ rd)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hBA); load_cache_byte(1, 8'h78); load_cache_byte(2, 8'h56); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(25, "MOV EDX, 0x12345678", "BA 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hBA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b00, 4'd5);

        // 26. MOV r/m8, imm8 (C6 /0)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC6); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h12);
        check_decode(26, "MOV BYTE PTR [ECX], 0x12", "C6 01 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC6, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b00, 48'h12, 2'b01, 4'd3);

        // 27. MOV r/m16, imm16 (C7 /0)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hC7); load_cache_byte(2, 8'h01); load_cache_byte(3, 8'h34); load_cache_byte(4, 8'h12);
        check_decode(27, "MOV WORD PTR [ECX], 0x1234", "66 C7 01 34 12",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hC7, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b01, 48'h1234, 2'b01, 4'd5);

        // 28. MOV r/m32, imm32 (C7 /0)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC7); load_cache_byte(1, 8'h01); load_cache_byte(2, 8'h78); load_cache_byte(3, 8'h56); load_cache_byte(4, 8'h34); load_cache_byte(5, 8'h12);
        check_decode(28, "MOV DWORD PTR [ECX], 0x12345678", "C7 01 78 56 34 12",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC7, 1'b1, 8'h01, 8'h00, 2'b00, 32'h0, 2'b10, 48'h12345678, 2'b01, 4'd6);

        // --------------------------------------------------------------------------------
        // 8-BIT CONDITIONAL RELATIVE BRANCHES (1 byte -> 2'b00)
        // --------------------------------------------------------------------------------
        // 1. JNE rel8 (clr top 16 EIP bits) (66 75 05)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h75); load_cache_byte(2, 8'h05);
        check_decode(1, "o16 jne $+0x07", "66 75 05",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h75, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd3);

        // 2. JNE rel8 (75 05)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h75); load_cache_byte(1, 8'h05);
        check_decode(2, "jne $+0x07", "75 05",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h75, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd2);

        // 3. JNBE rel8 (clr top 16 EIP bits) (66 77 05)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h77); load_cache_byte(2, 8'h05);
        check_decode(3, "o16 ja $+0x07", "66 77 05",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h77, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd3);

        // 4. JNBE rel8 (77 05)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h77); load_cache_byte(1, 8'h05);
        check_decode(4, "ja $+0x07", "77 05",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h77, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd2);

        // --------------------------------------------------------------------------------
        // 16/32-BIT CONDITIONAL RELATIVE BRANCHES
        // --------------------------------------------------------------------------------
        // 5. JNE rel16 (66 0F 85 44 33) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h0F); load_cache_byte(2, 8'h85); load_cache_byte(3, 8'h44); load_cache_byte(4, 8'h33);
        check_decode(5, "o16 jne $+0x3348", "66 0F 85 44 33",
            1'b0, 1'b1, 3'b0, 1'b1, 8'h85, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h3344, 2'b00, 4'd5);

        // 6. JNE rel32 (0F 85 44 33 22 11) (4 bytes -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h0F); load_cache_byte(1, 8'h85); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33); load_cache_byte(4, 8'h22); load_cache_byte(5, 8'h11);
        check_decode(6, "jne $+0x1122334A", "0F 85 44 33 22 11",
            1'b0, 1'b0, 3'b0, 1'b1, 8'h85, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h11223344, 2'b00, 4'd6);

        // 7. JNBE rel16 (66 0F 87 44 33) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h0F); load_cache_byte(2, 8'h87); load_cache_byte(3, 8'h44); load_cache_byte(4, 8'h33);
        check_decode(7, "o16 ja $+0x3348", "66 0F 87 44 33",
            1'b0, 1'b1, 3'b0, 1'b1, 8'h87, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h3344, 2'b00, 4'd5);

        // 8. JNBE rel32 (0F 87 44 33 22 11) (4 bytes -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h0F); load_cache_byte(1, 8'h87); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33); load_cache_byte(4, 8'h22); load_cache_byte(5, 8'h11);
        check_decode(8, "ja $+0x1122334A", "0F 87 44 33 22 11",
            1'b0, 1'b0, 3'b0, 1'b1, 8'h87, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h11223344, 2'b00, 4'd6);

        // --------------------------------------------------------------------------------
        // FAR CALLS (PTR16:16 / PTR16:32)
        // --------------------------------------------------------------------------------
        // 9. CALL ptr16:16 (66 9A 22 11 44 33) (4 bytes total -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'h9A); load_cache_byte(2, 8'h22); load_cache_byte(3, 8'h11); load_cache_byte(4, 8'h44); load_cache_byte(5, 8'h33);
        check_decode(9, "o16 call far 0x3344:0x1122", "66 9A 22 11 44 33",
            1'b0, 1'b1, 3'b0, 1'b0, 8'h9A, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h3344_1122, 2'b00, 4'd6);

        // 10. CALL ptr16:32 (9A 44 33 22 11 66 55) (6 bytes total -> 2'b11)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h9A); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11); load_cache_byte(5, 8'h66); load_cache_byte(6, 8'h55);
        check_decode(10, "call far 0x5566:0x11223344", "9A 44 33 22 11 66 55",
            1'b0, 1'b0, 3'b0, 1'b0, 8'h9A, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b11, 48'h5566_11223344, 2'b00, 4'd7);

        // --------------------------------------------------------------------------------
        // RETURNS AND IRET
        // --------------------------------------------------------------------------------
        // 11. RET imm16 (near, 16-bit pop) (66 C2 08 00) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hC2); load_cache_byte(2, 8'h08); load_cache_byte(3, 8'h00);
        check_decode(11, "o16 ret 0x0008", "66 C2 08 00",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hC2, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h0008, 2'b00, 4'd4);

        // 12. RET imm16 (near) (C2 08 00) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC2); load_cache_byte(1, 8'h08); load_cache_byte(2, 8'h00);
        check_decode(12, "ret 0x0008", "C2 08 00",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC2, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h0008, 2'b00, 4'd3);

        // 13. RET (near, 16-bit pop) (66 C3) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hC3);
        check_decode(13, "o16 ret", "66 C3",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hC3, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b00, 4'd2);

        // 14. RET (near) (C3) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hC3);
        check_decode(14, "ret", "C3",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hC3, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b00, 4'd1);

        // 15. RET imm16 (far, 16-bit pop) (66 CA 08 00) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hCA); load_cache_byte(2, 8'h08); load_cache_byte(3, 8'h00);
        check_decode(15, "o16 retf 0x0008", "66 CA 08 00",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hCA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h0008, 2'b00, 4'd4);

        // 16. RET imm16 (far) (CA 08 00) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hCA); load_cache_byte(1, 8'h08); load_cache_byte(2, 8'h00);
        check_decode(16, "retf 0x0008", "CA 08 00",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hCA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h0008, 2'b00, 4'd3);

        // 17. RET (far, 16-bit pop) (66 CB) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hCB);
        check_decode(17, "o16 retf", "66 CB",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hCB, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b00, 4'd2);

        // 18. RET (far) (CB) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hCB);
        check_decode(18, "retf", "CB",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hCB, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b00, 4'd1);

        // 19. IRETD (CF) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hCF);
        check_decode(19, "iretd", "CF",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hCF, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b00, 4'd1);

        // --------------------------------------------------------------------------------
        // UNCONDITIONAL RELATIVE CALLS & JUMPS
        // --------------------------------------------------------------------------------
        // 20. CALL rel16 (66 E8 44 33) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hE8); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33);
        check_decode(20, "o16 call $+0x3348", "66 E8 44 33",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hE8, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h3344, 2'b00, 4'd4);

        // 21. CALL rel32 (E8 44 33 22 11) (4 bytes -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hE8); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        check_decode(21, "call $+0x11223349", "E8 44 33 22 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hE8, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h11223344, 2'b00, 4'd5);

        // 22. JMP rel16 (66 E9 44 33) (2 bytes -> 2'b01)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hE9); load_cache_byte(2, 8'h44); load_cache_byte(3, 8'h33);
        check_decode(22, "o16 jmp $+0x3348", "66 E9 44 33",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hE9, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b01, 48'h3344, 2'b00, 4'd4);

        // 23. JMP rel32 (E9 44 33 22 11) (4 bytes -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hE9); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11);
        check_decode(23, "jmp $+0x11223349", "E9 44 33 22 11",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hE9, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h11223344, 2'b00, 4'd5);

        // --------------------------------------------------------------------------------
        // FAR JUMPS
        // --------------------------------------------------------------------------------
        // 24. JMP ptr16:16 (66 EA 22 11 44 33) (4 bytes total -> 2'b10)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hEA); load_cache_byte(2, 8'h22); load_cache_byte(3, 8'h11); load_cache_byte(4, 8'h44); load_cache_byte(5, 8'h33);
        check_decode(24, "o16 jmp far 0x3344:0x1122", "66 EA 22 11 44 33",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hEA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b10, 48'h3344_1122, 2'b00, 4'd6);

        // 25. JMP ptr16:32 (EA 44 33 22 11 66 55) (6 bytes total -> 2'b11)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hEA); load_cache_byte(1, 8'h44); load_cache_byte(2, 8'h33); load_cache_byte(3, 8'h22); load_cache_byte(4, 8'h11); load_cache_byte(5, 8'h66); load_cache_byte(6, 8'h55);
        check_decode(25, "jmp far 0x5566:0x11223344", "EA 44 33 22 11 66 55",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hEA, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b11, 48'h5566_11223344, 2'b00, 4'd7);

        // --------------------------------------------------------------------------------
        // SHORT UNCONDITIONAL JUMPS
        // --------------------------------------------------------------------------------
        // 26. JMP rel8 (clr top 16 EIP) (66 EB 05) (1 byte -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hEB); load_cache_byte(2, 8'h05);
        check_decode(26, "o16 jmp short $+0x07", "66 EB 05",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hEB, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd3);

        // 27. JMP rel8 (EB 05) (1 byte -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hEB); load_cache_byte(1, 8'h05);
        check_decode(27, "jmp short $+0x07", "EB 05",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hEB, 1'b0, 8'h00, 8'h00, 2'b00, 32'h0, 2'b00, 48'h05, 2'b00, 4'd2);

        // --------------------------------------------------------------------------------
        // MODR/M BASED CALLS AND JUMPS (Group 5 /2 and /4)
        // --------------------------------------------------------------------------------
        // 28. CALL r/m16 (66 FF 10) Mod=00, Reg=010 (Call), RM=000 [EAX] (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hFF); load_cache_byte(2, 8'h10);
        check_decode(28, "o16 call [eax]", "66 FF 10",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hFF, 1'b1, 8'h10, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b01, 4'd3);

        // 29. CALL r/m32 (FF 10) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hFF); load_cache_byte(1, 8'h10);
        check_decode(29, "call [eax]", "FF 10",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hFF, 1'b1, 8'h10, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b01, 4'd2);

        // 30. JMP r/m16 (66 FF 20) Mod=00, Reg=100 (Jmp), RM=000 [EAX] (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); load_cache_byte(1, 8'hFF); load_cache_byte(2, 8'h20);
        check_decode(30, "o16 jmp [eax]", "66 FF 20",
            1'b0, 1'b1, 3'b0, 1'b0, 8'hFF, 1'b1, 8'h20, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b01, 4'd3);

        // 31. JMP r/m32 (FF 20) (0 bytes immediate -> 2'b00)
        cache_line = 128'd0; 
        load_cache_byte(0, 8'hFF); load_cache_byte(1, 8'h20);
        check_decode(31, "jmp [eax]", "FF 20",
            1'b0, 1'b0, 3'b0, 1'b0, 8'hFF, 1'b1, 8'h20, 8'h00, 2'b00, 32'h0, 2'b00, 48'h00, 2'b01, 4'd2);

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TOP-LEVEL TESTS PASSED!");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule