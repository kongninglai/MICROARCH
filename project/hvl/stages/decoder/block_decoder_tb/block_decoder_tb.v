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
    wire [1:0] imm_size_mux;
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
        .imm_size_mux(imm_size_mux),
        .imm(imm),
        .addressing_mode(addressing_mode)
    );

    // 5. Reusable Verification Task
    // This checks every single output of the decoder simultaneously.
    task check_decode;
        input integer test_num;
        input exp_rep;
        input exp_op_size;
        input [2:0] exp_seg_ov_id;
        input exp_ext;
        input [7:0] exp_opcode;
        input [7:0] exp_modrm;
        input [7:0] exp_sib;
        input [1:0] exp_disp_size_mux;
        input [31:0] exp_disp;
        input [1:0] exp_imm_size_mux;
        input [47:0] exp_imm;
        input [1:0] exp_addr_mode;
        begin
            #15; // Wait for the longest critical path (approx 8-10ns max)
            
            if (prefix_rep !== exp_rep || prefix_op_size !== exp_op_size || 
                prefix_seg_ov_id !== exp_seg_ov_id || prefix_ext !== exp_ext ||
                opcode !== exp_opcode || modrm !== exp_modrm || sib !== exp_sib ||
                disp_size_mux !== exp_disp_size_mux || disp !== exp_disp ||
                imm_size_mux !== exp_imm_size_mux || imm !== exp_imm || 
                addressing_mode !== exp_addr_mode) begin
                
                $display("❌ FAIL [Test %0d]: Decoder Mismatch!", test_num);
                $display("  [PREFIXES] Exp: R=%b, OS=%b, Seg=%b, Ext=%b | Got: R=%b, OS=%b, Seg=%b, Ext=%b", 
                         exp_rep, exp_op_size, exp_seg_ov_id, exp_ext, prefix_rep, prefix_op_size, prefix_seg_ov_id, prefix_ext);
                $display("  [BYTES]    Exp: Op=%h, ModRM=%h, SIB=%h | Got: Op=%h, ModRM=%h, SIB=%h", 
                         exp_opcode, exp_modrm, exp_sib, opcode, modrm, sib);
                $display("  [DISP]     Exp: Size=%b, Data=%h | Got: Size=%b, Data=%h", 
                         exp_disp_size_mux, exp_disp, disp_size_mux, disp);
                $display("  [IMM]      Exp: Size=%b, Data=%h | Got: Size=%b, Data=%h", 
                         exp_imm_size_mux, exp_imm, imm_size_mux, imm);
                $display("  [ADDR MODE]Exp: %b | Got: %b", exp_addr_mode, addressing_mode);
                
                error_count = error_count + 1;
            end else begin
                $display("✅ PASS [Test %0d]: Successfully decoded Opcode %h", test_num, opcode);
            end
        end
    endtask

    // Helper task to easily load bytes into the cache_line
    task load_cache_byte;
        input integer byte_idx;
        input [7:0] data;
        begin
            cache_line[(byte_idx*8) + 7 -: 8] = data; 
        end
    endtask

    initial begin
        // Initialize Cache Line to 0
        cache_line = 128'd0;
        
        $display("===============================================================");
        $display("Starting Top-Level TB for block_decoder...");
        $display("===============================================================");
        #20;

        // --------------------------------------------------------------------
        // TEST 1: NOP (0x90)
        // A standard 1-byte instruction with no prefixes, no modrm, no imm.
        // --------------------------------------------------------------------
        cache_line = 128'd0; // Clear cache
        load_cache_byte(0, 8'h90); // Opcode

        // check_decode(Test#, Rep, OpSz, Seg, Ext, Opcode, ModRM, SIB, D_Sz, Disp, I_Sz, Imm, AddrMode)
        check_decode(1, 
            1'b0, 1'b0, 3'b000, 1'b0, // Prefixes
            8'h90,                    // Opcode
            8'h00, 8'h00,             // ModRM, SIB (Ignored/Zero)
            2'b00, 32'h00000000,      // Disp (0 bytes)
            2'b00, 48'h000000000000,  // Imm (0 bytes)
            2'b00                     // Addr Mode (No ModRM, No SIB)
        );

        // --------------------------------------------------------------------
        // TEST 2: Complex Instruction (Prefix + Opcode + ModRM + 4-byte Imm)
        // e.g., ADD EAX, imm32 (Operand Size Override 0x66 + Opcode 0x05)
        // --------------------------------------------------------------------
        cache_line = 128'd0; 
        load_cache_byte(0, 8'h66); // Prefix (Operand Size Override)
        load_cache_byte(1, 8'h05); // Opcode (ADD)
        load_cache_byte(2, 8'h11); // ModRM (Dummy value, assuming your ROM flags it)
        load_cache_byte(3, 8'hAA); // Imm Byte 0
        load_cache_byte(4, 8'hBB); // Imm Byte 1
        load_cache_byte(5, 8'hCC); // Imm Byte 2
        load_cache_byte(6, 8'hDD); // Imm Byte 3

        // UPDATE THESE EXPECTED VALUES based on how your ROM classifies 0x05 with a 0x66 prefix
        check_decode(2, 
            1'b0, 1'b1, 3'b000, 1'b0, // Prefixes (Op_size should be 1)
            8'h05,                    // Opcode
            8'h11, 8'h00,             // ModRM, SIB 
            2'b00, 32'h00000000,      // Disp (0 bytes)
            2'b10, 48'h0000DDCCBBAA,  // Imm (4 bytes, Little Endian)
            2'b01                     // Addr Mode (ModRM=1, SIB=0)
        );

        // --------------------------------------------------------------------
        // TEST 3: The Works (Prefix + Opcode + ModRM + SIB + Disp32 + Imm)
        // Construct a massive cache line to test maximum offset math
        // --------------------------------------------------------------------
        cache_line = 128'd0;
        load_cache_byte(0, 8'hF3); // Prefix
        load_cache_byte(1, 8'h0F); // Prefix (Extended)
        load_cache_byte(2, 8'hFF); // Opcode (Dummy)
        load_cache_byte(3, 8'h84); // ModRM (Mod=10 -> disp32, RM=100 -> SIB)
        load_cache_byte(4, 8'h20); // SIB
        load_cache_byte(5, 8'h10); // Disp0
        load_cache_byte(6, 8'h20); // Disp1
        load_cache_byte(7, 8'h30); // Disp2
        load_cache_byte(8, 8'h40); // Disp3
        load_cache_byte(9, 8'h99); // Imm0
        load_cache_byte(10, 8'h88);// Imm1

        // UPDATE THESE EXPECTED VALUES based on your specific ROM contents
        check_decode(3, 
            1'b1, 1'b0, 3'b000, 1'b1, // Prefixes
            8'hFF,                    // Opcode
            8'h84, 8'h20,             // ModRM, SIB 
            2'b10, 32'h40302010,      // Disp (4 bytes, Little Endian)
            2'b01, 48'h000000008899,  // Imm (2 bytes, Little Endian)
            2'b11                     // Addr Mode (ModRM=1, SIB=1)
        );

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TOP-LEVEL TESTS PASSED! Your decoder is ready for integration.");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");

        $finish;
    end
endmodule