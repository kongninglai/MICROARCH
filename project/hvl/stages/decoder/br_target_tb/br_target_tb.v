`timescale 1ns / 1ps

module tb_br_target();

    // 1. Inputs
    reg [31:0] i_eip;
    reg [127:0] cache_line;

    // 2. Wires between Decoder and Br_Target
    wire prefix_rep, prefix_op_size, prefix_seg, prefix_ext, modrm_v;
    wire [2:0] prefix_seg_ov_id, imm_size;
    wire [7:0] opcode, modrm, sib;
    wire [1:0] disp_size_mux, addressing_mode;
    wire [31:0] disp;
    wire [47:0] imm;
    wire [3:0] instr_length;

    // 3. Final Outputs
    wire hit;
    wire [31:0] bp_eip_target;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 4. Instantiate Decoder
    block_decoder decoder_uut (
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size), 
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_seg(prefix_seg),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm(modrm),
        .modrm_v(modrm_v),
        .sib(sib), 
        .disp_size_mux(disp_size_mux),
        .disp(disp), 
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .instr_length(instr_length)
    );    

    // 5. Instantiate Branch Target Calculator
    br_target target_uut (
        .i_eip(i_eip),
        .prefix_ext(prefix_ext), // Hooked up!
        .opcode(opcode),
        .imm(imm),
        .op_size_overload(prefix_op_size), // Hooked up!
        .hit(hit),
        .bp_eip_target(bp_eip_target)
    );

    // 6. Checking Task
    task check_result;
        input [8*35:1] test_name; 
        input exp_hit;
        input [31:0] exp_target;
        begin
            #100; // Wait 10ns for Decoder + Target logic to settle
            if (hit === exp_hit && (!exp_hit || bp_eip_target === exp_target)) begin
                $display("  ✅ PASS | %0s | Hit: %b | Target: %h", test_name, hit, bp_eip_target);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: Hit=%b | Target=%h", exp_hit, exp_target);
                $display("     ACTUAL  : Hit=%b | Target=%h", hit, bp_eip_target);
                FAILURES = FAILURES + 1;
                $display("     ACTUAL  : ieip=%b | Target32=%h, | Target16=%h, | Target8=%h", i_eip, target_uut.target_rel32, target_uut.target_rel16, target_uut.target_rel8);
            end
            #5; // Padding before next test
        end
    endtask

    // 7. Stimulus
    initial begin
        $dumpfile("br_target_tb.vpd");
        $dumpvars(0, tb_br_target);

        $display("=======================================");
        $display("    DECODER -> BRANCH TARGET TEST      ");
        $display("=======================================");

        // Set Base EIP for all tests
        i_eip = 32'h01_00_00_00;

        // Note: cache_line[7:0] is the first byte (lowest address).

        // --- 0x85 / 0x87 EXTENDED PREFIX TESTS ---
        
        // 0F 85 00 00 10 24 -> JNE rel32 (+0x10240000 -> Note: little endian offset is 0x24100000)
        // Let's use offset 0x00001024 -> bytes: 24 10 00 00
        cache_line = 128'h0;
        cache_line[47:0] = 48'h00_00_10_24_85_0F; 
        check_result("0F 85 (JNE rel32) w/ prefix      ", 1'b1, 32'h01_00_10_24);

        // 85 24 10 00 00 -> NO prefix (TEST instruction)
        cache_line = 128'h0;
        cache_line[39:0] = 40'h00_00_10_24_85; 
        check_result("85 (TEST) NO prefix              ", 1'b0, 32'hxxxx_xxxx); // Should not hit

        // 0F 87 F0 FF FF FF -> JNBE rel32 (-16 bytes)
        cache_line = 128'h0;
        cache_line[47:0] = 48'hFF_FF_FF_F0_87_0F; 
        check_result("0F 87 (JNBE rel32) w/ prefix     ", 1'b1, 32'h00_FF_FF_F0);

        // 87 F0 FF FF FF -> NO prefix (XCHG instruction)
        cache_line = 128'h0;
        cache_line[39:0] = 40'hFF_FF_FF_F0_87; 
        check_result("87 (XCHG) NO prefix              ", 1'b0, 32'hxxxx_xxxx); // Should not hit


        // --- OP SIZE OVERRIDE TESTS (0x66) ---
        
        // 66 0F 85 10 24 -> JNE rel16 (+0x1024 -> actually +0x2410 if little endian bytes are 10 24)
        // Let's use offset 0x2410 -> bytes: 10 24
        cache_line = 128'h0;
        cache_line[39:0] = 40'h24_10_85_0F_66; 
        check_result("66 0F 85 (JNE rel16) Op Override ", 1'b1, 32'h01_00_24_10);

        // 66 0F 87 F0 FF -> JNBE rel16 (-16 bytes -> 0xFFF0)
        cache_line = 128'h0;
        cache_line[39:0] = 40'hFF_F0_87_0F_66; 
        check_result("66 0F 87 (JNBE rel16) Op Override", 1'b1, 32'h00_FF_FF_F0);

        // E8 34 12 00 00 -> CALL rel32 (+0x00001234)
        cache_line = 128'h0;
        cache_line[39:0] = 40'h00_00_12_34_E8; 
        check_result("E8 (CALL rel32) NO Override      ", 1'b1, 32'h01_00_12_34);

        // 66 E8 34 12 -> CALL rel16 (+0x1234)
        cache_line = 128'h0;
        cache_line[31:0] = 32'h12_34_E8_66; 
        check_result("66 E8 (CALL rel16) Op Override   ", 1'b1, 32'h01_00_12_34);

        // E9 55 00 00 00 -> JMP rel32 (+0x55)
        cache_line = 128'h0;
        cache_line[39:0] = 40'h00_00_00_55_E9; 
        check_result("E9 (JMP rel32) NO Override       ", 1'b1, 32'h01_00_00_55);

        // 66 E9 55 00 -> JMP rel16 (+0x55)
        cache_line = 128'h0;
        cache_line[31:0] = 32'h00_55_E9_66; 
        check_result("66 E9 (JMP rel16) Op Override    ", 1'b1, 32'h01_00_00_55);


        // --- REMAINING REL8 COVERAGE ---
        
        // 75 08 -> JNE rel8 (+8 bytes)
        cache_line = 128'h0;
        cache_line[15:0] = 16'h08_75; 
        check_result("75 (JNE rel8)                    ", 1'b1, 32'h01_00_00_08);

        // 77 F0 -> JNBE rel8 (-16 bytes)
        cache_line = 128'h0;
        cache_line[15:0] = 16'hF0_77; 
        check_result("77 (JNBE rel8)                   ", 1'b1, 32'h00_FF_FF_F0);

        // EB 1A -> JMP rel8 (+26 bytes)
        cache_line = 128'h0;
        cache_line[15:0] = 16'h1A_EB; 
        check_result("EB (JMP rel8)                    ", 1'b1, 32'h01_00_00_1A);

        $display("=======================================");
        $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule